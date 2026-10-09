-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local g, opts = vim.g, vim.opt

g.lazyvim_blink_main = true
g.lazyvim_python_lsp = "basedpyright"
g.lazyvim_python_ruff = "ruff"
g.lazyvim_rust_diagnostics = "rust-analyzer"

opts.winborder = "single"
opts.cmdheight = 0

-- Indentation: 4 spaces instead of LazyVim's 2.
--
-- LazyVim sets these as *global* options in `lazyvim/config/options.lua` (shiftwidth and tabstop
-- are both 2, expandtab is on), and this file is sourced after it, so a plain global assignment
-- here wins. LazyVim has no `vim.g` variable for indentation, so overriding the options is the
-- only supported route.
--
-- Nothing is forced per filetype: `tabstop` is left at 2 so that an existing tab still renders
-- with the width it has today, while `shiftwidth` and `softtabstop` at 4 make both `<Tab>` and
-- the `>>`/`<<` operators use 4 spaces (verified: with expandtab on, all three produce 4).
opts.shiftwidth = 4
opts.softtabstop = 4

opts.confirm = false

-- Cursor shapes per mode (`:h guicursor`): block everywhere except
-- operator-pending (half bar) and replace/cmdline-replace (thin bar).
-- Insert/command/visual blink ~1s so the cursor stays findable; the
-- highlight is `Cursor`/`lCursor` (language-aware variant).
opts.guicursor = {
    "i-c-ci-ve:blinkoff500-blinkon500-block-Cursor/lCursor",
    "n-v:block-Cursor/lCursor",
    "o:hor50-Cursor/lCursor",
    "r-cr:hor20-Cursor/lCursor",
}

-- `cursorline` comes from LazyVim; `cursorcolumn` is ours. Both are
-- hidden while typing (see `user_cursorline_insert_toggle` in
-- `lua/config/autocmds.lua`): with a blinking block cursor the current
-- position is already obvious, and the extra row/column highlight is
-- visual noise mid-keystroke.
opts.cursorcolumn = true
opts.cursorline = true
