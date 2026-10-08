--- Plugin update checking and the update-related `:Pack*` commands.
---
--- Split out of `core/pack/init.lua` (which owns the loader): this module *checks* and
--- *applies* updates and never loads plugins. The two things it needs from the
--- loader are injected through `M.setup()`, so no cyclic require is needed: the
--- `pack.update` options and (implicitly) `core.pack` itself, which `report_lines`
--- requires lazily when it renders the plugin table.
---
--- Safety rules carried over: checking never changes plugin state, it is throttled
--- by `interval_days`, and applying updates always goes through Neovim's own review
--- buffer (`:write` applies, `:quit` discards).

local fs = require("lib.fs")
local json = require("lib.json")
local notify = require("core.notify")
local process = require("lib.process")
local report = require("lib.report")

--- @class core.pack.update
--- @field setup fun(o: { options: fun(): table })
--- @field state fun(): table
--- @field check_updates fun(o?: table): boolean, table
--- @field cmd_check fun()
--- @field cmd_update fun(args: table)
--- @field report_lines fun(): string[]
--- @field cmd_status fun()
local M = {}

--- Injected by `core.pack.setup()`.
--- @type { options: fun(): table }
local ctx = {
    options = function()
        return {}
    end,
}

--- @param o { options: fun(): table }
function M.setup(o)
    ctx = o or ctx
end

--- Read the persisted update state (last check + last result).
--- @return table
local function read_state()
    return json.read(fs.state_path("core", "pack-update.json"))
end

--- @param state table
local function write_state(state)
    json.write(fs.state_path("core", "pack-update.json"), state)
end

--- @param path string
--- @param args string[]
--- @return string|nil
local function git(path, args)
    local cmd = vim.list_extend({ "git", "-c", "gc.auto=0", "-C", path }, args)
    local res =
        process.run(cmd, { timeout = ctx.options() and ctx.options().fetch_timeout_ms or 20000 })
    if not res or res.code ~= 0 then
        return nil
    end
    return vim.trim(res.stdout)
end

--- Resolve a ref to the *commit* it points at.
--- Annotated tags resolve to the tag object, while the lockfile records the
--- commit, so every lookup is dereferenced with `^{commit}` (otherwise a plugin
--- pinned to an annotated tag always looks "updatable").
--- @param path string
--- @param ref string
--- @return string|nil rev
local function commit_of(path, ref)
    return git(path, { "rev-parse", "--verify", "--quiet", ref .. "^{commit}" })
end

--- Newest release revision the plugin's `version` resolves to upstream.
--- @param path string
--- @param spec table
--- @return string|nil rev
local function target_rev(path, spec)
    local version = spec.version
    if version == nil then
        return commit_of(path, "origin/HEAD") or commit_of(path, "origin/master")
    end
    if type(version) == "string" then
        return commit_of(path, version) or commit_of(path, "origin/" .. version)
    end
    -- vim.version.range(): pick the newest matching tag.
    local tags = git(path, { "tag", "--sort=-v:refname" })
    if not tags then
        return nil
    end
    for _, tag in ipairs(vim.split(tags, "\n", { plain = true })) do
        local ok, parsed = pcall(vim.version.parse, tag)
        if ok and parsed and version:has(parsed) then
            return commit_of(path, tag)
        end
    end
    return nil
end

