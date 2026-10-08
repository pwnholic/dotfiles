--- Git signs placed by us, for the statuscolumn.
---
--- Why this exists: `mini.diff` tracks buffers and computes hunks (its summary does
--- reach the statusline), but in this setup it never places its own signs -- and a
--- custom `'statuscolumn'` replaces the native sign column, which is where those
--- signs would have been drawn. This module reads the hunks from
--- `MiniDiff.get_buf_data()` (a documented API) and places the signs itself.
---
--- Sign names are `MiniDiffSign*` on purpose: that is the pattern the statuscolumn
--- classifies as git (and shows on the right side). Highlights are linked to the
--- original groups (`Added`/`Changed`/`Removed`) with `default = true`, so a
--- colorscheme or mini.diff may still override them.

local defaults = require("core.defaults")

local M = {}

--- Sign group owned by this module.
M.group = "CoreGitSigns"

--- @type table<string, { text: string, hl: string, link: string }>
M.kinds = {
    add = { text = nil, hl = "MiniDiffSignAdd", link = "Added" },
    change = { text = nil, hl = "MiniDiffSignChange", link = "Changed" },
    delete = { text = nil, hl = "MiniDiffSignDelete", link = "Removed" },
}

local function options()
    return defaults.get("git", {})
end

--- Define the signs and their (default) highlights.
function M.define()
    local texts = options().signs or {}
    for kind, spec in pairs(M.kinds) do
        vim.api.nvim_set_hl(0, spec.hl, { link = spec.link, default = true })
        vim.fn.sign_define(spec.hl, { text = texts[kind] or "│", texthl = spec.hl })
    end
end

--- Place the signs for every hunk of a buffer, replacing the previous ones.
--- @param bufnr integer
function M.refresh(bufnr)
    if options().place_signs == false then
        return
    end
    -- Hooks can fire for buffers that are already gone (`BufEnter` + `vim.schedule`,
    -- scratch buffers, ...): mini.diff raises for an invalid id, and nothing here may
    -- ever surface as an error message.
    if
        type(bufnr) ~= "number"
        or not vim.api.nvim_buf_is_valid(bufnr)
        or not vim.api.nvim_buf_is_loaded(bufnr)
    then
        return
    end
    local ok, diff = pcall(require, "mini.diff")
    if not ok or type(diff.get_buf_data) ~= "function" then
        return
    end
    local ok_data, data = pcall(diff.get_buf_data, bufnr)
    if not ok_data or type(data) ~= "table" then
        return
    end
    M.define()
    pcall(vim.fn.sign_unplace, M.group, { buffer = bufnr })

    local id = 0
    local hunk_count = vim.api.nvim_buf_line_count(bufnr)
    for _, hunk in ipairs(data.hunks or {}) do
        -- `{ type, ref_start, ref_count, buf_start, buf_count }` (mini.diff's source).
        local kind = M.kinds[hunk.type] and hunk.type or "delete"
        local start = hunk.buf_start or 0
        -- A deletion has no buffer lines: its sign belongs on the line above it.
        local count = math.max(1, hunk.buf_count or 0)
        for i = 0, count - 1 do
            local lnum = start + i
            if lnum >= 1 and lnum <= hunk_count then
                id = id + 1
                pcall(vim.fn.sign_place, id, M.group, M.kinds[kind].hl, bufnr, {
                    lnum = lnum,
                    priority = 5,
                })
            end
        end
    end
end

--- Hook mini.diff's update event (and buffer entry, for the initial pass).
function M.setup()
    if options().place_signs == false then
        return
    end
    M.define()
    local group = vim.api.nvim_create_augroup("core_gitsign", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "MiniDiffUpdated",
        desc = "core: place git signs for the statuscolumn",
        callback = function(args)
            M.refresh(args.buf)
        end,
    })
    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        desc = "core: git signs when entering a buffer",
        callback = function(args)
            vim.schedule(function()
                M.refresh(args.buf)
            end)
        end,
    })
end

return M
