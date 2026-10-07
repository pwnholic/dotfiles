--- Persistent floating terminals.
---
--- Design:
---   * a terminal lives in a hidden buffer; a floating window only *shows* it,
---   * the process is reused while it is alive (no shell per open),
---   * visibility and cwd are derived from Neovim/the kernel, never guessed,
---   * slots ("1", "2", ...) and named terminals ("lazygit") share one code path.
---
--- Context synchronization (`defaults.terminal.sync_cwd`):
---   * a *hidden* terminal may follow the project context (`cd <root>`),
---   * a *visible* terminal is user-controlled and is never forced to change,
---   * injection only happens when the shell is at its prompt -- checked through
---     `/proc/<pid>/stat` (`tpgid == pgrp`) so that a running program in the
---     shell is never corrupted with stray input. When that cannot be
---     determined (non-Linux), synchronization is skipped instead of guessed.
---
--- @class core.terminal
local M = {}

local defaults = require("core.defaults")
local fs = require("lib.fs")
local lifecycle = require("lib.lifecycle")
local notify = require("core.notify")
local process = require("lib.process")
local report = require("lib.report")

--- @type lib.Lifecycle
--- @type lib.Lifecycle?
local lc
--- @type table<string, table> id -> slot
local slots = {}
--- @type fun(root: string|nil, previous: string|nil)|nil
local unsubscribe_context
--- @type table
local opts = {}
--- @type boolean
local warned_no_proc = false
--- @type number
local last_used_slot = 0

--- ---------------------------------------------------------------------------
--- Slot bookkeeping
--- ---------------------------------------------------------------------------

--- @param id string|integer
--- @return string
local function slot_id(id)
    return tostring(id)
end

--- Last explicit command slot (used by `:Terminal info` and tests).
local last_command = nil

--- @param id string|integer
--- @return table slot
local function ensure_slot(id)
    local key = slot_id(id)
    if not slots[key] then
        slots[key] = {
            id = key,
            kind = "slot",
            bufnr = nil,
            job = nil,
            pid = nil,
            cwd = nil,
            created_at = 0,
            exited = false,
        }
    end
    return slots[key]
end

--- @param slot table
--- @return boolean
local function alive(slot)
    if not slot or not slot.job or not slot.bufnr then
        return false
    end
    if not vim.api.nvim_buf_is_valid(slot.bufnr) then
        return false
    end
    return vim.fn.jobwait({ slot.job }, 0)[1] == -1
end

--- @param slot table
--- @return integer window id or -1
local function visible_win(slot)
    if not slot or not slot.bufnr or not vim.api.nvim_buf_is_valid(slot.bufnr) then
        return -1
    end
    return vim.fn.bufwinid(slot.bufnr)
end

--- @param id string|integer
--- @return boolean
function M.is_visible(id)
    return visible_win(ensure_slot(id)) ~= -1
end

--- Real cwd of a slot's shell, plus how it was determined.
--- @param id string|integer
--- @return string? cwd
--- @return string? source 'proc'|'tracked'|'unknown'
function M.slot_cwd(id)
    local slot = ensure_slot(id)
    if alive(slot) and slot.pid then
        local cwd, source = process.cwd_of(slot.pid)
        if cwd then
            return cwd, source
        end
    end
    if slot.cwd then
        return slot.cwd, "tracked"
    end
    return nil, "unknown"
end

--- Is the slot's shell idle (at a prompt) and therefore safe to write to?
--- @param id string|integer
--- @return boolean|nil
function M.is_idle(id)
    local slot = ensure_slot(id)
    if not alive(slot) or not slot.pid then
        return nil
    end
    return process.foreground_idle(slot.pid)
end

--- ---------------------------------------------------------------------------
--- Creation / display
--- ---------------------------------------------------------------------------

