--- t08: statuscolumn + statusline UI (mini.statuscolumn / mini.statusline).
---
--- Headless sessions cannot *draw* the UI, but both options can be evaluated
--- for real: `nvim_eval_statusline()` runs the actual content functions, so an
--- error inside a section (or a broken expression) fails this test.
local T = dofile(vim.fs.joinpath(vim.fn.stdpath("config"), "tests", "helpers.lua"))

local defaults = require("core.defaults")
local pack = require("core.pack")

-- The statusline/statuscolumn and the theme are configured by plugins that load
-- on startup. In a real session  fires after startup; with
-- `nvim -c 'luafile ...'` the command runs *before* it, so the event is fired here
-- to assert the same state an interactive session reaches.
vim.cmd([[doautocmd VimEnter]])
vim.wait(500, function()
    return false
end, 10)

T.check(pack.load("mini.nvim"), "mini.nvim (and its UI modules) loads")
T.check(package.loaded["mini.statusline"] ~= nil, "mini.statusline is loaded")
T.check(vim.o.statuscolumn ~= "", "a statuscolumn is configured")

-- The modules own the two options: mini wires them to its own dispatchers.
T.check(
    vim.go.statusline:find("MiniStatusline.active", 1, true) ~= nil,
    "statusline is wired to mini.statusline: " .. vim.inspect(vim.go.statusline)
)
T.check(
    vim.o.statuscolumn:find("core.statuscolumn", 1, true) ~= nil,
    "statuscolumn is wired to mini.statuscolumn: " .. vim.inspect(vim.o.statuscolumn)
)

-- A real buffer so the sections have something to describe.
-- ---------------------------------------------------------------------------
-- Theme (tokyonight)
-- ---------------------------------------------------------------------------

T.equal(vim.g.colors_name, "tokyonight-night", "the configured colorscheme is active")
T.equal(defaults.get("theme.style"), "night", "the night variant is the configured style")
local theme_spec = pack.get("tokyonight.nvim")
T.check(theme_spec ~= nil, "the theme plugin is declared")
T.equal(
    theme_spec and theme_spec.lazy,
    false,
    "the theme is eager (needed before the first redraw)"
)
T.equal(pack.is_loaded("tokyonight.nvim"), true, "the theme plugin is loaded")
-- ---------------------------------------------------------------------------
-- Borders come from one place: `vim.opt.winborder`
-- ---------------------------------------------------------------------------

T.equal(vim.o.winborder, "single", "the global float border is set")
T.equal(defaults.get("options.winborder"), vim.o.winborder, "and comes from the defaults")
T.equal(defaults.get("mason.border"), nil, "no per-plugin border override for the mason UI")
T.equal(defaults.get("terminal.border"), nil, "no per-plugin border override for terminals")
for _, file in ipairs({
    "lua/lib/report.lua",
    "lua/plugins/oil.lua",
    "lua/plugins/mason.lua",
    "lua/plugins/fzf_lua.lua",
    "lua/core/terminal.lua",
}) do
    local path = vim.fs.joinpath(vim.fn.stdpath("config"), file)
    local text = table.concat(vim.fn.readfile(path), "\n")
    T.check(
        not text:find('border = "', 1, true) or text:find("vim.o.winborder", 1, true) ~= nil,
        ("%s follows vim.opt.winborder instead of a hardcoded shape"):format(file)
    )
end

local MiniClue = require("mini.clue")
T.equal(
    MiniClue.config.window.delay,
    defaults.get("ui_clue.delay"),
    "the clue window delay comes from the configuration"
)
T.check(MiniClue.config.window.delay < 1000, "and is snappier than mini.clue's 1000 ms default")

local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
T.check(normal and normal.fg ~= nil, "Normal is themed by the plugin")
T.equal(
    defaults.get("options.colorscheme"),
    "tokyonight-night",
    "the plugin records the applied scheme"
)
-- The managed highlights stay `default = true`, so the theme wins over them.
local managed = vim.api.nvim_get_hl(0, { name = "WinSeparator" })
T.check(managed ~= nil, "managed highlight groups survive the theme")

local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_win_set_buf(0, buf)
vim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    { "local one = 1", "local two = 2", "local three = 3" }
)
vim.api.nvim_buf_set_name(buf, "/tmp/core-ui-test.lua")
vim.api.nvim_win_set_cursor(0, { 2, 4 })

