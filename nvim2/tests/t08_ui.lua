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
T.check(package.loaded["mini.statuscolumn"] ~= nil, "mini.statuscolumn is loaded")

-- The modules own the two options: mini wires them to its own dispatchers.
T.check(
    vim.go.statusline:find("MiniStatusline.active", 1, true) ~= nil,
    "statusline is wired to mini.statusline: " .. vim.inspect(vim.go.statusline)
)
T.check(
    vim.o.statuscolumn:find("MiniStatuscolumn.active", 1, true) ~= nil,
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
defaults.values.ui.statuscolumn.separator = "!"
require("plugins.mini_statuscolumn").setup(defaults.get("ui.statuscolumn"))
local custom_column =
    vim.api.nvim_eval_statusline(vim.o.statuscolumn, { winid = 0, use_statuscol_lnum = 2 })
T.check(custom_column.str:find("!", 1, true) ~= nil, "statuscolumn uses the configured separator")

-- The click handler is safe for every section it can receive, and it toggles
-- folds only when the clicked line actually has one.
local statuscolumn_plugin = require("plugins.mini_statuscolumn")
for _, section in ipairs({ "fold", "sign", "lnum", "sep" }) do
    local ok, err = pcall(statuscolumn_plugin.click, {
        section = section,
        n_clicks = 1,
        ltype = "text",
        mousepos = { winid = 0, line = 2, column = 1, screenrow = 1, screencol = 1 },
    })
    T.check(ok, ("click on the %s section is safe: %s"):format(section, tostring(err)))
end

-- Fold toggle: create a fold, click its column section, expect it to open.
vim.wo.foldmethod = "manual"
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd("normal! zf2j")
T.check(vim.fn.foldclosed(1) ~= -1, "test fold is closed")
statuscolumn_plugin.click({
    section = "fold",
    n_clicks = 1,
    ltype = "text",
    mousepos = { winid = 0, line = 1, column = 1, screenrow = 1, screencol = 1 },
})
T.equal(vim.fn.foldclosed(1), -1, "clicking the fold section opened the fold")

-- Disabling the UI modules leaves the options untouched.
local before = vim.go.statusline
require("plugins.mini_statusline").setup({ enabled = false })
T.equal(vim.go.statusline, before, "enabled = false leaves statusline untouched")

T.finish()