--- @return string[]
local function shell_command()
    local shell = opts.shell or vim.o.shell
    if shell == nil or shell == "" then
        shell = vim.env.SHELL or "sh"
    end
    local cmd = { shell }
    for _, arg in ipairs(vim.list_extend({}, opts.shell_args or {})) do
        cmd[#cmd + 1] = arg
    end
    return cmd
end

--- @param value number ratio (0..1) or absolute cells
--- @param total integer
--- @return integer
local function resolve_size(value, total)
    if value <= 0 then
        return math.max(1, total)
    end
    if value < 1 then
        return math.max(10, math.floor(total * value))
    end
    return math.min(math.floor(value), total)
end

--- Create the terminal buffer + process for a slot.
--- @param slot table
--- @param spec table { cmd?: string[], cwd?: string, title?: string, close_on_exit?: boolean }
local function create_terminal(slot, spec)
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].bufhidden = "hide"
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].buflisted = false
    vim.api.nvim_buf_set_name(bufnr, ("core-term-%s"):format(slot.id))

    local cmd = spec.cmd or shell_command()
    local cwd = spec.cwd
    if cwd and not fs.is_dir(cwd) then
        notify.warn(("terminal %s: %s is not a directory, using cwd"):format(slot.id, cwd))
        cwd = nil
    end

    local job
    local ok, err = pcall(vim.api.nvim_buf_call, bufnr, function()
        job = vim.fn.termopen(cmd, {
            cwd = cwd,
            on_exit = function(_, code)
                vim.schedule(function()
                    slot.exited = true
                    slot.job = nil
                    if slot.close_on_exit then
                        local win = visible_win(slot)
                        if win ~= -1 then
                            pcall(vim.api.nvim_win_close, win, true)
                        end
                        if vim.api.nvim_buf_is_valid(slot.bufnr) then
                            pcall(vim.api.nvim_buf_delete, slot.bufnr, { force = true })
                        end
                        slots[slot.id] = nil
                    elseif code ~= 0 then
                        notify.info(("terminal %s exited with code %d"):format(slot.id, code))
                    end
                end)
            end,
        })
    end)

    if not ok or not job or job == 0 then
        pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
        notify.error(
            ("terminal %s: cannot start %q (%s)"):format(
                slot.id,
                cmd[1],
                tostring(err or "termopen failed")
            )
        )
        return false
    end

    slot.bufnr = bufnr
    slot.job = job
    slot.pid = vim.fn.jobpid(job)
    slot.cwd = cwd or (vim.uv.cwd() or vim.fn.getcwd())
    slot.created_at = vim.uv.hrtime()
    slot.exited = false
    slot.close_on_exit = spec.close_on_exit == true
    slot.title = spec.title or ("term %s"):format(slot.id)
    slot.kind = spec.cmd and "command" or "slot"
    return true
end

--- @param slot table
--- @return table window config
local function float_config(slot)
    local width = resolve_size(opts.width or 0.8, vim.o.columns)
    local height = resolve_size(opts.height or 0.75, vim.o.lines - vim.o.cmdheight - 1)
    local row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1)
    local col = math.max(0, math.floor((vim.o.columns - width) / 2))
    local title = slot.title or ("term %s"):format(slot.id)
    local cwd = M.slot_cwd(slot.id)
    if opts.title and cwd then
        title = ("%s  %s"):format(title, vim.fn.fnamemodify(cwd, ":~"))
    end
    return {
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        style = "minimal",
        border = opts.border or "rounded",
        title = opts.title and (" %s "):format(title) or nil,
        title_pos = "center",
        zindex = 50,
    }
end

--- @param slot table
local function show(slot)
    local win = visible_win(slot)
    if win == -1 then
        win = vim.api.nvim_open_win(slot.bufnr, true, float_config(slot))
    else
        vim.api.nvim_set_current_win(win)
    end
    vim.wo[win].winblend = opts.winblend or 0
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].foldcolumn = "0"
    vim.wo[win].wrap = false
    vim.wo[win].list = false
    vim.wo[win].spell = false
    vim.wo[win].cursorline = false
    vim.keymap.set("n", "<Esc>", function()
        M.hide(slot.id)
    end, { buffer = slot.bufnr, silent = true, desc = "hide terminal" })
    if opts.start_insert then
        vim.cmd.startinsert()
    end
end

--- ---------------------------------------------------------------------------
--- Public terminal operations
--- ---------------------------------------------------------------------------

