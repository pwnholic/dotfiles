--- Native `'statuscolumn'`, modelled on `snacks.nvim`'s statuscolumn (the one
--- LazyVim uses):
---
---     [left: mark, sign][right-aligned number + gap][right: fold, git]
---
--- Differences to the reference, both deliberate: fold state comes from the
--- documented `foldclosed()`/`foldclosedend()` instead of its `ffi` call into
--- `fold_info()`, and the per-line cache refreshed by a 50 ms timer is replaced by
--- signs are read on every render instead of being cached (snacks uses a 50 ms
--- refresh timer for that; extmark scans over signs only are cheap enough).

local defaults = require("core.defaults")

local M = {}

--- @class core.statuscolumn.Sign
--- @field text string
--- @field texthl string?
--- @field priority integer?
--- @field type "mark"|"sign"|"fold"|"git"

local function config()
    return defaults.get("ui.statuscolumn", {})
end

--- Sign names that come from git (mini.diff uses `MiniDiffSign*`).
--- @param name string
--- @return boolean
function M.is_git_sign(name)
    for _, pattern in ipairs(config().git_patterns or { "GitSign", "MiniDiffSign" }) do
        if name:find(pattern, 1, true) then
            return true
        end
    end
    return false
end

--- Every sign and mark of a buffer, grouped by line.
--- Signs come from extmarks (`type = "sign"`), which on Neovim 0.10+ include the
--- legacy signs placed by plugins such as mini.diff and the diagnostic signs.
--- @param bufnr integer
--- @return table<integer, core.statuscolumn.Sign[]>
function M.buf_signs(bufnr)
    local out = {}

    for _, extmark in
        ipairs(vim.api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, { details = true, type = "sign" }))
    do
        local details = extmark[4] or {}
        local name = details.sign_hl_group or details.sign_name or ""
        -- Signs without text cannot be drawn (plugins place such extmarks too,
        -- e.g. only for highlights), so they are skipped.
        if details.sign_text ~= nil and details.sign_text ~= "" then
            local sign = {
                text = details.sign_text,
                texthl = details.sign_hl_group,
                priority = details.priority,
                type = M.is_git_sign(name) and "git" or "sign",
            }
            local lnum = extmark[2] + 1
            out[lnum] = out[lnum] or {}
            table.insert(out[lnum], sign)
        end
    end

    -- Marks that still exist in the buffer (and file-wide marks pointing at it).
    local marks = vim.fn.getmarklist(bufnr)
    vim.list_extend(marks, vim.fn.getmarklist())
    for _, mark in ipairs(marks) do
        if mark.pos and mark.pos[1] == bufnr and tostring(mark.mark):match("^'[a-zA-Z]$") then
            local lnum = mark.pos[2]
            out[lnum] = out[lnum] or {}
            table.insert(out[lnum], {
                text = tostring(mark.mark):sub(2),
                texthl = config().mark_hl or "DiagnosticHint",
                type = "mark",
            })
        end
    end

    return out
end

