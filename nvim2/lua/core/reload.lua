--- Configuration watcher, soft reload and restart integration.
---
--- Watcher: every directory of the configuration tree (`init.lua`, `lua/**`,
--- `plugin/**`, `after/**`, ...) gets one `uv_fs_event` handle. Events are
--- debounced, filtered, and either reported (default) or used to trigger
--- `:ConfigReload`.
---
--- Reload model (deliberately not `dofile`-per-module):
---
---   1. `User ConfigReloadPre`
---   2. ordered module teardown (`core.init` order reversed) + lifecycle sweep
---   3. drop `core.*` / `lib.*` / `plugins.*` / `config.*` from `package.loaded`
---   4. re-source `init.lua` (keep it declarative) -- fallback: `core.setup(saved opts)`
---   5. `User ConfigReload`
---
--- Teardown is resource-exact, so reload cannot duplicate autocommands,
--- mappings, commands, timers or watchers. Terminals are processes and are
--- therefore terminated (documented): they are recreated on demand.
---
--- @class core.reload
local M = {}

local defaults = require("core.defaults")
local fs = require("lib.fs")
local lifecycle = require("lib.lifecycle")
local notify = require("core.notify")
local report = require("lib.report")

--- @type table
local opts = {}
--- @type table<string, uv_fs_event_t>
local watchers = {}
--- @type uv_timer_t|nil
local debounce
--- @type table<string, boolean>
local pending = {}
--- @type boolean
local enabled = true
--- @type boolean
local reloading = false
--- @type table|nil
local last_reload = nil
--- @type table|nil
local last_event = nil
--- @type integer
local events_seen = 0

local BASE_IGNORE = {
    "^%.git$",
    "^%.git/",
    "^4932$",
    "^4913$",
    "^%.DS_Store$",
    "^nvim%-pack%-lock%.json$",
    "^doc/tags$",
    "%.sw[op]$",
    "%.tmp$",
    "~$",
}

--- @param path string
--- @return boolean
local function ignored(path)
    local rel = path:gsub("^" .. vim.pesc(fs.config_path() .. "/"), "")
    for _, pattern in ipairs(BASE_IGNORE) do
        if rel:find(pattern) then
            return true
        end
    end
    for _, pattern in ipairs(opts.ignore or {}) do
        if path:find(pattern) then
            return true
        end
    end
    return false
end

--- ---------------------------------------------------------------------------
--- Watcher
--- ---------------------------------------------------------------------------

--- @param path string
local function watch_dir(path)
    if watchers[path] then
        return
    end
    local handle = vim.uv.new_fs_event()
    if not handle then
        notify.once(
            "reload.no_handle",
            "cannot create a filesystem watcher handle (watch disabled)",
            "WARN"
        )
        return
    end
    local ok, err = handle:start(path, {}, function(cb_err, filename)
        if cb_err then
            notify.once(
                "reload.event_error",
                ("config watcher error: %s"):format(tostring(cb_err)),
                "WARN"
            )
            return
        end
        events_seen = events_seen + 1
        local changed = filename and filename ~= "" and fs.joinpath(path, filename) or path
        last_event = { path = changed, time = os.time() }
        if ignored(changed) then
            return
        end
        pending[changed] = true
        M.debounce_start()
    end)
    if not ok then
        handle:close()
        notify.once(
            "reload.start_error",
            ("cannot watch %s: %s"):format(path, tostring(err)),
            "WARN"
        )
        return
    end
    watchers[path] = handle
end

--- Start (or restart) the watcher over the whole configuration tree.
function M.start_watcher()
    M.stop_watcher()
    local root = fs.config_path()
    if not fs.is_dir(root) then
        notify.warn(("config directory %s is missing; watcher disabled"):format(root))
        return false
    end
    local dirs = fs.walk_dirs(root, {
        ignore = function(name)
            -- Dot-directories (.git, .luarc caches, ...) are never watched.
            return name:sub(1, 1) == "."
        end,
    })
    for _, dir in ipairs(dirs) do
        watch_dir(dir)
    end
    return true
end

--- Stop the watcher and release every handle.
function M.stop_watcher()
    for path, handle in pairs(watchers) do
        if not handle:is_closing() then
            handle:stop()
            handle:close()
        end
        watchers[path] = nil
    end
    if debounce and not debounce:is_closing() then
        debounce:stop()
    end