--- Open (or focus) a slot, creating the terminal on first use.
--- @param id string|integer
--- @param spec? table { cmd?: string[], cwd?: string, close_on_exit?: boolean, sync?: boolean }
--- @return boolean ok
function M.open(id, spec)
    spec = spec or {}
    local slot = ensure_slot(id)

    if alive(slot) and spec.force_new then
        M.kill(id)
        slot = ensure_slot(id)
    end

    if not alive(slot) then
        if slot.bufnr and vim.api.nvim_buf_is_valid(slot.bufnr) then
            local win = visible_win(slot)
            if win ~= -1 then
                pcall(vim.api.nvim_win_close, win, true)
            end
            pcall(vim.api.nvim_buf_delete, slot.bufnr, { force = true })
            slot.bufnr = nil
        end
        local cwd = spec.cwd or (not spec.cmd and M.context_cwd() or nil)
        if spec.cmd then
            last_command = { cmd = spec.cmd, cwd = cwd, title = spec.title, slot = slot.id }
        end
        if
            not create_terminal(slot, {
                cmd = spec.cmd,
                cwd = cwd,
                title = spec.title,
                close_on_exit = spec.close_on_exit,
            })
        then
            return false
        end
        last_used_slot = tonumber(slot.id) or last_used_slot
    else
        -- Reuse: only synchronize while hidden (the visible terminal is user-owned).
        if not M.is_visible(slot.id) and spec.cwd then
            M.sync_slot(slot.id, spec.cwd)
        end
        slot.title = spec.title or slot.title
    end

    show(slot)
    return true
end

--- Hide a slot's window (the process keeps running).
--- @param id string|integer
--- @return boolean
function M.hide(id)
    local slot = slots[slot_id(id)]
    if not slot then
        return false
    end
    local win = visible_win(slot)
    if win == -1 then
        return false
    end
    pcall(vim.api.nvim_win_close, win, true)
    return true
end

--- Toggle a slot's visibility.
--- @param id? string|integer defaults to slot 1
--- @return boolean ok
function M.toggle(id)
    id = id or 1
    if M.is_visible(id) then
        M.hide(id)
        return true
    end
    return M.open(id)
end

--- Hide every visible terminal window.
function M.hide_all()
    for _, slot in pairs(slots) do
        local win = visible_win(slot)
        if win ~= -1 then
            pcall(vim.api.nvim_win_close, win, true)
        end
    end
end

--- Terminate a slot's process and delete its buffer.
--- @param id string|integer
--- @return boolean
function M.kill(id)
    local key = slot_id(id)
    local slot = slots[key]
    if not slot then
        return false
    end
    local win = visible_win(slot)
    if win ~= -1 then
        pcall(vim.api.nvim_win_close, win, true)
    end
    if slot.job then
        pcall(vim.fn.jobstop, slot.job)
    end
    if slot.bufnr and vim.api.nvim_buf_is_valid(slot.bufnr) then
        pcall(vim.api.nvim_buf_delete, slot.bufnr, { force = true })
    end
    slots[key] = nil
    return true
end

--- Terminate every terminal (used by `:ConfigReload`).
function M.kill_all()
    for id in pairs(slots) do
        M.kill(id)
    end
    slots = {}
end

--- Write text to a slot's process (no implicit newline).
--- @param id string|integer
--- @param text string
--- @return boolean ok
function M.send(id, text)
    local slot = slots[slot_id(id)]
    if not alive(slot) then
        return false
    end
    return process.write(slot.bufnr and vim.bo[slot.bufnr].channel or slot.job, text)
end

--- Current project context directory (root when detected, else cwd).
--- @return string
function M.context_cwd()
    local ok, root = pcall(require, "core.root")
    if ok and root then
        return root.context_root()
    end
    return vim.uv.cwd() or vim.fn.getcwd()
end

--- Synchronize one slot to `cwd` if it is hidden, alive, idle and out of date.
--- @param id string|integer
--- @param cwd string
--- @return boolean synced
--- @return string|nil reason
function M.sync_slot(id, cwd)
    local slot = slots[slot_id(id)]
    if not slot then
        return false, "unknown slot"
    end
    if not alive(slot) then
        return false, "not running"
    end
    if M.is_visible(slot.id) then
        return false, "visible terminals are never changed"
    end
    local target = vim.uv.fs_realpath(cwd) or cwd
    local current, source = M.slot_cwd(slot.id)
    if source ~= "proc" then
        if not warned_no_proc then
            warned_no_proc = true
            notify.once(
                "terminal.sync.unsupported",
                "terminal cwd sync needs /proc and is disabled on this platform",
                "WARN"
            )
        end
        return false, "cwd not observable"
    end
    if current == target then
        return false, "already at target"
    end
    if (vim.uv.hrtime() - slot.created_at) / 1e6 < (opts.sync_grace_ms or 500) then
        return false, "shell still starting"
    end
    local idle = process.foreground_idle(slot.pid)
    if idle == nil then
        return false, "cannot determine shell state"
    end
    if idle == false then
        return false, "shell is busy"
    end
    -- Absolute paths only, so `cd` cannot be confused by a leading dash.
    local cmd = ("cd %s\n"):format(vim.fn.shellescape(target))
    if not M.send(slot.id, cmd) then
        return false, "write failed"
    end
    slot.cwd = target
    return true, nil
