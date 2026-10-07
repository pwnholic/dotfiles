--- Native `vim.pack()` orchestration.
---
--- Thin layer over `vim.pack`, not a plugin manager clone. What it adds:
---
---   * declarative, validated specs (triggers, deps, hooks),
---   * lazy loading driven by `cmd` / `keys` / `ft` / `event` stubs,
---   * dependency ordering,
---   * throttled update *checking* (never silent state changes),
---   * batched user feedback through `core.notify`.
---
--- Loading model (documented, predictable):
---
---   eager (`lazy = false`)  -> installed + loaded on `VimEnter`
---   trigger                 -> installed + loaded when the trigger fires
---   `VeryLazy`              -> fires right after `VimEnter`
---   explicit                -> `require('core.pack').load(id)` / `:PackInstall`
---
--- A plugin is added with `vim.pack.add(specs, { load = false })` (registers
--- 'runtimepath' only) and then sourced with `:packadd`, which is exactly the
--- native two-step behaviour verified for Neovim 0.12.
---
--- @class core.pack
local M = {}

local Registry = require("lib.registry")
local defaults = require("core.defaults")
local fs = require("lib.fs")
local json = require("lib.json")
local lifecycle = require("lib.lifecycle")
local notify = require("core.notify")
local process = require("lib.process")

local pack_update = require("core.pack.update")
local triggers = require("core.pack.triggers")

--- @type lib.Registry plugin specs
local registry = Registry.new({ name = "plugins" })
--- @type lib.Registry PackChanged hooks (`{ id, plugin?, kinds?, fn }`)
local hooks = Registry.new({ name = "pack.hooks" })
--- @type lib.Lifecycle
--- @type lib.Lifecycle?
local lc
--- @type table
local opts = {}

--- ---------------------------------------------------------------------------
--- Declared-but-loaded state (survives :ConfigReload on purpose)
---
--- `plugin/` scripts can be sourced only once; the flags therefore live in
--- `vim.g` so a soft reload cannot double-source or double-configure a plugin.
--- ---------------------------------------------------------------------------

--- Read a persistent flag table. `vim.g[key]` returns a *converted copy*, not a
--- live reference, so every mutation must be written back through `flag_set()`.
--- @param key string
--- @return table<string, boolean>
local function flag_table(key)
    local t = vim.g[key]
    return type(t) == "table" and t or {}
end

--- Set (or clear) one persistent flag and write the table back.
--- @param key string
--- @param field string
--- @param value boolean|nil
local function flag_set(key, field, value)
    local t = flag_table(key)
    t[field] = value
    vim.g[key] = t
end

--- Has the plugin's `plugin/` scripts been sourced (or the spec loaded)?
--- @param id string
--- @return boolean
function M.is_loaded(id)
    return flag_table("core_pack_loaded")[id] == true
end

--- @param id string
--- @return boolean
function M.is_configured(id)
    return flag_table("core_pack_configured")[id] == true
end

--- @return string[]
function M.loaded_ids()
    local ids = vim.iter(flag_table("core_pack_loaded"))
        :map(function(id)
            return id
        end)
        :totable()
    table.sort(ids)
    return ids
end

--- ---------------------------------------------------------------------------
--- Declaration
--- ---------------------------------------------------------------------------

