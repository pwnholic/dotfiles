--- tokyonight (folke): the colorscheme of this configuration.
---
--- The spec is *eager* on purpose. `core.setup()` tries to apply
--- `options.colorscheme` before plugins are on the runtimepath, so the first
--- attempt cannot succeed while this plugin is unloaded; it is therefore applied
--- here, when the plugin actually loads. `theme.style` is the single knob and the
--- plugin records the resulting colorscheme name, so `:checkhealth config` and the
--- tests compare against one source of truth.

local defaults = require("core.defaults")
local notify = require("core.notify")
local pack = require("core.pack")

local M = {}

--- Colorscheme name for the configured variant.
--- @return string
function M.scheme()
    return ("tokyonight-%s"):format(defaults.get("theme.style", "night"))
end

function M.setup()
    if defaults.get("theme.enabled", true) == false then
        return
    end
    local ok, err = pack.register({
        src = "https://github.com/folke/tokyonight.nvim",
        name = "tokyonight.nvim",
        --- A theme has to exist before the first redraw.
        lazy = false,
        reloadable = true,
        config = M.configure,
    })
    if not ok then
        notify.warn("plugins.tokyonight: " .. tostring(err))
    end
end

function M.configure()
    local loaded, tokyonight = pcall(require, "tokyonight")
    if not loaded then
        notify.error("tokyonight.nvim could not be loaded: " .. tostring(tokyonight))
        return
    end
    tokyonight.setup({ style = defaults.get("theme.style", "night") })

    local scheme = M.scheme()
    -- Single source of truth: the applied scheme is what the rest of the config
    -- (health, tests, users) reads from `options.colorscheme`.
    defaults.values.options.colorscheme = scheme
    local applied, err = require("core.highlights").apply_colorscheme(scheme)
    if not applied then
        notify.error(("colorscheme %s could not be applied: %s"):format(scheme, tostring(err)))
    end
end

return M
