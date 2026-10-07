--- nvim-treesitter-context: sticky context lines, plus its toggle.
---
--- The "treesitter context" toggle in `core.toggle` gets its implementation
--- here (plugin-provided extension, no core knowledge of this plugin). The
--- plugin exposes real state (`enabled()`), so `get` reads the truth instead of
--- a shadow flag.
---
--- Loaded on `VeryLazy`; unavailable installations degrade to a clear message
--- from the toggle, never an error.
---
--- @class plugins.treesitter_context
local M = {}

local SRC = "https://github.com/nvim-treesitter/nvim-treesitter-context"

function M.setup()
    require("core.pack").register({
        src = SRC,
        name = "nvim-treesitter-context",
        event = { "VeryLazy" },
        reloadable = true,
        config = M.configure,
    })
end

function M.configure()
    local notify = require("core.notify")
    local ok, context = pcall(require, "treesitter-context")
    if not ok then
        notify.error("nvim-treesitter-context could not be loaded: " .. tostring(context))
        return
    end

    context.setup({
        enable = true,
        max_lines = 3,
        multiline_threshold = 20,
        min_window_height = 0,
        trim_scope = "outer",
        mode = "cursor",
    })

    local attached, err = require("core.toggle").attach("treesitter_context", {
        get = function()
            return context.enabled()
        end,
        set = function(value)
            if value then
                context.enable()
            else
                context.disable()
            end
        end,
        available = function()
            return true
        end,
    })
    if not attached then
        notify.error("treesitter_context.lua: cannot attach toggle: " .. tostring(err))
        return
    end

    -- Respect the configured default (runtime state wins afterwards).
    local want = require("core.defaults").get("toggles.defaults.treesitter_context")
    if want ~= nil and context.enabled() ~= want then
        if want then
            context.enable()
        else
            context.disable()
        end
    end
end

function M.teardown()
    local ok, context = pcall(require, "treesitter-context")
    if ok then
        pcall(context.disable)
    end
end

return M