--- Normalize + validate a spec.
--- @param spec table
--- @return table|nil normalized
--- @return string|nil err
local function normalize(spec)
    if type(spec) == "string" then
        spec = { src = spec }
    end
    if type(spec) ~= "table" then
        return nil, ("plugin spec must be a table or string, got %s"):format(type(spec))
    end
    local src = spec.src
    if type(src) ~= "string" or src == "" then
        return nil, "plugin spec needs a non-empty `src`"
    end
    local def = vim.deepcopy(spec)
    def.id = def.id or def.name or src:gsub("%.git$", ""):gsub("/+$", ""):match("([^/]+)$")
    if type(def.id) ~= "string" or def.id == "" then
        return nil, ("cannot derive a plugin name from %q; set `name`"):format(src)
    end
    def.name = def.id

    if def.version ~= nil and type(def.version) ~= "string" and type(def.version) ~= "table" then
        return nil, ("plugin %q: `version` must be a string or vim.version.range()"):format(def.id)
    end
    if def.init ~= nil and type(def.init) ~= "function" then
        return nil, ("plugin %q: `init` must be a function"):format(def.id)
    end
    if def.config ~= nil and type(def.config) ~= "function" then
        return nil, ("plugin %q: `config` must be a function"):format(def.id)
    end
    if def.keys ~= nil and type(def.keys) ~= "string" and type(def.keys) ~= "table" then
        return nil, ("plugin %q: `keys` must be a string or a list"):format(def.id)
    end
    for _, trigger in ipairs({ "cmd", "ft", "event" }) do
        local value = def[trigger]
        if value ~= nil and type(value) ~= "string" and type(value) ~= "table" then
            return nil, ("plugin %q: `%s` must be a string or a list"):format(def.id, trigger)
        end
    end
    -- Entries are names or inline specs; `resolve_chain()` handles both.
    def.deps = def.deps or {}

    def.lazy = def.lazy ~= nil and def.lazy
        or (def.cmd ~= nil or def.keys ~= nil or def.ft ~= nil or def.event ~= nil)
    def.enabled = def.enabled ~= false
    return def
end

--- Declare a plugin.
--- @param spec table
--- @return boolean ok
--- @return string? err
function M.register(spec)
    local def, err = normalize(spec)
    if not def then
        return false, err
    end
    local ok, reg_err = registry:register(def, { replace = true })
    if not ok then
        return false, reg_err
    end
    -- A spec declared for a plugin that is already loaded but not yet
    -- configured (the common case after `:ConfigReload`) is configured right
    -- away, so declaration order relative to `core.pack.setup()` is irrelevant.
    if def.enabled and M.is_loaded(def.id) and not M.is_configured(def.id) then
        M.load(def.id)
    end
    return true
end