end

--- Add watchers for directories created after the initial scan and drop
--- watchers for directories that disappeared.
function M.refresh_watchers()
    local root = fs.config_path()
    local dirs = fs.walk_dirs(root)
    local seen = {}
    for _, dir in ipairs(dirs) do
        seen[dir] = true
        if not watchers[dir] then
            watch_dir(dir)
        end
    end
    for path, handle in pairs(watchers) do
        if not seen[path] or not fs.is_dir(path) then
            if not handle:is_closing() then
                handle:stop()
                handle:close()
            end
            watchers[path] = nil
        end
    end
end

--- Restart the debounce timer (each event pushes the reload further out).
function M.debounce_start()
    if not debounce or debounce:is_closing() then
        debounce = vim.uv.new_timer()
    end
    debounce:stop()
    debounce:start(
        opts.debounce_ms or 300,
        0,
        vim.schedule_wrap(function()
            local changed = vim.iter(pending)
                :map(function(path)
                    return path
                end)
                :totable()
            pending = {}
            table.sort(changed)
            M.refresh_watchers()
            M.on_change(changed)
        end)
    )
end

--- React to a debounced change set.
--- @param changed string[]
function M.on_change(changed)
    if #changed == 0 or reloading then
        return
    end
    if opts.auto_reload then
        M.reload({ changed = changed })
        return
    end
    local shown = vim.iter(changed)
        :map(function(path)
            return vim.fn.fnamemodify(path, ":~:.:h") .. "/" .. fs.basename(path)
        end)
        :totable()
    notify.once(
        "reload.changed." .. table.concat(changed, ","),
        ("configuration changed: %s -- run :ConfigReload to apply"):format(
            table.concat(shown, ", ")
        ),
        "INFO"
    )
end

--- ---------------------------------------------------------------------------
--- Soft reload
--- ---------------------------------------------------------------------------