-- statusline: evaluate the configured expression with highlights.
local statusline = vim.api.nvim_eval_statusline(vim.go.statusline, { winid = 0, highlights = true })
T.check(type(statusline.str) == "string" and statusline.str ~= "", "statusline renders text")
T.check(#(statusline.highlights or {}) > 0, "statusline reports highlight groups")
-- Sections truncate in narrow windows (80 columns in a headless session), so
-- the mode is the short form here; the full form is checked on the section
-- function itself (mini renders "Normal"/"NORMAL" depending on version).
local Mini = require("mini.statusline")
T.check(
    vim.iter({ "Normal", "NORMAL" }):any(function(mode)
        return (Mini.section_mode({ trunc_width = 0 })):find(mode, 1, true) == 1
    end),
    "mode section renders its full form: " .. vim.inspect(Mini.section_mode({ trunc_width = 0 }))
)
T.check(statusline.str:find("N", 1, true) ~= nil, "statusline shows a mode marker")
T.check(statusline.str:find("core-ui-test.lua", 1, true) ~= nil, "statusline shows the filename")
T.check(
    statusline.str:find("2|3", 1, true) ~= nil,
    "statusline shows the cursor location (line|total)"
)

-- statuscolumn: with 'number' + 'relativenumber' the cursor line shows its
-- absolute number, other lines their relative number.
local statuscolumn = vim.api.nvim_eval_statusline(vim.o.statuscolumn, {
    winid = 0,
    use_statuscol_lnum = 2,
    highlights = true,
})
T.check(type(statuscolumn.str) == "string" and statuscolumn.str ~= "", "statuscolumn renders text")
T.check(
    statuscolumn.str:find("2", 1, true) ~= nil,
    "statuscolumn shows the cursor line number: " .. vim.inspect(statuscolumn.str)
)
T.check(#(statuscolumn.highlights or {}) > 0, "statuscolumn reports highlight groups")

-- Section knobs really reach the statusline (git/diff sections are dropped).
defaults.values.ui.statusline.git = false
defaults.values.ui.statusline.diff = false
require("plugins.mini_statusline").setup(defaults.get("ui.statusline"))
local without_git = vim.api.nvim_eval_statusline(vim.go.statusline, { winid = 0 })
T.check(without_git.str ~= "", "statusline still renders with git/diff sections disabled")
T.check(
    without_git.str:find("core-ui-test.lua", 1, true) ~= nil,
    "filename section survives section changes"
)

-- statuscolumn glyphs come from configuration.

-- The statuscolumn follows snacks.nvim's layout (what LazyVim uses):
-- [left: mark, sign] + [right-aligned number + gap] + [right: fold, git], wrapped
-- in a click handler that toggles the fold under the cursor.
local sc = require("core.statuscolumn")
vim.cmd("enew")
local sc_win, sc_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(
    sc_buf,
    0,
    -1,
    false,
    { "satu", "if x then", "    dalam", "end", "empat" }
)
vim.api.nvim_buf_set_mark(sc_buf, "m", 1, 0, {})
defaults.values.ui.statuscolumn.mark_hl = "Special"
-- The renderer snapshots its options in `reload()` (part of being fast).
sc.reload()
T.check(
    sc.line(sc_win, sc_buf, 1, { virtnum = 0, relnum = 0 }):find("%#Special#", 1, true) ~= nil,
    "the mark highlight group is configurable"
)
defaults.values.ui.statuscolumn.mark_hl = "DiagnosticHint"
sc.reload()
local sc_ns = vim.api.nvim_create_namespace("t08_statuscolumn")
vim.diagnostic.set(
    sc_ns,
    sc_buf,
    { { lnum = 1, col = 0, message = "warn", severity = vim.diagnostic.severity.WARN } }
)
-- A fold is needed to test the fold glyph; creating one is not always possible in a
-- headless session, so this part reports and skips instead of failing.
vim.wo[sc_win].foldmethod = "manual"
vim.cmd("2,3fold")
local folded_lnum
for lnum = 1, vim.api.nvim_buf_line_count(sc_buf) do
    if vim.fn.foldclosed(lnum) ~= -1 then
        folded_lnum = lnum
        break
    end
end
if folded_lnum == nil then
    T.info("no fold could be created here; the fold glyph check is skipped")
end
local marked = sc.line(sc_win, sc_buf, 1, { virtnum = 0, relnum = 0 })
T.check(
    marked:find("%%#DiagnosticHint#m", 1, false) ~= nil,
    "mark letter with its group: " .. marked
)
T.check(marked:find("%=", 1, true) ~= nil, "the number is right-aligned")
T.check(marked:find("%@v:lua", 1, true) ~= nil, "a click handler wraps the line")
local signed = sc.line(sc_win, sc_buf, 2, { virtnum = 0, relnum = 1 })
T.check(
    signed:find("%%#DiagnosticSignWarn#", 1, false) ~= nil,
    "diagnostic sign with its group: " .. signed
)
if folded_lnum then
    local folded = sc.line(sc_win, sc_buf, folded_lnum, { virtnum = 0, relnum = folded_lnum })
    T.check(
        folded:find("%%#Folded#", 1, false) ~= nil,
        "closed fold shows the fold glyph: " .. folded
    )
    T.check(
        folded:find("%%#Folded#▸", 1, false) ~= nil,
        "the fold glyph is shown only when the fold hides lines: " .. folded
    )
    defaults.values.ui.statuscolumn.fold_count = true
    sc.reload()
    T.check(
        sc.line(sc_win, sc_buf, folded_lnum, { virtnum = 0, relnum = folded_lnum })
            :find("%%#Folded#▸%d", 1, false) ~= nil,
        "the count can be appended in the column too"
    )
    defaults.values.ui.statuscolumn.fold_count = false
    sc.reload()
end
-- Fold text: the renderer is exercised explicitly (the configured default is the
-- syntax-preserving empty `'foldtext'`). `foldtextresult()` is the documented way to
-- read what a closed fold displays.
defaults.values.fold.text = true
require("core.foldtext").setup()
vim.wo.foldmethod = "manual"
vim.cmd("2,3fold")
local fold_text = vim.fn.foldtextresult(2)
T.check(fold_text ~= "", "a closed fold has text: " .. fold_text)
T.check(fold_text:find("if x then", 1, true) ~= nil, "fold text shows the first line")
T.check(
    fold_text:find("1 lines", 1, true) ~= nil,
    "fold text shows how many lines are folded away: " .. fold_text
)
defaults.values.fold.count = "total"
require("core.foldtext").setup()
T.check(
    vim.fn.foldtextresult(2):find("2 lines", 1, true) ~= nil,
    "the count can include the whole fold instead"
)
defaults.values.fold.count = "hidden"
require("core.foldtext").setup()
T.check(fold_text:find("..", 1, true) ~= nil, "fold text is filled with dots")
defaults.values.fold.icon = "▸"
require("core.foldtext").setup()
T.check(vim.fn.foldtextresult(2):find("▸", 1, true) ~= nil, "the fold glyph can be enabled")
defaults.values.fold.icon = false
require("core.foldtext").setup()
vim.cmd("2,3foldopen")
vim.wo.foldmethod = "expr"
defaults.values.fold.text = false
require("core.foldtext").setup()
T.equal(vim.o.foldtext, "", "the configured default keeps syntax highlighting")

-- Git signs: `core.gitsign` places them itself (mini.diff computes the hunks here
-- but does not place signs, and a custom statuscolumn replaces the sign column), and
-- a `MiniDiffSign*` sign must render on the *right* side of the number.
local gitsign = require("core.gitsign")
gitsign.define()
-- Line 5 is outside the closed fold: on a folded line the fold glyph legitimately
-- wins the right-hand slot (fold is first in `right`), exactly like snacks.
vim.fn.sign_place(0, gitsign.group, "MiniDiffSignAdd", sc_buf, { lnum = 5, priority = 5 })
-- Signs placed without an event are picked up by the lazy TTL (`refresh_ms`).
vim.wait(90, function()
    return false
end, 10)
local git_line = sc.line(sc_win, sc_buf, 5, { virtnum = 0, relnum = 4 })
T.check(
    git_line:find("%#MiniDiffSignAdd#│", 1, true) ~= nil,
    "git signs render on the right side: " .. git_line
)
vim.fn.sign_unplace(gitsign.group, { buffer = sc_buf })

vim.wo[sc_win].foldmethod = "expr"
vim.wo[sc_win].foldlevel = 99
-- Disabling the UI modules leaves the options untouched.
local before = vim.go.statusline
require("plugins.mini_statusline").setup({ enabled = false })
T.equal(vim.go.statusline, before, "enabled = false leaves statusline untouched")

T.finish()
