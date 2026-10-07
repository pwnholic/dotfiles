--- blink.indent (saghen): indent guides with scope, computed in Lua.
---
--- No dependency and no build step (the parser ships in Lua), and `setup()` is
--- optional -- the plugin initialises itself with defaults. Visibility is owned by
--- the plugin: `vim.b.indent_guide = false` per buffer, `vim.g.indent_guide = false`
--- globally, or `require('blink.indent').enable(bool)` / `is_enabled()`.

local defaults = require("core.defaults")
local notify = require("core.notify")
local pack = require("core.pack")

local M = {}

function M.setup()
    if defaults.get("blink_indent.enabled", true) == false then
        return
    end
    local ok, err = pack.register({
        src = "https://github.com/Saghen/blink.indent",
        name = "blink.indent",
        --- `main` (see `blink_pairs.lua`).
        lazy = false,
        reloadable = true,
        config = M.configure,
    })
    if not ok then
        notify.warn("plugins.blink_indent: " .. tostring(err))
    end
end

function M.configure()
    local ok, indent = pcall(require, "blink.indent")
    if not ok then
        notify.error("blink.indent could not be loaded: " .. tostring(indent))
        return
    end
    local o = defaults.get("blink_indent", {})
    local char = o.char or "▏"
    indent.setup({
        static = {
            enabled = o.static ~= false,
            char = char,
        },
        scope = {
            enabled = o.scope ~= false,
            char = char,
            underline = { enabled = o.underline == true },
        },
    })
end

return M
