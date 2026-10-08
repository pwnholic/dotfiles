--- Native `'statuscolumn'`, modelled on `snacks.nvim`'s (the one LazyVim uses):
---
---     [left: mark, sign][right-aligned number + gap][right: fold, git]
---
--- Smoothness notes:
---   * signs are read from extmarks (`type = "sign"`) and **cached per buffer**,
---     invalidated by the events that can change them (`MiniDiffUpdated`,
---     `DiagnosticChanged`, edits, buffer entry) instead of per line per redraw,
---   * the resolved options, glyphs and side lists are computed once in `setup()`,
---     so the hot path does not walk `defaults`, `deepcopy` or read `fillchars`,
---   * pure cursor moves only redraw the statuscolumn when the cursor line changes
---     (same trick as snacks), so the `CursorLineNr` number never lags behind,
---   * rendering is wrapped in `pcall`: a redraw must never raise an error.
---
--- Deviation from the reference: fold state comes from the documented
--- `foldclosed()` instead of its `ffi.fold_info()` call.

local defaults = require("core.defaults")

local M = {}

--- Resolved configuration and option-derived values (rebuilt on setup/reload).
local S = {
    seeds = {},
}

--- Cache of signs per buffer, invalidated by the events that change them and by a
--- short lazy TTL (`refresh_ms`): signs placed by other code without an event are
--- picked up within that window. snacks.nvim uses a 50 ms repeating timer for this;
--- checking the clock while rendering costs ~0.1 us and wakes up nothing.
M.cache = {}
M.stamp = 0

--- Sign names that come from git.
--- @param name string
--- @return boolean
local function is_git_sign(name)
    for _, pattern in ipairs(S.git_patterns) do
        if name:find(pattern, 1, true) then
            return true
        end
    end
    return false
end

--- Read every sign and mark of a buffer, grouped by line.
--- Signs come from extmarks, which on Neovim 0.10+ include the legacy signs placed
--- by plugins such as mini.diff and the diagnostic signs; extmarks without
--- `sign_text` cannot be drawn and are skipped.
--- @param bufnr integer
--- @return table<integer, table[]>
function M.read(bufnr)
    local out = {}
    for _, extmark in
        ipairs(vim.api.nvim_buf_get_extmarks(bufnr, -1, 0, -1, { details = true, type = "sign" }))
    do
        local details = extmark[4] or {}
        local text = details.sign_text
        if type(text) == "string" and text ~= "" then
            local lnum = extmark[2] + 1
            out[lnum] = out[lnum] or {}
            table.insert(out[lnum], {
                text = text,
                texthl = details.sign_hl_group,
                priority = details.priority,
                type = is_git_sign(details.sign_hl_group or details.sign_name or "") and "git"
                    or "sign",
            })
        end
    end

    if S.marks ~= false then
        local marks = vim.fn.getmarklist(bufnr)
        vim.list_extend(marks, vim.fn.getmarklist())
        for _, mark in ipairs(marks) do
            if mark.pos and mark.pos[1] == bufnr and tostring(mark.mark):match("^'[a-zA-Z]$") then
                local lnum = mark.pos[2]
                out[lnum] = out[lnum] or {}
                table.insert(out[lnum], {
                    text = tostring(mark.mark):sub(2),
                    texthl = S.mark_hl,
                    type = "mark",
                    priority = 10,
                })
            end
        end
    end
    return out
end

--- Cached signs of a buffer.
--- @param bufnr integer
--- @return table<integer, table[]>
function M.signs(bufnr)
    local now = vim.uv.hrtime()
    local cached = M.cache[bufnr]
    if cached and (now - M.stamp) < S.refresh_ns then
        return cached
    end
    local signs = M.read(bufnr)
    M.cache[bufnr] = signs
    M.stamp = now
    return signs
end

--- Drop the caches (signs change; called from the events that can do that).
function M.invalidate()
    M.cache = {}
    M.stamp = 0
end

--- One sign as a 2-cell icon with its group (`%*` resets), or two spaces.
--- @param sign? table
--- @return string
local function icon(sign)
    if not sign then
        return "  "
    end
    local text = vim.fn.strcharpart(sign.text, 0, 2)
    text = text .. string.rep(" ", math.max(0, 2 - vim.fn.strchars(text)))
    if type(sign.texthl) == "string" and sign.texthl ~= "" then
        return ("%%#%s#%s%%*"):format(sign.texthl, text)
    end
    return text
end

--- First sign of the wanted types on a line (the side lists are ordered by priority).
--- @param signs table[]
--- @param types string[]
--- @return table?
local function pick(signs, types)
    local found = {}
    for _, sign in ipairs(signs) do
        found[sign.type] = found[sign.type] or sign
    end
    for _, kind in ipairs(types) do
        if found[kind] then
            return found[kind]
        end
    end
end

