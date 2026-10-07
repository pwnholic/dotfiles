--- Central keymap ownership.
---
--- Mappings that are not inherently plugin-specific are declared here (or in
--- `defaults`) so there is one place to inspect and change them. Everything is
--- created through `lib.lifecycle`, which makes teardown exact and prevents
--- duplicates after `:ConfigReload`.
---
--- Plugin modules may still create their own buffer-local mappings; global
--- mappings belong to this module.
---
--- @class core.keymaps
local M = {}

local defaults = require("core.defaults")
local lifecycle = require("lib.lifecycle")

--- @type lib.Lifecycle
--- @type lib.Lifecycle?
local lc
--- Declarative keymap definition.
--- @class core.keymaps.Def
--- @field id string
--- @field mode? string|string[]
--- @field lhs string
--- @field rhs string|function
--- @field opts? table
--- @field _applied? boolean

--- @type table<string, core.keymaps.Def>
local registry = {}

--- Register a keymap declaratively.
--- @param def core.keymaps.Def
--- @return boolean ok
--- @return string? err
function M.register(def)
    if type(def) ~= "table" or type(def.id) ~= "string" or def.id == "" then
        return false, "keymap needs a non-empty string id"
    end
    if type(def.lhs) ~= "string" or def.lhs == "" then
        return false, ("keymap %q needs a non-empty lhs"):format(def.id)
    end
    if def.rhs == nil then
        return false, ("keymap %q needs an rhs"):format(def.id)
    end
    registry[def.id] = def
    if lc then
        lc:keymap(
            def.mode or "n",
            def.lhs,
            def.rhs,
            vim.tbl_extend("force", { desc = def.opts and def.opts.desc }, def.opts or {})
        )
    end
    return true
end

--- Apply the built-in keymaps.
--- @param opts? table
function M.setup(opts)
    opts = opts or defaults.get("keymaps", {})
    lc = lifecycle.new({ name = "core.keymaps" })

    local function map(id, mode, lhs, rhs, o)
        local ok, err = M.register({ id = id, mode = mode, lhs = lhs, rhs = rhs, opts = o })
        if not ok then
            require("core.notify").error("core.keymaps: " .. tostring(err))
        end
    end

    -- Clear search highlighting without leaving the mapping to the user.
    if opts.clear_search then
        map(
            "clear_search",
            "n",
            "<Esc>",
            "<cmd>nohlsearch<cr>",
            { desc = "clear search highlight" }
        )
    end

    if opts.window_nav then
        local nav = { { "<C-h>", "h" }, { "<C-j>", "j" }, { "<C-k>", "k" }, { "<C-l>", "l" } }
        for _, item in ipairs(nav) do
            map(
                "window_nav_" .. item[2],
                { "n", "t" },
                item[1],
                ("<C-\\><C-n><C-w>%s"):format(item[2]),
                { desc = ("go to %s window"):format(item[2]) }
            )
        end
    end

    -- Existing registry entries (registered before setup by user config/plugins).
    for _, def in pairs(registry) do
        if not def._applied then
            def._applied = true
            lc:keymap(
                def.mode or "n",
                def.lhs,
                def.rhs,
                vim.tbl_extend("force", { desc = def.opts and def.opts.desc }, def.opts or {})
            )
        end
    end

    lc:activate()
end

--- Teardown all mappings created by this module.
function M.teardown()
    if lc then
        lc:teardown()
        lc = nil
    end
end

return M