--- Signs for one line, folds included, sorted by priority (high to low).
--- @param bufnr integer
--- @param lnum integer
--- @return core.statuscolumn.Sign[]
function M.line_signs(bufnr, lnum)
    local o = config()
    -- No cache: mini.diff (and friends) place signs asynchronously, without a buffer
    -- change, so a `changedtick`-keyed cache goes stale and the signs never appear.
    -- snacks.nvim solves this with a 50 ms refresh timer; `nvim_buf_get_extmarks`
    -- over signs only is cheap enough to just read every time.
    local list = vim.deepcopy(M.buf_signs(bufnr)[lnum] or {})

    -- Fold: a closed fold shows its glyph on the only visible line; open folds are
    -- only marked when `folds_open` is on (off by default, like the reference).
    local foldclose = vim.opt.fillchars:get().foldclose or "▸"
    if vim.fn.foldclosed(lnum) ~= -1 then
        list[#list + 1] =
            { text = foldclose, texthl = o.fold_hl or "Folded", type = "fold", priority = 200 }
    elseif o.folds_open and vim.fn.foldlevel(lnum) > 0 and vim.fn.foldlevel(lnum + 1) > 0 then
        list[#list + 1] = {
            text = vim.opt.fillchars:get().foldopen or "▾",
            type = "fold",
            priority = 200,
        }
    end

    table.sort(list, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
    end)
    return list
end

--- One sign as a 2-cell icon with its highlight group (`%*` resets, like the
--- reference does), or two spaces when there is no sign.
--- @param sign? core.statuscolumn.Sign
--- @return string
function M.icon(sign)
    if not sign then
        return "  "
    end
    local text = vim.fn.strcharpart(sign.text or "", 0, 2)
    text = text .. string.rep(" ", math.max(0, 2 - vim.fn.strchars(text)))
    if type(sign.texthl) == "string" and sign.texthl ~= "" then
        return ("%%#%s#%s%%*"):format(sign.texthl, text)
    end
    return text
end

--- Render one line. Pure given `(win, bufnr, lnum, v)` so it can be tested outside
--- of a real statuscolumn evaluation (`vim.v.*` is only valid during rendering).
--- @param win integer
--- @param bufnr integer
--- @param lnum integer
--- @param v { virtnum: integer, relnum: integer }
--- @return string
function M.line(win, bufnr, lnum, v)
    local o = config()
    local number = vim.wo[win].number
    local relnumber = vim.wo[win].relativenumber
    local show_signs = v.virtnum == 0 and vim.wo[win].signcolumn ~= "no"
    local show_folds = v.virtnum == 0 and vim.wo[win].foldcolumn ~= "0"
    if not (show_signs or number or relnumber) then
        return ""
    end

    local left = vim.deepcopy(o.left or { "mark", "sign" })
    local right = vim.deepcopy(o.right or { "fold", "git" })
    local components = { "  ", "", "  " }

    if (number or relnumber) and v.virtnum == 0 then
        local num = lnum
        if relnumber then
            num = (number and v.relnum == 0) and lnum or v.relnum
        end
        -- `%=` right-aligns the number, the trailing space is the gap to the code.
        components[2] = ("%%=%d "):format(num)
    end

    if show_signs or show_folds then
        local signs = M.line_signs(bufnr, lnum)
        if #signs > 0 then
            local by_type = {}
            for _, sign in ipairs(signs) do
                by_type[sign.type] = by_type[sign.type] or sign
            end
            --- @param types string[]
            local function first_of(types)
                for _, kind in ipairs(types) do
                    if by_type[kind] then
                        return by_type[kind]
                    end
                end
            end
            components[1] = M.icon(first_of(left))
            components[3] = M.icon(first_of(right))
        end
    end

    local ret = table.concat(components, "")
    -- Clicking the statuscolumn toggles the fold under the cursor (`za`).
    return "%@v:lua.require'core.statuscolumn'.click_fold@" .. ret .. "%T"
end

--- The expression result for the current line.
--- @return string
function M.render()
    local win = vim.g.statusline_winid
    if type(win) ~= "number" or win == 0 then
        win = vim.api.nvim_get_current_win()
    end
    return M.line(win, vim.api.nvim_win_get_buf(win), vim.v.lnum, {
        virtnum = vim.v.virtnum,
        relnum = vim.v.relnum,
    })
end

--- Toggle the fold under the mouse (`%@` item of `'statuscolumn'`).
function M.click_fold()
    local pos = vim.fn.getmousepos()
    if pos.winid == 0 then
        return
    end
    vim.api.nvim_win_set_cursor(pos.winid, { pos.line, 1 })
    vim.api.nvim_win_call(pos.winid, function()
        if vim.fn.foldlevel(pos.line) > 0 then
            vim.cmd("normal! za")
        end
    end)
end

--- Install the expression (idempotent).
function M.setup()
    local o = config()
    if o.enabled == false then
        return
    end
    vim.o.statuscolumn = "%!v:lua.require'core.statuscolumn'.render()"
end

return M