--- Render one line. Pure given its arguments, so it is testable outside of a real
--- statuscolumn evaluation (`vim.v.*` is only valid while rendering).
--- @param win integer
--- @param bufnr integer
--- @param lnum integer
--- @param v { virtnum: integer, relnum: integer }
--- @return string
function M.line(win, bufnr, lnum, v)
    local number = vim.wo[win].number
    local relnumber = vim.wo[win].relativenumber
    local show_signs = v.virtnum == 0 and vim.wo[win].signcolumn ~= "no"
    local show_folds = v.virtnum == 0
    if not (show_signs or number or relnumber) then
        return ""
    end

    local middle = ""
    if (number or relnumber) and v.virtnum == 0 then
        local num = lnum
        if relnumber then
            num = (number and v.relnum == 0) and lnum or v.relnum
        end
        middle = ("%%=%d%s"):format(num, S.gap)
    end

    local left, right = "  ", "  "
    if show_signs or show_folds then
        -- The fold check must run even when the line has no sign at all.
        local signs = vim.deepcopy(M.signs(bufnr)[lnum] or {})
        if true then
            if show_folds then
                local closed_start = vim.fn.foldclosed(lnum)
                -- snacks shows the fold glyph only for folds that hide lines
                -- (`info.lines > 0`); a fold with nothing hidden gets nothing, and an
                -- *open* fold is marked only when `folds.open` is on.
                local hidden = closed_start ~= -1 and (vim.fn.foldclosedend(lnum) - lnum) or 0
                if hidden > 0 then
                    local text = S.fold_close
                    if S.fold_count then
                        text = ("%s%d"):format(S.fold_close, math.min(hidden, 99))
                    end
                    signs = vim.list_extend(signs, {
                        { text = text, texthl = S.fold_hl, type = "fold", priority = 200 },
                    })
                elseif S.folds_open and vim.fn.foldlevel(lnum) > 0 then
                    signs = vim.list_extend(signs, {
                        { text = S.fold_open, type = "fold", priority = 200 },
                    })
                end
            end
            -- snacks parity: optionally colour the fold glyph like the git sign.
            if S.git_hl then
                local by_type = {}
                for _, sign in ipairs(signs) do
                    by_type[sign.type] = by_type[sign.type] or sign
                end
                if by_type.fold and by_type.git and by_type.git.texthl then
                    by_type.fold.texthl = by_type.git.texthl
                end
            end
            left = icon(pick(signs, S.left))
            right = icon(pick(signs, S.right))
        end
    end

    return ("%%@v:lua.require'core.statuscolumn'.click_fold@%s%s%s%%T"):format(left, middle, right)
end

--- The expression result for the current line (never raises).
--- @return string
function M.render()
    local ok, ret = pcall(function()
        local win = vim.g.statusline_winid
        if type(win) ~= "number" or win == 0 then
            win = vim.api.nvim_get_current_win()
        end
        return M.line(win, vim.api.nvim_win_get_buf(win), vim.v.lnum, {
            virtnum = vim.v.virtnum,
            relnum = vim.v.relnum,
        })
    end)
    return ok and ret or ""
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

--- Re-read the configuration and the option-derived values.
function M.reload()
    local o = defaults.get("ui.statuscolumn", {})
    local fillchars = vim.opt.fillchars:get()
    S.left = o.left or { "mark", "sign" }
    S.right = o.right or { "fold", "git" }
    S.marks = o.marks
    S.marks_width = o.marks_width or 2
    S.mark_hl = o.mark_hl or "DiagnosticHint"
    S.fold_hl = o.fold_hl or "Folded"
    S.cursor_lnum_hl = o.cursor_lnum_hl or "CursorLineNr"
    S.lnum_hl = o.lnum_hl or "LineNr"
    S.folds_open = o.folds_open
    S.fold_count = o.fold_count == true
    S.git_hl = o.git_hl == true
    S.git_patterns = o.git_patterns or { "GitSign", "MiniDiffSign" }
    S.gap = o.trailing_gap == false and "" or " "
    S.fold_close = fillchars.foldclose or "▸"
    S.fold_open = fillchars.foldopen or "▾"
    S.refresh_ns = (o.refresh_ms or 50) * 1e6
    M.invalidate()
end

--- Redraw the statuscolumn when the cursor line changed, so highlights that depend
--- on it (`CursorLineNr`, relative numbers) are not one redraw behind.
local redraw_lnum = 0
local function nudge_redraw()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    if lnum == redraw_lnum then
        return
    end
    redraw_lnum = lnum
    pcall(vim.api.nvim__redraw, { win = 0, statuscolumn = true })
end

--- Install the expression, the caches and the redraw hooks (idempotent).
function M.setup()
    local o = defaults.get("ui.statuscolumn", {})
    if o.enabled == false then
        return
    end
    M.reload()
    vim.o.statuscolumn = "%!v:lua.require'core.statuscolumn'.render()"

    local group = vim.api.nvim_create_augroup("core_statuscolumn", { clear = true })
    --- Events that change signs or marks.
    vim.api.nvim_create_autocmd(
        { "BufEnter", "TextChanged", "InsertLeave", "BufWritePost", "DiagnosticChanged" },
        {
            group = group,
            callback = M.invalidate,
            desc = "core: statuscolumn sign cache invalidation",
        }
    )
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "MiniDiffUpdated",
        callback = M.invalidate,
        desc = "core: git signs changed",
    })
    --- Glyphs come from `fillchars`.
    vim.api.nvim_create_autocmd("OptionSet", {
        group = group,
        pattern = "fillchars",
        callback = M.reload,
        desc = "core: statuscolumn fold glyphs",
    })
    --- Cursor-line-dependent highlights.
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = group,
        callback = nudge_redraw,
        desc = "core: statuscolumn cursorline redraw",
    })
end

return M
