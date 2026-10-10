-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local g, opts = vim.g, vim.opt

g.lazyvim_blink_main = true
-- AI completion off: blink ghost text + sidekick NES stay disabled.
g.ai_cmp = false
g.sidekick_nes = false
g.lazyvim_python_lsp = "basedpyright"
g.lazyvim_python_ruff = "ruff"
g.lazyvim_rust_diagnostics = "rust-analyzer"

opts.winborder = "single"
opts.cmdheight = 0

-- 4 spaces (LazyVim default 2); `tabstop` stays 2 so existing tabs render unchanged.
opts.shiftwidth = 4
opts.tabstop = 4
opts.softtabstop = 4

opts.confirm = false

-- Block everywhere except operator-pending (half bar) and replace (thin bar); blink ~1s.
opts.guicursor = {
    "i-c-ci-ve:blinkoff500-blinkon500-block-Cursor/lCursor",
    "n-v:block-Cursor/lCursor",
    "o:hor50-Cursor/lCursor",
    "r-cr:hor20-Cursor/lCursor",
}

-- Hidden while typing (see autocmds toggle); `number` keeps only the gutter lit.
opts.cursorcolumn = true
opts.cursorline = true
opts.cursorlineopt = "both"

opts.path:append("**")
opts.diffopt:append({ "algorithm:histogram", "indent-heuristic", "linematch:60" })
opts.foldopen:remove("block")
opts.formatoptions:append("nm")
opts.nrformats:append("blank")
opts.tabclose = "uselast"
opts.mousemoveevent = true

-- Tabs blank; only trailing/non-breakable spaces marked.
opts.listchars = {
    tab = "  ",
    trail = "·",
    nbsp = "␣",
}
