--- Plugin layer.
---
--- Plugin modules own *plugin-specific* configuration only: they declare specs
--- through `core.pack` and register plugin-provided extensions (toggles,
--- formatters, LSP hints) through the `core.*` registries. Nothing here
--- implements infrastructure.
---
--- A module's `setup()` must be side-effect free with respect to loading:
--- it only *declares*. Actual loading happens through `core.pack` triggers.
---
--- @class plugins
local M = {}

--- Declaration order. Add a module here (and to `lua/plugins/`) to extend the
--- configuration; nothing in `core/` needs to change.
---
--- `plugins.mini_statusline` / `plugins.mini_statuscolumn` are deliberately not
--- listed: they configure modules of the *same* repository as `mini.nvim`, so
--- they are applied from that spec's `config` hook (see `plugins/mini.lua`).
local ORDER = {
    -- The theme first: it must be applied before the other modules render.
    "tokyonight",
    "mini",
    "blink_indent",
    "blink_pairs",
    "fzf_lua",
    -- `blink_cmp` before `lsp`: the LSP module loads it early for capabilities.
    "blink_cmp",
    "conform",
    "oil",
    "treesitter",
    "treesitter_context",
    "lsp",
    "mason",
}

--- Declare every plugin module's specs and extensions.
--- @return string[] problems
function M.setup()
    local problems = {}
    for _, name in ipairs(ORDER) do
        local ok, err = pcall(function()
            local mod = require("plugins." .. name)
            if type(mod.setup) == "function" then
                mod.setup()
            end
        end)
        if not ok then
            problems[#problems + 1] = ("plugins.%s: %s"):format(name, tostring(err))
        end
    end
    for _, problem in ipairs(problems) do
        require("core.notify").error(problem)
    end
    return problems
end

--- Plugin-local teardown (called before core teardown during a reload).
function M.teardown()
    for i = #ORDER, 1, -1 do
        pcall(function()
            local mod = require("plugins." .. ORDER[i])
            if type(mod.teardown) == "function" then
                mod.teardown()
            end
        end)
    end
end

return M
