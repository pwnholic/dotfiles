--- Declarative toggle registry.
---
--- Every toggle is data. The framework owns scope handling, keymaps,
--- notifications and the "report the actual resulting state" rule; the entry
--- owns how to read and write the state.
---
--- Entry schema (`require('core.toggle').register{ ... }`):
---
---   id        string    unique id (also used for `<leader>u*` keymap lookup)
---   label     string    user-facing name ("Diagnostics")
---   scope     string    'global' | 'buffer' | 'window'
---   get       function  `fun(ctx) -> boolean|nil`   -- nil = unknown/unavailable
---   set       function  `fun(value, ctx)`           -- result is verified via `get`
---   default   boolean?  applied once at setup (nil = leave Neovim's default)
---   key       string?   keymap, falls back to `defaults.toggles.keys[id]`
---   deps      string[]? plugin ids to load (through `core.pack`) before toggling
---   available function? `fun() -> boolean, why?`
---   notify    boolean?  per-entry override of `defaults.toggles.notify`
---
--- Plugins attach implementations for toggles they own with
--- `require('core.toggle').attach(id, { get = ..., set = ... })`, which keeps
--- `core` free of plugin-specific knowledge.
---
--- Implementation of a toggle, provided by core or a plugin.
--- @class core.toggle.Impl
--- @field get fun(ctx: table): boolean|nil
--- @field set fun(value: boolean, ctx: table): any
--- @field available? fun(): boolean|nil, string|nil

--- @class core.toggle
local M = {}

local Registry = require("lib.registry")
local defaults = require("core.defaults")
local lifecycle = require("lib.lifecycle")
local notify = require("core.notify")
local report = require("lib.report")

--- @type lib.Registry
local registry = Registry.new({ name = "toggles" })
--- @type lib.Lifecycle
--- @type lib.Lifecycle?
local lc
--- @type fun(root: string|nil, previous: string|nil)|nil
local unsubscribe_context

--- ---------------------------------------------------------------------------
--- Context
--- ---------------------------------------------------------------------------

--- @param bufnr? integer
--- @param winid? integer
--- @return table ctx
function M.ctx(bufnr, winid)
    local buf = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
    local win = (winid == nil or winid == 0) and vim.api.nvim_get_current_win() or winid
    return {
        bufnr = buf,
        winid = win,
        buf_valid = vim.api.nvim_buf_is_valid(buf),
        win_valid = vim.api.nvim_win_is_valid(win),
    }
end

--- ---------------------------------------------------------------------------
--- Registry
--- ---------------------------------------------------------------------------

--- @param entry table
--- @return boolean ok
--- @return string? err
function M.register(entry, opts)
    if type(entry) ~= "table" then
        return false, "toggle entry must be a table"
    end
    if type(entry.id) ~= "string" or entry.id == "" then
        return false, "toggle needs a non-empty string id"
    end
    local scope = entry.scope or "global"
    if scope ~= "global" and scope ~= "buffer" and scope ~= "window" then
        return false,
            ("toggle %q: scope must be global|buffer|window, got %q"):format(
                entry.id,
                tostring(scope)
            )
    end
    if entry.get ~= nil and type(entry.get) ~= "function" then
        return false, ("toggle %q: get must be a function"):format(entry.id)
    end
    if entry.set ~= nil and type(entry.set) ~= "function" then
        return false, ("toggle %q: set must be a function"):format(entry.id)
    end
    local def = vim.deepcopy(entry)
    def.scope = scope
    def.label = def.label or (def.id:gsub("^%l", string.upper))
    return registry:register(def, opts)
end

--- Attach (or replace) the implementation of a registered toggle. Plugins use
--- this to provide behaviour without core knowing about them.
--- @param id string
--- @param impl core.toggle.Impl|nil # nil detaches the implementation
--- @return boolean ok
--- @return string? err
function M.attach(id, impl)
    local def = registry:get(id)
    if not def then
        return false, ("toggle %q is not registered"):format(id)
    end
    if type(impl) ~= "table" or type(impl.get) ~= "function" or type(impl.set) ~= "function" then
        return false, ("toggle %q: implementation needs get and set functions"):format(id)
    end
    def.get = function(ctx)
        return impl.get(ctx)
    end
    def.set = function(value, ctx)
        return impl.set(value, ctx)
    end
    def.available = impl.available
    def.attached = true
    return true
end

--- @return table[]
function M.list()
    return registry:list()
end

--- @return string[]
function M.ids()
    return registry:ids()
end

--- ---------------------------------------------------------------------------
--- State access
--- ---------------------------------------------------------------------------

--- @param def table
--- @return boolean available
--- @return string|nil why
local function availability(def)
    if def.available then
        local ok, available, why = pcall(def.available)
        if not ok then
            return false, tostring(available)
        end
        return available ~= false, why
    end
    if not def.get or not def.set then
        return false, "no implementation registered (provider plugin not available?)"
    end
    return true, nil
end

--- Load plugin dependencies declared by a toggle.
--- @param def table
--- @return boolean ok
--- @return string? err
local function ensure_deps(def)
    if not def.deps or #def.deps == 0 then
        return true
    end
    local ok, pack = pcall(require, "core.pack")
    if not ok then
        return true
    end
    for _, id in ipairs(def.deps) do
        if pack.is_declared(id) then
            local loaded, err = pack.load(id)
            if not loaded then
                return false, ("cannot load %q: %s"):format(id, tostring(err))
            end
        end
    end
    return true
end

--- Actual state of a toggle.
--- @param id string
--- @param ctx? table
--- @return boolean|nil state
--- @return string|nil err
function M.state(id, ctx)
    local def = registry:get(id)
    if not def then
        return nil, ("unknown toggle %q"):format(id)
    end
    ctx = ctx or M.ctx()
    if not def.get then
        return nil, ("toggle %q has no implementation"):format(id)
    end
    local ok, state = pcall(def.get, ctx)
    if not ok then
        return nil, tostring(state)
    end
    if type(state) ~= "boolean" then
        return nil, "state could not be determined"
    end
    return state, nil
end

--- Set a toggle and return the *verified* resulting state.
--- @param id string
--- @param value boolean
--- @param ctx? table
--- @return boolean|nil state
--- @return string|nil err
function M.set(id, value, ctx)
    local def = registry:get(id)
    if not def then
        return nil, ("unknown toggle %q"):format(id)
    end
    ctx = ctx or M.ctx()
    local ok_deps, dep_err = ensure_deps(def)
    if not ok_deps then
        return nil, dep_err
    end
    -- Dependencies may have attached an implementation (or replaced the entry).
    def = registry:get(id) or def
    local available, why = availability(def)
    if not available then
        return nil, why or "unavailable"
    end
    local ok, err = pcall(def.set, value, ctx)
    if not ok then
        return nil, tostring(err)
    end
    -- Always re-read: the notification must reflect the real state.
    return M.state(id, ctx)
end

--- Toggle a state and notify the resulting (verified) state.
--- @param id string
--- @param ctx? table
--- @return boolean|nil state
function M.toggle(id, ctx)
    local def = registry:get(id)
    if not def then
        notify.error(("unknown toggle %q"):format(id))
        return nil
    end
    ctx = ctx or M.ctx()

    if ctx.buf_valid == false and (def.scope == "buffer" or def.scope == "window") then
        notify.error(("%s: no valid buffer/window for a %s toggle"):format(def.label, def.scope))
        return nil
    end

    local current, state_err = M.state(id, ctx)
    if current == nil then
        local available, why = availability(def)
        if def.attached or available then
            notify.warn(
                ("%s: state unknown (%s)"):format(def.label, state_err or why or "unavailable")
            )
        else
            notify.warn(("%s: unavailable - %s"):format(def.label, why or "no provider"))
        end
        return nil
    end

    local target = not current
    local result, set_err = M.set(id, target, ctx)
    local should_notify = def.notify
    if should_notify == nil then
        should_notify = defaults.get("toggles.notify", true)
    end
    if should_notify then
        if result == nil then
            notify.warn(
                ("%s: state unknown after toggle (%s)"):format(def.label, set_err or "unavailable")
            )
        else
            notify.info(("%s: %s"):format(def.label, result and "ON" or "OFF"))
        end
    end
    return result
end

--- ---------------------------------------------------------------------------
--- Built-in toggles
--- ---------------------------------------------------------------------------

local function register_builtin_toggles()
    local builtin = {
        {
            id = "diagnostics",
            label = "Diagnostics",
            scope = "global",
            get = function()
                return vim.diagnostic.is_enabled()
            end,
            set = function(value)
                vim.diagnostic.enable(value)
            end,
        },
        {
            id = "inlay_hints",
            label = "Inlay hints",
            scope = "buffer",
            get = function(ctx)
                return vim.lsp.inlay_hint.is_enabled({ bufnr = ctx.bufnr })
            end,
            set = function(value, ctx)
                vim.lsp.inlay_hint.enable(value, { bufnr = ctx.bufnr })
            end,
        },
        {
            id = "autoformat",
            label = "Autoformat (global)",
            scope = "global",
            get = function()
                return require("core.format").enabled()
            end,
            set = function(value)
                require("core.format").set_enabled(value)
            end,
        },
        {
            id = "autoformat_buffer",
            label = "Autoformat (buffer)",
            scope = "buffer",
            get = function(ctx)
                return require("core.format").effective_buffer_enabled(ctx.bufnr)
            end,
            set = function(value, ctx)
                require("core.format").set_buffer_enabled(ctx.bufnr, value)
            end,
        },
        {
            id = "spell",
            label = "Spell",
            scope = "window",
            get = function(ctx)
                return vim.wo[ctx.winid].spell
            end,
            set = function(value, ctx)
                vim.wo[ctx.winid].spell = value
            end,
        },
        {
            id = "wrap",
            label = "Wrap",
            scope = "window",
            get = function(ctx)
                return vim.wo[ctx.winid].wrap
            end,
            set = function(value, ctx)
                vim.wo[ctx.winid].wrap = value
            end,
        },
        {
            id = "relativenumber",
            label = "Relative numbers",
            scope = "window",
            get = function(ctx)
                return vim.wo[ctx.winid].relativenumber
            end,
            set = function(value, ctx)
                vim.wo[ctx.winid].relativenumber = value
            end,
        },
        {
            id = "number",
            label = "Line numbers",
            scope = "window",
            get = function(ctx)
                return vim.wo[ctx.winid].number
            end,
            set = function(value, ctx)
                vim.wo[ctx.winid].number = value
            end,
        },
        {
            id = "cursorword",
            label = "Cursor word highlight",
            -- mini.cursorword decides per buffer via `vim.b[bufnr].minicursorword_disable`.
            scope = "buffer",
            deps = { "mini.nvim" },
            available = function()
                local entry = registry:get("cursorword")
                return entry ~= nil and entry.attached == true,
                    "cursor word provider not loaded (needs the mini.nvim plugin)"
            end,
        },
        {
            id = "treesitter_context",
            label = "Treesitter context",
            scope = "global",
            deps = { "nvim-treesitter-context" },
            available = function()
                local entry = registry:get("treesitter_context")
                return entry ~= nil and entry.attached == true, "nvim-treesitter-context not loaded"
            end,
        },
    }

    for _, entry in ipairs(builtin) do
        -- Core-owned toggles are re-registerable, so a repeated `setup()` (or a
        -- plugin redefining a built-in) cannot fail with a duplicate-id error.
        local ok, err = M.register(entry, { replace = true })
        if not ok then
            notify.error("core.toggle: " .. tostring(err))
        end
    end
end

local function apply_default(name, value, scope)
    if value == nil then
        return
    end
    if scope == "buffer" then
        -- Buffer-scoped gates default to "inherit"; nothing to apply globally.
        return
    end
    local ok, err = pcall(function()
        if name == "diagnostics" then
            vim.diagnostic.enable(value)
        elseif name == "autoformat" then
            require("core.format").set_enabled(value)
        elseif name == "spell" then
            vim.opt.spell = value
        elseif name == "wrap" then
            vim.opt.wrap = value
        elseif name == "relativenumber" then
            vim.opt.relativenumber = value
        elseif name == "number" then
            vim.opt.number = value
        end
    end)
    if not ok then
        notify.warn(("toggle %s default: %s"):format(name, tostring(err)))
    end
end

--- ---------------------------------------------------------------------------
--- Setup
--- ---------------------------------------------------------------------------

function M.setup()
    register_builtin_toggles()
    lc = lifecycle.new({ name = "core.toggle" })

    -- A toggle registered *after* setup (plugin or user configuration) gets its
    -- keymap immediately: no periodic refresh and no dead API.
    registry:on_change(function(event, _, entry)
        if event ~= "register" or not lc then
            return
        end
        local lhs = entry.key ~= nil and entry.key or defaults.get("toggles.keys", {})[entry.id]
        if lhs and lhs ~= false and lhs ~= "" then
            lc:keymap("n", lhs, function()
                M.toggle(entry.id)
            end, { desc = ("toggle %s"):format(entry.label), silent = true })
        end
    end)

    local keys = defaults.get("toggles.keys", {})
    local states = defaults.get("toggles.defaults", {})

    for _, def in ipairs(registry:list()) do
        local lhs = def.key ~= nil and def.key or keys[def.id]
        if lhs == false then
            lhs = nil
        end
        if lhs and lhs ~= "" then
            -- One global mapping: the context (current buffer/window) is resolved at
            -- press time, which is what makes buffer/window scope meaningful.
            lc:keymap("n", lhs, function()
                M.toggle(def.id)
            end, { desc = ("toggle %s"):format(def.label), silent = true })
        end
        apply_default(def.id, states[def.id], def.scope)
    end

    -- Inlay hints: apply the configured default when a server attaches.
    local hint_default = states["inlay_hints"]
    if hint_default ~= nil then
        lc:autocmd("LspAttach", {
            group_name = "inlay_hint_default",
            desc = "core: apply configured inlay hint default",
            callback = function(args)
                pcall(vim.lsp.inlay_hint.enable, hint_default, { bufnr = args.buf })
            end,
        })
    end

    -- Invalidate nothing here: `core.root` owns cache lifecycle.
    lc:activate()
end

function M.teardown()
    if unsubscribe_context then
        unsubscribe_context()
        unsubscribe_context = nil
    end
    if lc then
        lc:teardown()
        lc = nil
    end
end

--- ---------------------------------------------------------------------------
--- Inspector / command
--- ---------------------------------------------------------------------------

--- @return string[]
function M.report_lines()
    local ctx = M.ctx()
    local keys = defaults.get("toggles.keys", {})
    local rows = vim.iter(registry:list())
        :map(function(def)
            local state, err = M.state(def.id, ctx)
            local available, why = availability(def)
            local source
            if state == nil then
                source = available and ("unknown: " .. (err or "?"))
                    or ("unavailable: " .. (why or "?"))
            else
                source = def.attached and "provider plugin" or "core"
            end
            local key = def.key ~= nil and def.key or keys[def.id]
            return ("%-18s %-9s %-8s %-6s %s"):format(
                def.id,
                def.scope,
                key and tostring(key) or "-",
                state == nil and "?" or (state and "ON" or "OFF"),
                source
            )
        end)
        :totable()
    local lines = {
        ("%-18s %-9s %-8s %-6s %s"):format("TOGGLE", "SCOPE", "KEY", "STATE", "SOURCE"),
    }
    vim.list_extend(lines, rows)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Press <CR> on a toggle line to flip it, q to close."
    return lines
end

--- `:Toggles [id]`
--- @param args vim.api.keyset.create_user_command.command_args
function M.cmd(args)
    local id = args.fargs and args.fargs[1]
    if id and id ~= "" then
        if not registry:get(id) then
            notify.error(("unknown toggle %q (known: %s)"):format(id, table.concat(M.ids(), ", ")))
            return
        end
        M.toggle(id)
        return
    end
    report.open({
        title = "Toggles",
        name = "core://toggles",
        lines = function()
            return M.report_lines()
        end,
        on_line = function(line)
            local toggle_id = line:match("^(%S+)%s")
            if toggle_id and registry:get(toggle_id) then
                M.toggle(toggle_id)
            end
        end,
    })
end

return M
