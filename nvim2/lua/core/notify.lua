--- Notification abstraction.
---
--- The backend is intentionally indirect: Neovim may not have `mini.notify`
--- loaded (or installed at all), especially during early startup. Every call
--- therefore goes through this module, which:
---
---   * filters by a configurable minimum level,
---   * keeps an inspectable history ring buffer,
---   * supports deduplication (`notify.once`) for repeating conditions,
---   * never raises -- a failing backend degrades to `vim.notify`.
---
--- Backend selection: `mini.notify` (or any other UI plugin) is expected to
--- install itself as the Neovim notification handler (`vim.notify`), which is
--- the documented `mini.notify` usage. `notify.set_backend()` exists for
--- explicit control and is what `lua/plugins/mini.lua` uses.
---
--- @class core.notify
local M = {}

local util = require("lib.util")

--- @alias core.notify.Level 'DEBUG'|'INFO'|'WARN'|'ERROR'

M.levels = {
    DEBUG = vim.log.levels.DEBUG,
    INFO = vim.log.levels.INFO,
    WARN = vim.log.levels.WARN,
    ERROR = vim.log.levels.ERROR,
    OFF = 99,
}

--- @type table
local state = {
    level = M.levels.INFO,
    history_size = 50,
    once_ms = 5000,
    history = {}, --- @type { msg: string, level: integer, time: integer }[]
    backend = nil, --- @type fun(msg: string, level: integer, opts: table)|nil
    seen = {}, --- @type table<string, integer>
    failures = 0,
}

--- @param opts? { level?: string, history?: integer, once_ms?: integer }
function M.setup(opts)
    opts = opts or {}
    if opts.level ~= nil then
        local lvl = M.levels[tostring(opts.level):upper()]
        if not lvl then
            M.warn(("core.notify: unknown level %q, keeping current"):format(tostring(opts.level)))
        else
            state.level = lvl
        end
    end
    if opts.history then
        state.history_size = opts.history
    end
    if opts.once_ms then
        state.once_ms = opts.once_ms
    end
end

--- Set an explicit backend.
--- @param backend fun(msg: string, level: integer, opts?: table)|nil # nil resets to `vim.notify`
function M.set_backend(backend)
    state.backend = backend
end

--- @return string
function M.backend_name()
    if state.backend then
        return "custom"
    end
    if package.loaded["mini.notify"] then
        return "mini.notify"
    end
    return "vim.notify"
end

--- @return { msg: string, level: integer, time: integer }[]
function M.history()
    return vim.deepcopy(state.history)
end

--- @param level integer
--- @return boolean
function M.enabled(level)
    return level >= state.level
end

--- Deliver a notification through the backend (history + backend call).
--- Never raises: a failing backend degrades to `vim.notify`.
--- @param msg string
--- @param level integer
--- @param opts table?
local function deliver(msg, level, opts)
    opts = opts or {}
    state.history[#state.history + 1] = { msg = msg, level = level, time = os.time() }
    while #state.history > state.history_size do
        table.remove(state.history, 1)
    end

    local backend = state.backend or vim.notify
    local ok, err = pcall(backend, msg, level, opts)
    if not ok then
        state.failures = state.failures + 1
        -- Last-resort path: never let a notification break the caller.
        pcall(
            vim.notify,
            ("notify backend failed: %s\n%s"):format(tostring(err), msg),
            vim.log.levels.ERROR
        )
    end
end

--- @param msg string
--- @param level integer
--- @param opts table?
local function emit(msg, level, opts)
    if not M.enabled(level) then
        return
    end
    msg = type(msg) ~= "string" and vim.inspect(msg) or msg
    opts = opts or {}

    -- Error-level messages are deferred by one event-loop tick: Neovim treats an
    -- error being echoed inside a command as a failure of that command (observed
    -- with `:write` + `BufWritePre`), and reporting an error must never change
    -- the outcome of the operation that produced it.
    if level >= vim.log.levels.ERROR and not vim.in_fast_event() then
        vim.schedule(function()
            deliver(msg, level, opts)
        end)
        return
    end

    deliver(msg, level, opts)
end

--- @param msg string
--- @param opts? table
function M.info(msg, opts)
    emit(msg, vim.log.levels.INFO, opts)
end

--- @param msg string
--- @param opts? table
function M.warn(msg, opts)
    emit(msg, vim.log.levels.WARN, opts)
end

--- @param msg string
--- @param opts? table
function M.error(msg, opts)
    emit(msg, vim.log.levels.ERROR, opts)
end

--- @param msg string
--- @param opts? table
function M.debug(msg, opts)
    emit(msg, vim.log.levels.DEBUG, opts)
end

--- Report a message at most once per `once_ms` window per `key`.
--- Used for repeating conditions (missing formatter, LSP restarts, ...).
--- @param key string
--- @param msg string
--- @param level? 'DEBUG'|'INFO'|'WARN'|'ERROR'
--- @param opts? table
function M.once(key, msg, level, opts)
    level = level or "INFO"
    local lvl = M.levels[level]
    local last = state.seen[key]
    local now = vim.uv.hrtime() / 1e6
    if last and (now - last) < state.once_ms then
        return
    end
    state.seen[key] = now
    emit(msg, lvl or vim.log.levels.INFO, opts)
end

--- Format an error value (string or table) for a notification.
--- @param err any
--- @return string
function M.error_text(err)
    local text = type(err) == "table" and (err.message or vim.inspect(err)) or tostring(err)
    return util.trim(text)
end

return M
