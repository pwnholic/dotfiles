--- Core bootstrap: ordered setup, error collection, reload-safe teardown.
---
--- Setup order is explicit and intentional:
---
---   notify -> options -> highlights -> autocmds -> tools -> keymaps -> commands
---   -> root -> toggle -> terminal -> format -> lsp
---   -> plugins (declarations + plugin extensions)
---   -> pack (turns declarations into native vim.pack loads + triggers)
---   -> reload (watcher, last so a partially initialized config is not watched)
---
--- Every module setup is error-isolated: one failing subsystem is recorded in
--- `core.errors`, reported through the notifier, and reported by
--- `:checkhealth config` instead of aborting the whole startup.
---
--- @class core
local M = {}

--- Setup order. `section` is the key of `defaults.values` passed to the module.
--- @type table[]
local SETUP_ORDER = {
    { mod = "core.notify", section = "notify", required = true },
    { mod = "core.options", section = "options" },
    { mod = "core.highlights", section = "highlights" },
    { mod = "core.autocmds", section = "autocmds" },
    { mod = "core.tools", section = nil },
    { mod = "core.keymaps", section = "keymaps" },
    { mod = "core.commands", section = nil },
    { mod = "core.root", section = "root" },
    { mod = "core.toggle", section = nil },
    { mod = "core.terminal", section = "terminal" },
    { mod = "core.format", section = "format" },
    { mod = "core.lsp", section = "lsp" },
    { mod = "plugins", section = nil },
    { mod = "core.pack", section = "pack" },
    { mod = "core.reload", section = "reload" },
}

--- @type { module: string, error: string }[]
M.errors = {}

--- @type table
M.state = {
    setup_count = 0,
    last_setup = nil,
    reloads = 0,
}

--- Set up (or re-set up) the whole configuration.
--- @param overrides? table user overrides (see `core.defaults` for precedence)
--- @return core
function M.setup(overrides)
    overrides = overrides or {}
    M.errors = {}
    M.state.setup_count = M.state.setup_count + 1
    M.state.last_setup = os.time()
    -- Generation counter that survives `:ConfigReload` (the core module itself is
    -- re-required, so its own counters restart): 1 = first start, then +1 per reload.
    vim.g.core_generation = (tonumber(vim.g.core_generation) or 0) + 1
    -- Kept for the `:ConfigReload` fallback path when `init.lua` cannot be sourced.
    vim.g.core_user_opts = overrides

    local defaults = require("core.defaults")
    local values = defaults.setup(overrides)

    -- Leader keys must exist before any mapping is created.
    vim.g.mapleader = values.leader
    vim.g.maplocalleader = values.localleader

    local function fail(module, err)
        M.errors[#M.errors + 1] = { module = module, error = tostring(err) }
        pcall(function()
            require("core.notify").error(("%s setup failed: %s"):format(module, tostring(err)))
        end)
    end

    for _, entry in ipairs(SETUP_ORDER) do
        local ok, err = pcall(function()
            local mod = require(entry.mod)
            if type(mod.setup) ~= "function" then
                error(("%s has no setup()"):format(entry.mod), 0)
            end
            if entry.section then
                mod.setup(values[entry.section])
            else
                mod.setup()
            end
        end)
        if not ok then
            fail(entry.mod, err)
        end
    end

    -- Colorscheme last: plugins registered their highlight groups by now and a
    -- missing scheme is reported rather than fatal.
    local ok_scheme, scheme_err = pcall(function()
        require("core.highlights").apply_colorscheme(values.colorscheme)
    end)
    if not ok_scheme then
        fail("colorscheme", scheme_err)
    end

    return M
end

--- Tear down every subsystem in reverse setup order, then sweep anything left
--- registered through `lib.lifecycle`.
--- @return string[] problems
function M.teardown()
    local problems = {}
    for i = #SETUP_ORDER, 1, -1 do
        local entry = SETUP_ORDER[i]
        local ok, mod = pcall(require, entry.mod)
        if ok and type(mod.teardown) == "function" then
            local ok_td, err = pcall(mod.teardown)
            if not ok_td then
                problems[#problems + 1] = ("%s.teardown: %s"):format(entry.mod, tostring(err))
            end
        end
    end
    local lifecycle = require("lib.lifecycle")
    for _, entry in ipairs(lifecycle.teardown_all()) do
        problems[#problems + 1] = ("%s: %s"):format(entry.name, table.concat(entry.problems, "; "))
    end
    lifecycle.reset_registry()
    return problems
end

return M
