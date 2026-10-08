--- Custom `'foldtext'`: one informative line instead of the raw first line.
---
--- Documented pieces this uses (`:h 'foldtext'`, `:h fold-foldtext`):
--- `v:foldstart`, `v:foldend`, `v:folddashes` and `v:foldlevel` are available while
--- the fold is displayed, `fillchars.fold` is the character that fills the fold text
--- (highlighted with `Folded`), and an empty `'foldtext'` disables it.
---
--- Shape: `{dashes}{icon} {first line} {fill…} {count} {label}`
--- e.g.    `▸ fn main() ······················· 12 lines`

local defaults = require("core.defaults")

local M = {}

--- Snapshot of the configuration (fold text is rendered per *fold*, but keeping it
--- out of the hot path is consistent with the rest of the UI modules).
local S = {
    enabled = true,
    label = "lines",
    fill = true,
    trim = true,
    prefix = "",
    suffix = "",
    dashes = false,
    count = "hidden",
    fill_char = ".",
    icon = false,
}

--- The text displayed for the closed fold currently being rendered.
--- @return string single line
function M.text()
    local start, stop = vim.v.foldstart, vim.v.foldend
    -- "How many lines are folded": the hidden ones by default (`stop - start`); the
    -- knob can report the total instead (`stop - start + 1`, including the first line).
    local count = S.count == "total" and (stop - start + 1) or (stop - start)

    local line = vim.fn.getline(start)
    if S.trim then
        line = vim.trim(vim.fn.substitute(line, [[\s\+]], " ", "g"))
    end

    -- `v:folddashes` encodes the fold level (`-` for level 1, `|` deeper); it is a
    -- knob because the statuscolumn already shows the depth.
    local dashes = S.dashes and ((vim.v.folddashes or "") .. " ") or ""
    -- Fill character: the knob wins, then `fillchars.fold` (Neovim's documented
    -- "filling 'foldtext'"), then a dot.
    local fillchar = S.fill_char or vim.opt.fillchars:get().fold or "."
    -- No icon by default: `fn main() .... 2 lines` is the requested look.
    local icon = S.icon and (S.icon .. " ") or ""
    local tail = ("%s%d %s"):format(S.suffix, count, S.label)
    local head = ("%s%s%s%s "):format(S.prefix, dashes, icon, line)

    -- Fill the remaining width with `fillchars.fold` (never overflow the window).
    if S.fill then
        local room = vim.api.nvim_win_get_width(0) - vim.fn.strdisplaywidth(head .. tail)
        if room > 1 then
            head = head .. string.rep(fillchar, room - 1)
        end
    end
    return head .. tail
end

--- Read the configuration.
function M.reload()
    local o = defaults.get("fold", {})
    S.enabled = o.text ~= false
    S.label = o.label or "lines"
    S.fill = o.fill ~= false
    S.trim = o.trim ~= false
    S.dashes = o.dashes == true
    --- `false` removes the fold glyph; a string replaces it.
    S.icon = o.icon or nil
    S.fill_char = o.fill_char
    S.count = o.count or "hidden"
    S.icon = o.icon
    S.prefix = o.prefix or ""
    S.suffix = o.suffix or ""
end

--- Install `'foldtext'` (idempotent). An empty value disables it, as documented.
function M.setup()
    M.reload()
    vim.o.foldtext = S.enabled and "v:lua.require'core.foldtext'.text()" or ""
end

return M
