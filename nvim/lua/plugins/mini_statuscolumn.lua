--- mini.statuscolumn: the sign/fold/number column, clickable, with dimming in
--- inactive windows.
---
--- Configured together with `mini.nvim` (one repository = one pack spec):
--- `lua/plugins/mini.lua` calls `M.setup()` from its config hook.
---
--- Content is generated from a specification (mini's data-driven generator), so
--- sections can be reordered/removed without touching the engine:
---
---   { fold = "%C", sign = "%s", lnum = "%l" }  -- available sections
---   { format = "=lfs", sep = ... }             -- order `f`old/s`ign/`l`num
---   { ltype = "virt", lnum = ... }             -- virtual lines
---   { ltype = "wrap", lnum = ... }             -- wrapped lines
---   { win = "inactive", sep = " " }            -- inactive windows
---
--- Click behaviour: `MiniStatuscolumn.default_click()` selects the clicked
--- window/line (and centers on double click); this handler adds a fold toggle on
--- the fold section and diagnostics on the sign section.
---
--- Note: on Neovim 0.12 the clickable ranges are computed once per window, so
--- the section in `data` is a best-effort hint. The handler therefore only acts
--- when the clicked line really has a fold/diagnostic.
---
--- @class plugins.mini_statuscolumn
local M = {}

--- Mouse handler passed to mini's content generator (exposed for tests/docs).
--- @param data table `{ section, n_clicks, ltype, mousepos, ... }`
function M.click(data)
    local Mini = require("mini.statuscolumn")
    Mini.default_click(data)

    local mousepos = data and data.mousepos
    local win, line = mousepos and mousepos.winid, mousepos and mousepos.line
    if not win or not line or not vim.api.nvim_win_is_valid(win) then
        return
    end

    if data.section == "fold" then
        vim.api.nvim_win_call(win, function()
            -- Only toggle folds that exist: a stray click must not create a
            -- manual fold in a buffer that has none.
            if vim.fn.foldclosed(line) == -1 and vim.fn.foldlevel(line) == 0 then
                return
            end
            vim.cmd(("normal! %dGza"):format(line))
        end)
        return
    end

    if data.section == "sign" then
        local bufnr = vim.api.nvim_win_get_buf(win)
        local diagnostics = vim.diagnostic.get(bufnr, { lnum = line - 1 })
        if #diagnostics > 0 then
            vim.diagnostic.open_float({
                bufnr = bufnr,
                scope = "line",
                pos = { line - 1, diagnostics[1].col },
            })
        end
    end
end

--- @param o? { enabled?: boolean, dim?: boolean, separator?: string, virt?: string, wrap?: string }
function M.setup(o)
    o = o or require("core.defaults").get("ui.statuscolumn", {})
    if o.enabled == false then
        return
    end

    local Mini = require("mini.statuscolumn")
    Mini.setup({
        content = Mini.gen_content.main({
            { fold = "%C", sign = "%s", lnum = "%l" },
            { format = "=lfs", sep = o.separator or "▏" },
            { ltype = "virt", lnum = o.virt or "•" },
            { ltype = "wrap", lnum = o.wrap or "↳" },
            { win = "inactive", sep = " " },
        }, { click = M.click }),
        dim_inactive = o.dim ~= false,
    })
end

return M
