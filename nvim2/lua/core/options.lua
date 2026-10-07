--- Data-driven editor options.
---
--- `vim.opt` semantics are used (`:set`), so window/buffer-local options get a
--- global default *and* the current window/buffer value, and the toggles in
--- `core.toggle` can still flip them per window/buffer afterwards.
---
--- Options are idempotent: re-applying them on reload is safe, so there is no
--- teardown that could leave Neovim in a half-restored state.
---
--- @class core.options
local M = {}

local defaults = require("core.defaults")
local notify = require("core.notify")

--- Apply a table of options.
--- @param opts table<string, any>
--- @return string[] problems
function M.apply(opts)
    local problems = {}
    for name, value in pairs(opts or {}) do
        local ok, err = pcall(function()
            vim.opt[name] = value
        end)
        if not ok then
            problems[#problems + 1] = ("option %s: %s"):format(name, tostring(err))
        end
    end
    return problems
end

--- Setup: apply `defaults.options` plus the `shortmess` additions.
--- @param opts? table overrides for `defaults.options`
function M.setup(opts)
    opts = opts or defaults.get("options", {})
    local problems = M.apply(opts)

    local extra = defaults.get("shortmess_extra")
    if extra and extra ~= "" then
        local ok, err = pcall(function()
            vim.opt.shortmess:append(extra)
        end)
        if not ok then
            problems[#problems + 1] = ("shortmess: %s"):format(tostring(err))
        end
    end

    if #problems > 0 then
        -- One short line (a long message would trigger the hit-enter prompt at
        -- startup) *and* a raised error: `core.init` records it in `core.errors`,
        -- where the test suite and health can see it instead of it hiding behind a
        -- stray notification.
        notify.error(
            ("core.options: %d option(s) rejected: %s"):format(
                #problems,
                table.concat(problems, " | ")
            )
        )
        error(("options rejected: %s"):format(table.concat(problems, "; ")), 0)
    end
    return problems
end

return M
