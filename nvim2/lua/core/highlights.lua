--- Declarative highlight management.
---
--- Two kinds of entries:
---   `default`  -- applied only when the group is not already defined
---                 (`nvim_set_hl(..., { default = true })`)
---   `override` -- applied verbatim, always winning
---
--- Both are re-applied on `ColorScheme`, so a colorscheme change cannot lose
--- them. Plugins and user configuration extend the tables through
--- `M.define()` instead of touching Neovim directly.
---
--- @class core.highlights
local M = {}

local defaults = require("core.defaults")
local lifecycle = require("lib.lifecycle")

--- @type lib.Lifecycle
--- @type lib.Lifecycle?
local lc
--- @type table<string, table> default specs (group -> spec)
local default_groups = {}
--- @type table<string, table> override specs
local override_groups = {}

--- Register highlight groups.
--- @param groups table<string, table> `vim.api.nvim_set_hl` specs
--- @param opts? { kind?: 'default'|'override' }
function M.define(groups, opts)
    local kind = (opts or {}).kind or "override"
    local target = kind == "default" and default_groups or override_groups
    for name, spec in pairs(groups or {}) do
        target[name] = spec
    end
    M.apply()
end

--- Apply all managed groups now.
function M.apply()
    for name, spec in pairs(default_groups) do
        local ok, err =
            pcall(vim.api.nvim_set_hl, 0, name, vim.tbl_extend("force", { default = true }, spec))
        if not ok then
            require("core.notify").warn(("highlight %s: %s"):format(name, err))
        end
    end
    for name, spec in pairs(override_groups) do
        local ok, err = pcall(vim.api.nvim_set_hl, 0, name, spec)
        if not ok then
            require("core.notify").warn(("highlight %s: %s"):format(name, err))
        end
    end
end

--- Setup: load the configured groups and re-apply them on ColorScheme.
--- @param opts? { default?: table, override?: table }
function M.setup(opts)
    opts = opts or defaults.get("highlights", {})
    default_groups = vim.tbl_extend("force", {}, opts.default or {})
    override_groups = vim.tbl_extend("force", {}, opts.override or {})

    lc = lifecycle.new({ name = "core.highlights" })
    lc:autocmd("ColorScheme", {
        desc = "core: reapply managed highlights",
        callback = M.apply,
    })
    lc:autocmd("VimEnter", {
        once = true,
        desc = "core: apply managed highlights after colorscheme setup",
        callback = M.apply,
    })
    lc:activate()
end

--- Teardown managed groups' ownership (groups themselves stay defined; a
--- reload re-registers them). Called by the reload subsystem.
function M.teardown()
    if lc then
        lc:teardown()
        lc = nil
    end
end

--- Apply the configured colorscheme (falls back with a clear message).
--- @param name string
function M.apply_colorscheme(name)
    local ok, err = pcall(vim.cmd.colorscheme, name)
    if not ok then
        -- A scheme can be provided by a plugin that is not loaded yet (eager
        -- plugins load on `VimEnter`, after this early attempt), so a failure here
        -- is not an error: the current scheme stays and the plugin applies its own
        -- scheme when it loads. `:checkhealth config` reports a real mismatch.
        require("core.notify").debug(
            ("colorscheme %q not available yet (%s); keeping %s"):format(
                name,
                err,
                tostring(vim.g.colors_name or "the default")
            )
        )
        return false, err
    end
    return true, nil
end

return M
