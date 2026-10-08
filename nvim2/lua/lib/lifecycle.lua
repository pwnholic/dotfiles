--- Resource ownership + setup/teardown/reload support.
---
--- Every subsystem that creates reversible resources (autocommands, keymaps,
--- user commands, augroups, timers, file watchers) does it through a
--- `lib.Lifecycle` object. Teardown is therefore exact: only resources created
--- by that object are removed, which is what makes `:ConfigReload` free of
--- duplicates and stale state.
---
--- Lifecycle objects are registered globally so the reload subsystem can tear
--- everything down in reverse setup order.
---
local M = {}

--- Lifecycle instance: owns the resources of one subsystem generation.
--- @class lib.Lifecycle
--- @field name string
--- @field _augroups integer[]
--- @field _autocmd_ids integer[]
--- @field _keymaps { mode: string, lhs: string, buffer: integer? }[]
--- @field _commands string[]
--- @field _timers uv_timer_t[]
--- @field _handles { stop: fun() }[]
--- @field _teardown fun()[]
--- @field _active boolean
local Lifecycle = {}
Lifecycle.__index = Lifecycle

--- Every created lifecycle, in setup order.
--- @type lib.Lifecycle[]
local stack = {}

--- @param opts? { name?: string }
--- @return lib.Lifecycle
function Lifecycle.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Lifecycle)
    self.name = opts.name or "lifecycle"
    self._augroups = {} --- @type integer[]
    self._autocmd_ids = {} --- @type integer[]
    self._keymaps = {} --- @type { mode: string, lhs: string, buffer: integer? }[]
    self._commands = {} --- @type string[]
    self._timers = {} --- @type uv_timer_t[]
    self._handles = {} --- @type { stop: fun() }[]
    self._teardown = {} --- @type fun()[]
    self._active = false

    -- Idempotency: re-creating a lifecycle with a name that is still active
    -- tears the previous generation down first. This makes a repeated
    -- `setup()` of a subsystem duplicate-free instead of relying on callers.
    for i = #stack, 1, -1 do
        local previous = stack[i]
        if previous.name == self.name and previous._active then
            previous:teardown()
            table.remove(stack, i)
        end
    end

    stack[#stack + 1] = self
    return self
end

--- Mark the object as active (called by `setup`).
function Lifecycle:activate()
    self._active = true
end

--- Create or reuse an augroup owned by this lifecycle.
--- `clear = true` on first use guarantees no duplicate autocommands survive a
--- reload of this subsystem.
--- @param name string
--- @return integer
function Lifecycle:augroup(name)
    local group = vim.api.nvim_create_augroup("core." .. name, { clear = false })
    if not vim.tbl_contains(self._augroups, group) then
        self._augroups[#self._augroups + 1] = group
        -- Clear once when the group is adopted so re-running setup() cannot stack
        -- duplicate autocommands from an earlier (failed) setup pass.
        vim.api.nvim_clear_autocmds({ group = group })
    end
    return group
end

--- @param event string|string[]
--- @param opts table `nvim_create_autocmd` options; `group_name` is a
---   lifecycle-private key and is translated into an owned augroup.
--- @return integer autocmd id
function Lifecycle:autocmd(event, opts)
    opts = vim.deepcopy(opts)
    local group_name = opts.group_name or "general"
    opts.group_name = nil
    opts.group = self:augroup(group_name)
    local id = vim.api.nvim_create_autocmd(event, opts)
    self._autocmd_ids[#self._autocmd_ids + 1] = id
    return id
end

--- Delete one autocommand previously created through this lifecycle.
--- @param id integer
function Lifecycle:del_autocmd(id)
    pcall(vim.api.nvim_del_autocmd, id)
    for i, v in ipairs(self._autocmd_ids) do
        if v == id then
            table.remove(self._autocmd_ids, i)
            break
        end
    end
end

--- @param mode string|string[]
--- @param lhs string
--- @param rhs string|function
--- @param opts? table
function Lifecycle:keymap(mode, lhs, rhs, opts)
    opts = vim.deepcopy(opts or {})
    local buffer = opts.buffer
    vim.keymap.set(mode, lhs, rhs, opts)
    --- @type string[]
    local modes = type(mode) == "table" and mode or { mode }
    for _, m in ipairs(modes) do
        self._keymaps[#self._keymaps + 1] = { mode = m, lhs = lhs, buffer = buffer }
    end
end

--- Register a user command. `opts.func` is required for the `nvim_create_user_command`
--- contract; the name is tracked so teardown removes exactly our command.
--- @param name string
--- @param rhs string|function
--- @param opts? table
function Lifecycle:command(name, rhs, opts)
    opts = vim.deepcopy(opts or {})
    opts.force = true
    -- Lifecycle-private keys must never reach the API (it validates strictly).
    opts.owner, opts.override, opts.group_name = nil, nil, nil
    vim.api.nvim_create_user_command(name, rhs, opts)
    self._commands[#self._commands + 1] = name
end

--- Delete one user command created through this lifecycle.
--- @param name string
function Lifecycle:del_command(name)
    pcall(vim.api.nvim_del_user_command, name)
    for i, v in ipairs(self._commands) do
        if v == name then
            table.remove(self._commands, i)
            break
        end
    end
end

--- Create a repeating/one-shot timer owned by this lifecycle.
--- @param opts { timeout: integer, repeat?: integer, callback: fun() }
--- @return uv_timer_t
function Lifecycle:timer(opts)
    local timer = vim.uv.new_timer()
    timer:start(opts.timeout, opts["repeat"] or 0, vim.schedule_wrap(opts.callback))
    self._timers[#self._timers + 1] = timer
    return timer
end

--- @param fn fun()
function Lifecycle:on_teardown(fn)
    self._teardown[#self._teardown + 1] = fn
end

--- Remove every resource created through this object (reverse creation order).
--- @return string[] problems
function Lifecycle:teardown()
    local problems = {}
    for i = #self._teardown, 1, -1 do
        local ok, err = pcall(self._teardown[i])
        if not ok then
            problems[#problems + 1] = ("teardown hook: %s"):format(err)
        end
    end
    self._teardown = {}

    for i = #self._timers, 1, -1 do
        local timer = self._timers[i]
        if not timer:is_closing() then
            timer:stop()
            timer:close()
        end
    end
    self._timers = {}

    for i = #self._handles, 1, -1 do
        local ok, err = pcall(self._handles[i].stop)
        if not ok then
            problems[#problems + 1] = ("handle stop: %s"):format(err)
        end
    end
    self._handles = {}

    for i = #self._commands, 1, -1 do
        local ok, err = pcall(vim.api.nvim_del_user_command, self._commands[i])
        if not ok and not tostring(err):match("E184") then
            problems[#problems + 1] = ("del command %s: %s"):format(self._commands[i], err)
        end
    end
    self._commands = {}

    for i = #self._keymaps, 1, -1 do
        local km = self._keymaps[i]
        local ok, err =
            pcall(vim.keymap.del, km.mode, km.lhs, km.buffer and { buffer = km.buffer } or nil)
        if not ok and not tostring(err):match("E31") then
            problems[#problems + 1] = ("del mapping %s %s: %s"):format(km.mode, km.lhs, err)
        end
    end
    self._keymaps = {}

    for i = #self._augroups, 1, -1 do
        local ok, err = pcall(vim.api.nvim_del_augroup_by_id, self._augroups[i])
        if not ok then
            problems[#problems + 1] = ("del augroup %d: %s"):format(self._augroups[i], err)
        end
    end
    self._augroups = {}
    self._autocmd_ids = {}

    self._active = false
    return problems
end

--- Tear down every lifecycle, newest first. Returns collected problems.
--- @return { name: string, problems: string[] }[]
function Lifecycle.teardown_all()
    local problems = {}
    for i = #stack, 1, -1 do
        local lc = stack[i]
        local errs = lc:teardown()
        if #errs > 0 then
            problems[#problems + 1] = { name = lc.name, problems = errs }
        end
    end
    stack = {}
    return problems
end

--- Forget all registered lifecycles without tearing them down (used when a
--- reload re-creates the module state).
function Lifecycle.reset_registry()
    stack = {}
end

--- @param opts? { name?: string }
--- @return lib.Lifecycle
function M.new(opts)
    return Lifecycle.new(opts)
end

--- @return { name: string, problems: string[] }[]
function M.teardown_all()
    return Lifecycle.teardown_all()
end

function M.reset_registry()
    Lifecycle.reset_registry()
end

return M