end

--- Synchronize every eligible slot with the current project context.
--- @param cwd? string
--- @return integer synced
function M.sync_cwd(cwd)
    if not opts.sync_cwd then
        return 0
    end
    cwd = cwd or M.context_cwd()
    if type(cwd) ~= "string" or cwd == "" or not fs.is_dir(cwd) then
        return 0
    end
    local n = 0
    for id in pairs(slots) do
        local ok = M.sync_slot(id, cwd)
        if ok then
            n = n + 1
        end
    end
    return n
end

--- ---------------------------------------------------------------------------
--- Command entry points
--- ---------------------------------------------------------------------------

--- `:Terminal [n|next|close|info]`
--- @param args vim.api.keyset.create_user_command.command_args
function M.cmd(args)
    local arg = args.fargs and args.fargs[1] or ""
    if arg == "" then
        M.toggle(1)
        return
    end
    if arg == "close" then
        M.hide_all()
        return
    end
    if arg == "info" then
        report.open({
            title = "Terminals",
            name = "core://terminals",
            lines = function()
                return M.report_lines()
            end,
            on_line = function(line)
                local id = line:match("^(%S+)%s")
                if id and slots[id] and alive(slots[id]) then
                    M.toggle(id)
                end
            end,
        })
        return
    end
    if arg == "next" then
        local count = tonumber(opts.slots) or 1
        local start = tonumber(last_used_slot) or 0
        M.toggle((start % count) + 1)
        last_used_slot = (start % count) + 1
        return
    end
    local index = tonumber(arg)
    if not index or index < 1 then
        notify.error(
            (":Terminal: expected a slot number >= 1, or next|close|info (got %q)"):format(arg)
        )
        return
    end
    if index > (tonumber(opts.slots) or 1) then
        notify.warn(
            ("slot %d is beyond the configured %d slots (opening anyway)"):format(
                index,
                opts.slots or 1
            )
        )
    end
    M.toggle(index)
    last_used_slot = index
end

--- `:Lazygit [root|cwd]`
--- @param args vim.api.keyset.create_user_command.command_args
function M.cmd_lazygit(args)
    local mode = (args.fargs and args.fargs[1]) or "root"
    if mode ~= "root" and mode ~= "cwd" then
        notify.error((":Lazygit: expected root|cwd, got %q"):format(mode))
        return
    end
    if not process.have("lazygit") then
        notify.error("lazygit is not installed or not in PATH (see :checkhealth config)")
        return
    end
    M.lazygit(mode)
end

--- Open lazygit in the shared floating terminal infrastructure.
--- @param mode 'root'|'cwd'
--- @return boolean ok
function M.lazygit(mode)
    local cwd
    if mode == "cwd" then
        cwd = vim.uv.cwd() or vim.fn.getcwd()
    else
        local root
        local ok, rootmod = pcall(require, "core.root")
        if ok and rootmod then
            root = rootmod.get(0)
        end
        if root then
            cwd = root
        else
            cwd = vim.uv.cwd() or vim.fn.getcwd()
            notify.warn(("no project root detected; running lazygit in %s"):format(cwd))
        end
    end
    if not cwd or not fs.is_dir(cwd) then
        notify.error(("lazygit: %s is not a usable directory"):format(tostring(cwd)))
        return false
    end

    local slot = ensure_slot("lazygit")
    if alive(slot) then
        local current = M.slot_cwd("lazygit")
        if current == cwd then
            if M.is_visible("lazygit") then
                notify.info(("lazygit is already open in %s"):format(current))
                return true
            end
            return M.open(
                "lazygit",
                { cmd = { "lazygit" }, cwd = cwd, title = "lazygit", close_on_exit = true }
            )
        end
        if M.is_visible("lazygit") then
            notify.warn(
                ("lazygit is open in %s; close it before switching directories"):format(
                    tostring(current)
                )
            )
            return false
        end
        -- Hidden and pointing at another directory: restart it there.
        M.kill("lazygit")
    end
    return M.open(
        "lazygit",
        { cmd = { "lazygit" }, cwd = cwd, title = "lazygit", close_on_exit = true }
    )