--- Check for available updates without changing any plugin state.
--- @param o? { force?: boolean, notify?: boolean, names?: string[], wait?: boolean }
--- @return boolean ran
--- @return table result `{ checked, updates = { { name, current, target } }, errors }`
function M.check_updates(o)
    o = o or {}
    local update_opts = ctx.options() or {}
    local state = read_state()
    local interval = (tonumber(update_opts.interval_days) or 7) * 86400
    if not o.force and state.last_check and (os.time() - state.last_check) < interval then
        return false, { checked = 0, updates = {}, errors = {}, throttled = true }
    end

    local installed = vim.pack.get(o.names, { info = false })
    local result = { checked = 0, updates = {}, errors = {} }
    local pending = 0
    local finished = false

    if #installed == 0 then
        state.last_check = os.time()
        state.last_result = { updates = {} }
        write_state(state)
        return true, result
    end

    local pack = require("core.pack")
    for _, plugin in ipairs(installed) do
        local name = plugin.spec.name
        local spec = pack.get(name)
        if spec and not process.have("git") then
            result.errors[#result.errors + 1] = name .. ": git missing"
        elseif spec then
            pending = pending + 1
            process.run_async({
                "git",
                "-c",
                "gc.auto=0",
                "-C",
                plugin.path,
                "fetch",
                "--quiet",
                "--tags",
                "origin",
            }, {
                timeout = update_opts.fetch_timeout_ms or 20000,
            }, function(res)
                if res.code ~= 0 then
                    result.errors[#result.errors + 1] = ("%s: fetch failed"):format(name)
                else
                    local target = target_rev(plugin.path, spec)
                    if target and target ~= plugin.rev then
                        result.updates[#result.updates + 1] =
                            { name = name, current = plugin.rev, target = target }
                    end
                end
                pending = pending - 1
                if pending == 0 then
                    finished = true
                end
            end)
            result.checked = result.checked + 1
        end
    end

    -- Bounded wait so `:PackCheck` reports something useful; the automatic check
    -- never waits (it notifies from the timer callback instead).
    if o.wait ~= false and not vim.in_fast_event() then
        local deadline = (tonumber(update_opts.fetch_timeout_ms) or 20000) + 2000
        pcall(vim.wait, deadline, function()
            return finished
        end)
    end

    state.last_check = os.time()
    state.last_result = result
    write_state(state)

    if o.notify then
        local report_fn = function()
            if #result.updates == 0 and #result.errors == 0 then
                notify.info("plugin updates: none available")
            elseif #result.updates == 0 then
                notify.warn(
                    ("plugin update check: no updates (%d error(s), see :PackStatus)"):format(
                        #result.errors
                    )
                )
            else
                local names = vim.iter(result.updates)
                    :map(function(u)
                        return u.name
                    end)
                    :totable()
                table.sort(names)
                notify.info(
                    ("plugin updates available (%d): %s -- run :PackUpdate to review"):format(
                        #names,
                        table.concat(names, ", ")
                    )
                )
            end
        end
        if o.wait ~= false then
            report_fn()
        else
            vim.schedule(report_fn)
        end
    end

    return true, result
end

--- Current update state (as persisted).
--- @return table
function M.state()
    return read_state()
end

--- `:PackCheck`
function M.cmd_check()
    local ran, result = M.check_updates({ force = true, notify = true })
    if not ran then
        notify.info("update check skipped")
        return
    end
    if result.throttled then
        notify.info("update check is throttled (run :PackUpdate to update anyway)")
    end
end

--- ---------------------------------------------------------------------------
--- Update / status commands
--- ---------------------------------------------------------------------------

--- `:PackUpdate [names...]` -- native review workflow.
--- @param args vim.api.keyset.create_user_command.command_args
function M.cmd_update(args)
    if not process.have("git") then
        notify.error("vim.pack requires git, which was not found in PATH")
        return
    end
    local names = args.fargs and #args.fargs > 0 and args.fargs or nil
    notify.info(
        "fetching plugin updates (vim.pack); a review buffer will open: :write applies, :quit discards"
    )
    local ok, err = pcall(vim.pack.update, names, {})
    if not ok then
        notify.error(("vim.pack.update() failed: %s"):format(notify.error_text(err)))
        return
    end
    local state = read_state()
    state.last_check = os.time()
    write_state(state)
    notify.info("review the update buffer, then :write (apply) or :quit (discard)")
end

--- @return string[]
function M.report_lines()
    local pack = require("core.pack")
    local state = read_state()
    local lines = {
        ("vim.pack plugins   %d managed"):format(#vim.pack.get({}, { info = false })),
        ("declared specs     %d"):format(#pack.list()),
        ("loaded             %s"):format(
            #pack.loaded_ids() > 0 and table.concat(pack.loaded_ids(), ", ") or "none"
        ),
        ("last update check  %s"):format(
            state.last_check and os.date("%Y-%m-%d %H:%M", state.last_check) or "never"
        ),
        ("auto check         %s (every %s days)"):format(
            tostring(ctx.options().auto_check ~= false),
            tostring(ctx.options().interval_days or 7)
        ),
        "",
        ("%-24s %-9s %-8s %-9s %s"):format("PLUGIN", "LAZY", "LOADED", "TRIGGERS", "VERSION"),
    }
    vim.list_extend(
        lines,
        vim.iter(pack.list())
            :map(function(def)
                local triggers_ = vim.iter({ "cmd", "keys", "ft", "event" })
                    :filter(function(key)
                        return def[key] ~= nil
                    end)
                    :totable()
                return ("%-24s %-9s %-8s %-9s %s"):format(
                    def.id,
                    def.lazy and "lazy" or "eager",
                    pack.is_loaded(def.id) and "yes" or "no",
                    #triggers_ > 0 and table.concat(triggers_, ",") or "-",
                    def.version ~= nil and tostring(def.version) or "default branch"
                )
            end)
            :totable()
    )
    local last = state.last_result or {}
    if last.updates and #last.updates > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "updates seen at last check:"
        for _, update in ipairs(last.updates) do
            lines[#lines + 1] = ("  %-24s %s -> %s"):format(
                update.name,
                update.current:sub(1, 8),
                update.target:sub(1, 8)
            )
        end
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Commands: :PackInstall [names] | :PackUpdate | :PackCheck"
    return lines
end

--- `:PackStatus`
function M.cmd_status()
    report.open({
        title = "Plugins (vim.pack)",
        name = "core://pack",
        lines = function()
            return M.report_lines()
        end,
    })
end

return M