--- @return string[] problems
local function teardown_all()
    local problems = {}
    local ok, core = pcall(require, "core")
    if ok and type(core.teardown) == "function" then
        vim.list_extend(problems, core.teardown())
    end
    for _, entry in ipairs(lifecycle.teardown_all()) do
        problems[#problems + 1] = ("%s: %s"):format(entry.name, table.concat(entry.problems, "; "))
    end
    lifecycle.reset_registry()
    return problems
end

--- Module namespaces owned by this configuration.
--- @param name string
--- @return boolean
local function is_our_module(name)
    return name:match("^core%.") ~= nil
        or name:match("^lib%.") ~= nil
        or name == "core"
        or name == "plugins"
        or name:match("^plugins%.") ~= nil
        or name:match("^config%.") ~= nil
end

--- Perform a soft reload.
--- @param o? { changed?: string[] }
--- @return boolean ok
--- @return string[] problems
function M.reload(o)
    o = o or {}
    if reloading then
        return false, { "reload already in progress" }
    end
    if vim.in_fast_event() then
        return false, { "cannot reload from a fast event" }
    end

    reloading = true
    local started = vim.uv.hrtime()
    local problems = {}
    local saved_opts = vim.g.core_user_opts
    local init_path = fs.config_path("init.lua")

    pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "ConfigReloadPre" })

    M.stop_watcher()
    vim.list_extend(problems, teardown_all())

    for name in pairs(package.loaded) do
        if is_our_module(name) then
            package.loaded[name] = nil
        end
    end

    local ok, err = pcall(function()
        local chunk, load_err = loadfile(init_path)
        if not chunk then
            error(load_err, 0)
        end
        chunk()
    end)
    if not ok then
        problems[#problems + 1] = ("init.lua: %s"):format(tostring(err))
        local ok_fallback, fallback_err = pcall(function()
            return require("core").setup(saved_opts or {})
        end)
        if not ok_fallback then
            problems[#problems + 1] = ("core.setup fallback: %s"):format(tostring(fallback_err))
        end
    end

    local ok_core, core = pcall(require, "core")
    if ok_core and type(core.errors) == "table" then
        for _, entry in ipairs(core.errors) do
            problems[#problems + 1] = ("%s: %s"):format(entry.module, entry.error)
        end
    end

    local elapsed = (vim.uv.hrtime() - started) / 1e6
    last_reload = {
        time = os.time(),
        problems = problems,
        changed = o.changed or {},
        elapsed_ms = elapsed,
    }

    pcall(vim.api.nvim_exec_autocmds, "User", { pattern = "ConfigReload" })

    reloading = false

    if #problems == 0 then
        notify.info(
            ("configuration reloaded in %.0f ms%s"):format(
                elapsed,
                #(o.changed or {}) > 0 and (" (%d changed file(s))"):format(#(o.changed or {}))
                    or ""
            )
        )
    else
        notify.error(
            ("configuration reloaded with %d problem(s): %s"):format(
                #problems,
                table.concat(problems, " | ")
            )
        )
    end
    return #problems == 0, problems
end

--- ---------------------------------------------------------------------------
--- Commands / status
--- ---------------------------------------------------------------------------

--- `:ConfigReload`
function M.cmd_reload()
    M.reload({ changed = { "user request" } })
end

--- `:ConfigWatch [on|off|status]`
--- @param args vim.api.keyset.create_user_command.command_args
function M.cmd_watch(args)
    local action = (args.fargs and args.fargs[1]) or "status"
    if action == "on" then
        enabled = true
        M.start_watcher()
        notify.info(("config watcher enabled (%d directories)"):format(vim.tbl_count(watchers)))
        return
    end
    if action == "off" then
        enabled = false
        M.stop_watcher()
        notify.info("config watcher disabled")
        return
    end
    if action == "status" then
        report.open({
            title = "Config watcher",
            name = "core://config-watch",
            lines = function()
                return M.report_lines()
            end,
        })
        return
    end
    notify.error((":ConfigWatch: expected on|off|status, got %q"):format(action))
end

--- @return table
function M.watch_state()
    return {
        enabled = enabled,
        watched = vim.tbl_count(watchers),
        events_seen = events_seen,
        last_event = last_event,
        pending = vim.tbl_count(pending),
        auto_reload = opts.auto_reload == true,
        auto_restart = defaults.get("reload.auto_restart", false),
        reloading = reloading,
    }
end

--- @return string[]
function M.report_lines()
    local state = M.watch_state()
    local lines = {
        ("watcher            %s"):format(state.enabled and "enabled" or "disabled"),
        ("directories        %d"):format(state.watched),
        ("events seen        %d"):format(state.events_seen),
        ("last event         %s"):format(
            state.last_event
                    and ("%s at %s"):format(
                        vim.fn.fnamemodify(state.last_event.path, ":~:."),
                        os.date("%H:%M:%S", state.last_event.time)
                    )
                or "none"
        ),
        ("debounce           %s ms"):format(tostring(opts.debounce_ms)),
        ("auto_reload        %s"):format(tostring(state.auto_reload)),
        ("auto_restart       %s"):format(tostring(state.auto_restart)),
        ("reloading          %s"):format(tostring(state.reloading)),
        "",
    }
    if last_reload then
        lines[#lines + 1] = ("last reload        %s (%.0f ms, %d problem(s))"):format(
            os.date("%Y-%m-%d %H:%M:%S", last_reload.time),
            last_reload.elapsed_ms or 0,
            #last_reload.problems
        )
        for _, problem in ipairs(last_reload.problems) do
            lines[#lines + 1] = ("  ! " .. problem)
        end
    else
        lines[#lines + 1] = "last reload        never"
    end
    lines[#lines + 1] = ""
    vim.list_extend(
        lines,
        vim.iter(watchers)
            :map(function(path)
                return ("  watching %s"):format(vim.fn.fnamemodify(path, ":~:."))
            end)
            :totable()
    )
    table.sort(lines, function(a, b)
        return (a:sub(1, 2) == "  ") and (b:sub(1, 2) ~= "  ") or (a < b)
    end)
    return lines
end

--- ---------------------------------------------------------------------------
--- Setup / teardown
--- ---------------------------------------------------------------------------

--- @param o? table
function M.setup(o)
    opts = o or defaults.get("reload", {})
    enabled = opts.watch ~= false
    if enabled then
        M.start_watcher()
    end
    local lc = lifecycle.new({ name = "core.reload" })
    lc:autocmd("VimLeavePre", {
        group_name = "reload_teardown",
        desc = "core: stop the config watcher",
        callback = function()
            M.stop_watcher()
        end,
    })
    lc:activate()
end

--- Stop watching (called from the module teardown order).
function M.teardown()
    M.stop_watcher()
end

return M