--- @param specs table[]
--- @return string[] problems
function M.register_all(specs)
    local problems = {}
    for _, spec in ipairs(specs or {}) do
        local ok, err = M.register(spec)
        if not ok then
            problems[#problems + 1] = tostring(err)
        end
    end
    return problems
end

--- @param id string
--- @return table|nil
function M.get(id)
    return registry:get(id)
end

--- @param id string
--- @return boolean
function M.is_declared(id)
    return registry:has(id)
end

--- @return table[]
function M.list()
    return registry:list()
end

--- @return string[]
function M.ids()
    return registry:ids()
end

--- Register a `PackChanged` hook.
--- @param spec { id: string, plugin?: string, kinds?: string[], fn: fun(ev: table) }
--- @return boolean ok
--- @return string? err
function M.register_hook(spec)
    if type(spec) ~= "table" or type(spec.fn) ~= "function" then
        return false, "hook needs { id, fn }"
    end
    return hooks:register(spec, { replace = true })
end

--- ---------------------------------------------------------------------------
--- Dependency ordering
--- ---------------------------------------------------------------------------

--- Resolve specs plus their declared dependencies in load order.
--- @param id string
--- @return table[] ordered specs
--- @return string|nil err
function M.resolve_chain(id)
    local order = {}
    local state = {}

    local function visit(current)
        if state[current] == "done" then
            return true
        end
        if state[current] == "visiting" then
            return false, ("dependency cycle through %q"):format(current)
        end
        local spec = registry:get(current)
        if not spec then
            return false, ("unknown plugin %q"):format(current)
        end
        state[current] = "visiting"
        for _, dep in ipairs(spec.deps or {}) do
            if type(dep) == "string" then
                local ok, err = visit(dep)
                if not ok then
                    return false, err
                end
            else
                local def, err = normalize(dep)
                if not def then
                    return false, err
                end
                if not registry:has(def.id) then
                    registry:register(def)
                end
                local ok, dep_err = visit(def.id)
                if not ok then
                    return false, dep_err
                end
            end
        end
        state[current] = "done"
        order[#order + 1] = spec
        return true
    end

    local ok, err = visit(id)
    if not ok then
        return {}, err
    end
    return order
end

--- ---------------------------------------------------------------------------
--- Loading
--- ---------------------------------------------------------------------------

--- @type table<string, boolean> recursion guard during load
local loading = {}

--- Is a plugin present in the vim.pack directory?
--- (`site/pack/core/opt` of the "data" standard path -- see `:help vim.pack-directory`.)
--- @param name string
--- @return boolean
local function on_disk(name)
    return fs.is_dir(fs.data_path("site", "pack", "core", "opt", name))
end

--- Public form of `on_disk()`: "installed" (on disk) is not "loaded".
--- @param id string
--- @return boolean
function M.is_installed(id)
    return on_disk(id)
end

--- @param specs table[]
--- @return boolean ok
--- @return string|nil err
local function ensure_on_disk(specs)
    if not process.have("git") then
        return false, "git is required by vim.pack but was not found in PATH"
    end

    -- A headless session must never download plugins: no silent network
    -- activity, and install prompts cannot be answered.
    if #vim.api.nvim_list_uis() == 0 then
        local missing = vim.iter(specs)
            :map(function(spec)
                if on_disk(spec.id) then
                    return nil
                end
                return spec.id
            end)
            :totable()
        if #missing > 0 then
            return false,
                ("headless session: refusing to install %s (run :PackInstall in an interactive Neovim)"):format(
                    table.concat(missing, ", ")
                )
        end
    end

    local list = {}
    for _, spec in ipairs(specs) do
        list[#list + 1] = {
            src = spec.src,
            name = spec.id,
            version = spec.version,
            data = spec.data,
        }
    end
    local ok, err = pcall(vim.pack.add, list, { load = false, confirm = opts.confirm_install })
    if not ok then
        return false, notify.error_text(err)
    end
    return true, nil
end

--- Install (when missing) and load a plugin, then run its `init`/`config`.
--- Safe to call repeatedly; already-loaded plugins are not re-sourced.
--- @param id string
--- @return boolean ok
--- @return string|nil err
function M.load(id)
    local spec = registry:get(id)
    if not spec then
        return false, ("unknown plugin %q"):format(id)
    end
    if not spec.enabled then
        return false, ("plugin %q is disabled"):format(id)
    end
    if loading[id] then
        return true, nil
    end

    local chain, err = M.resolve_chain(id)
    if not chain or #chain == 0 then
        return false, err or ("cannot resolve %q"):format(id)
    end

    loading[id] = true
    local ok, load_err = pcall(function()
        local need_add = vim.iter(chain)
            :filter(function(dep)
                return not M.is_loaded(dep.id)
            end)
            :totable()

        local added, add_err = ensure_on_disk(need_add)
        if not added then
            error(add_err, 0)
        end

        for _, dep in ipairs(chain) do
            local already_loaded = M.is_loaded(dep.id)
            local needs_config = not M.is_configured(dep.id)
            -- `plugin/` files were already sourced in this Neovim process and the
            -- plugin's configuration is current -> nothing to do (reload-safe).
            if not (already_loaded and not (dep.reloadable and needs_config)) then
                -- Placeholders are dropped *before* `plugin/` files are sourced:
                -- the plugin (or its `init` hook) may define a command/mapping
                -- with exactly those names, and those have to survive.
                triggers.remove(dep.id)

                if not already_loaded then
                    if dep.init then
                        dep.init()
                    end
                    local ok_add, err_add =
                        pcall(vim.cmd.packadd, { dep.id, bang = false, magic = { file = false } })
                    if not ok_add then
                        error(("cannot load %q: %s"):format(dep.id, tostring(err_add)), 0)
                    end
                    flag_set("core_pack_loaded", dep.id, true)
                end

                if dep.config and needs_config then
                    local ok_cfg, err_cfg = pcall(dep.config)
                    if not ok_cfg then
                        error(("config for %q failed: %s"):format(dep.id, tostring(err_cfg)), 0)
                    end
                    flag_set("core_pack_configured", dep.id, true)
                end
                notify.debug(
                    ("%s plugin %s"):format(already_loaded and "reconfigured" or "loaded", dep.id)
                )
            end
        end
    end)
    loading[id] = nil

    if not ok then
        local message = tostring(load_err)
        notify.error(("plugin %s: %s"):format(id, message))
        return false, message
    end

    return true, nil
end

--- Install declared plugins without loading them (`:PackInstall`).
--- @param ids string[]
--- @return boolean ok
--- @return string|nil err
function M.install(ids)
    local specs = {}
    for _, id in ipairs(ids) do
        local spec = registry:get(id)
        if not spec then
            return false,
                ("unknown plugin %q (declared: %s)"):format(id, table.concat(M.ids(), ", "))
        end
        local chain, err = M.resolve_chain(id)
        if not chain then
            return false, err
        end
        vim.list_extend(
            specs,
            vim.iter(chain)
                :filter(function(dep)
                    return not M.is_loaded(dep.id)
                end)
                :totable()
        )
    end
    if #specs == 0 then
        return true, nil
    end
    return ensure_on_disk(specs)
end

--- `:PackInstall [names...]`
--- @param args vim.api.keyset.create_user_command.command_args
function M.cmd_install(args)
    local names = args.fargs and #args.fargs > 0 and args.fargs or M.ids()
    if #names == 0 then
        notify.warn("no plugins are declared (see lua/plugins/)")
        return
    end
    local ok, err = M.install(names)
    if not ok then
        notify.error(("install failed: %s"):format(tostring(err)))
        return
    end
    notify.info(
        ("installed/verified %d plugin(s); they load when their trigger fires"):format(#names)
    )
end

--- ---------------------------------------------------------------------------
--- PackChanged handling
--- ---------------------------------------------------------------------------

--- @type table<string, true>
local updated = {}
--- @type uv_timer_t|nil
local update_timer

local function flush_updates()
    local names = vim.iter(updated)
        :map(function(name)
            return name
        end)
        :totable()
    updated = {}
    table.sort(names)
    if #names == 0 then
        return
    end
    notify.info(("%d plugin(s) updated: %s"):format(#names, table.concat(names, ", ")))
    if defaults.get("reload.auto_restart", false) then
        notify.info("auto_restart is enabled: restarting Neovim")
        vim.cmd.restart()
    else
        notify.info(
            "run :restart to use the updated plugin code (configuration is not restarted automatically)"
        )
    end
    local state = json.read(fs.state_path("core", "pack-update.json"))
    state.last_result = { updated = names, time = os.time() }
    json.write(fs.state_path("core", "pack-update.json"), state)
end

--- @param ev table `PackChanged` event
local function on_pack_changed(ev)
    local data = ev.data or {}
    local spec = data.spec or {}
    local name = spec.name or "?"
    for _, hook in ipairs(hooks:list()) do
        local kinds = hook.kinds or { "install", "update", "delete" }
        if (not hook.plugin or hook.plugin == name) and vim.tbl_contains(kinds, data.kind) then
            local ok, err = pcall(hook.fn, ev)
            if not ok then
                notify.error(("pack hook %s failed: %s"):format(hook.id, notify.error_text(err)))
            end
        end
    end

    if data.kind == "install" then
        notify.debug(("installed %s"):format(name))
    elseif data.kind == "update" then
        updated[name] = true
        if update_timer and not update_timer:is_closing() then
            update_timer:stop()
        else
            update_timer = vim.uv.new_timer()
        end
        update_timer:start(300, 0, vim.schedule_wrap(flush_updates))
    elseif data.kind == "delete" then
        notify.debug(("deleted %s"):format(name))
    end
end

--- Remove every trigger stub that belongs to `id` (implementation: `triggers.lua`).
--- @param id string
function M.remove_triggers(id)
    triggers.remove(id)
end

--- Install the trigger stubs for every declared spec (implementation: `triggers.lua`).
function M.setup_triggers()
    triggers.setup_triggers()
end

--- ---------------------------------------------------------------------------
--- Update checking and `:Pack*` update commands
--- (implementation: `core/pack/update.lua`)
--- ---------------------------------------------------------------------------

--- @param o? { force?: boolean, notify?: boolean, names?: string[], wait?: boolean }
--- @return boolean ran
--- @return table result
function M.check_updates(o)
    return pack_update.check_updates(o)
end

--- Current update state (as persisted).
--- @return table
function M.update_state()
    return pack_update.state()
end

--- `:PackCheck`
function M.cmd_check()
    pack_update.cmd_check()
end

--- `:PackUpdate [names...]` -- native review workflow.
--- @param args vim.api.keyset.create_user_command.command_args
function M.cmd_update(args)
    pack_update.cmd_update(args)
end

--- @return string[]
function M.report_lines()
    return pack_update.report_lines()
end

--- `:PackStatus`
function M.cmd_status()
    pack_update.cmd_status()
end

--- ---------------------------------------------------------------------------
--- Setup
--- ---------------------------------------------------------------------------

--- @param o? table
function M.setup(o)
    opts = o or defaults.get("pack", {})
    triggers.setup({
        registry = registry,
        is_loaded = function(id)
            return M.is_loaded(id)
        end,
        is_configured = function(id)
            return M.is_configured(id)
        end,
        lifecycle = function()
            -- Triggers are installed after  exists; failing loudly beats a
            -- silent no-op when that order is broken.
            return assert(lc, "pack triggers require an active lifecycle")
        end,
        load = function(id)
            return M.load(id)
        end,
    })
    pack_update.setup({
        options = function()
            return opts.update or {}
        end,
    })
    lc = lifecycle.new({ name = "core.pack" })

    if not process.have("git") then
        notify.error(
            "git was not found in PATH: vim.pack cannot manage plugins (see :checkhealth config)"
        )
        lc:activate()
        return
    end

    -- Hooks must exist before the first `vim.pack` call, otherwise installs from
    -- the lockfile would not run their hooks.
    lc:autocmd("PackChanged", {
        group_name = "pack_hooks",
        desc = "core: pack change hooks + update notifications",
        callback = on_pack_changed,
    })

    local problems = M.register_all(opts.plugins or {})
    for _, problem in ipairs(problems) do
        notify.error("core.pack: " .. problem)
    end

    -- Trigger stubs.
    M.setup_triggers()

    -- After `:ConfigReload`, already-loaded plugins whose configuration is
    -- declared `reloadable` get their `config()` re-applied (their `plugin/`
    -- files cannot and must not be sourced twice).
    for _, def in ipairs(registry:list()) do
        if def.enabled and M.is_loaded(def.id) and not M.is_configured(def.id) then
            M.load(def.id)
        end
    end

    -- Eager plugins load at VimEnter: the UI exists (install prompts can be
    -- answered) and lazy triggers are already registered.
    lc:autocmd("VimEnter", {
        group_name = "pack_eager",
        once = true,
        desc = "core: load eager plugins",
        callback = function()
            for _, def in ipairs(registry:list()) do
                if def.enabled and not def.lazy and not M.is_loaded(def.id) then
                    M.load(def.id)
                end
            end
        end,
    })

    -- Throttled background update check (advisory, no state change).
    if (opts.update or {}).auto_check ~= false then
        lc:autocmd("User", {
            pattern = "VeryLazy",
            group_name = "pack_update_check",
            once = true,
            desc = "core: throttled plugin update check",
            callback = function()
                lc:timer({
                    timeout = (opts.update or {}).startup_delay_ms or 2000,
                    callback = function()
                        if #vim.api.nvim_list_uis() == 0 then
                            return
                        end
                        local ran, result = M.check_updates({
                            notify = (opts.update or {}).notify ~= false,
                            wait = false,
                        })
                        if ran and result.throttled then
                            notify.debug("plugin update check throttled")
                        end
                    end,
                })
            end,
        })
    end

    lc:activate()
end

function M.teardown()
    if update_timer and not update_timer:is_closing() then
        update_timer:stop()
        update_timer:close()
    end
    update_timer = nil
    triggers.reset()

    -- `config()` of reloadable plugins is re-applied on reload: forget that it
    -- ran so the next `M.setup()` runs it again exactly once.
    for _, def in ipairs(registry:list()) do
        if def.reloadable then
            flag_set("core_pack_configured", def.id, nil)
        end
    end

    if lc then
        lc:teardown()
        lc = nil
    end
end

--- @return table
function M.inspect()
    return {
        declared = registry:ids(),
        loaded = M.loaded_ids(),
        update_state = pack_update.state(),
    }
end

return M