end

--- ---------------------------------------------------------------------------
--- Inspector
--- ---------------------------------------------------------------------------

--- @return string[]
function M.report_lines()
    -- Slot order is made deterministic: the report used to follow `pairs()`
    -- order, which made two runs of `:Terminal info` differ.
    local ids = vim.iter(slots)
        :map(function(id)
            return id
        end)
        :totable()
    table.sort(ids, function(a, b)
        return (tonumber(a) or math.huge) < (tonumber(b) or math.huge)
    end)
    local lines = {
        ("slots configured  %d"):format(opts.slots or 1),
        ("sync_cwd          %s"):format(tostring(opts.sync_cwd)),
        ("context cwd       %s"):format(M.context_cwd()),
        "",
        ("%-10s %-8s %-8s %-8s %-8s %s"):format("SLOT", "ALIVE", "VISIBLE", "PID", "IDLE", "CWD"),
    }
    vim.list_extend(
        lines,
        vim.iter(ids)
            :map(function(id)
                local slot = slots[id]
                local cwd, source = M.slot_cwd(id)
                local idle = M.is_idle(id)
                return ("%-10s %-8s %-8s %-8s %-8s %s"):format(
                    id,
                    tostring(alive(slot)),
                    tostring(M.is_visible(id)),
                    tostring(slot.pid or "-"),
                    idle == nil and "?" or tostring(idle),
                    ("%s (%s)"):format(tostring(cwd), source)
                )
            end)
            :totable()
    )
    if next(slots) == nil then
        lines[#lines + 1] = "(no terminals have been opened yet)"
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Press <CR> to toggle the terminal on the current line, q to close."
    return lines
end

--- ---------------------------------------------------------------------------
--- Setup / teardown
--- ---------------------------------------------------------------------------

--- @param o? table
function M.setup(o)
    opts = o or defaults.get("terminal", {})
    lc = lifecycle.new({ name = "core.terminal" })
    lc:on_teardown(function()
        M.kill_all()
    end)

    local keys = opts.keys or {}
    if keys.toggle then
        lc:keymap("n", keys.toggle, function()
            M.toggle(1)
            last_used_slot = 1
        end, { desc = "toggle terminal slot 1" })
    end
    if keys.close then
        lc:keymap("n", keys.close, function()
            M.hide_all()
        end, { desc = "hide terminals" })
    end
    if keys.slot then
        for i = 1, (tonumber(opts.slots) or 1) do
            local lhs = keys.slot:gsub("{n}", tostring(i))
            lc:keymap({ "n", "t" }, lhs, function()
                M.toggle(i)
                last_used_slot = i
            end, { desc = ("toggle terminal slot %d"):format(i) })
        end
    end

    if opts.sync_cwd then
        local ok, root = pcall(require, "core.root")
        if ok and root then
            unsubscribe_context = root.on_context_change(function(cwd)
                M.sync_cwd(cwd)
            end)
        end
    end

    lc:autocmd("TermClose", {
        group_name = "terminal_bookkeeping",
        desc = "core: keep terminal slot bookkeeping accurate",
        callback = function(args)
            for _, slot in pairs(slots) do
                if slot.bufnr == args.buf then
                    slot.exited = true
                end
            end
        end,
    })

    lc:activate()
end

--- Teardown: terminals are processes, not just state -- they are terminated so
--- that a reload cannot leave orphaned shells behind.
function M.teardown()
    if unsubscribe_context then
        unsubscribe_context()
        unsubscribe_context = nil
    end
    M.kill_all()
    if lc then
        lc:teardown()
        lc = nil
    end
end

--- @return table
function M.inspect()
    return {
        ids = vim.iter(slots)
            :map(function(id)
                return id
            end)
            :totable(),
        opts = opts,
        last_command = last_command,
    }
end

--- Inspectable state of one slot (used by tests and `:Terminal info`).
--- @param id string|integer
--- @return table|nil
function M.slot_state(id)
    local slot = slots[slot_id(id)]
    if not slot then
        return nil
    end
    local cwd, source = M.slot_cwd(slot.id)
    return {
        id = slot.id,
        bufnr = slot.bufnr,
        job = slot.job,
        pid = slot.pid,
        alive = alive(slot),
        visible = M.is_visible(slot.id),
        cwd = cwd,
        cwd_source = source,
        idle = M.is_idle(slot.id),
        kind = slot.kind,
    }
end

return M
