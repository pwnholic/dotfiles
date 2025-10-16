-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.winborder = "single"
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.opt.showtabline = 0
vim.opt.cmdheight = 0
vim.opt.colorcolumn = "100,130"
vim.opt.cursorcolumn = true

vim.opt.spell = true
vim.opt.spelllang = { "en" }
vim.opt.spellcapcheck = ""
vim.opt.spelloptions = "camel"
vim.opt.spellsuggest = "best,9"

vim.opt.listchars:append({
    tab = "▏ ",
    trail = "·",
    nbsp = "␣",
})

vim.opt.guicursor = {
    "i-c-ci-ve:blinkoff500-blinkon500-block-TermCursor",
    "n-v:block-Cursor/lCursor",
    "o:hor50-Cursor/lCursor",
    "r-cr:hor20-Cursor/lCursor",
}

vim.opt.sessionoptions = {
    "buffers",
    "curdir",
    "folds",
    "globals",
    "help",
    "tabpages",
    "terminal",
    "winpos",
    "winsize",
}

-------------------------
---- GLOBAL OPTIONS ----
-------------------------

-- set to `true` to follow the main branch
-- you need to have a working rust toolchain to build the plugin
-- in this case.
vim.g.lazyvim_blink_main = true

-- LSP Server to use for Python.
-- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.lazyvim_python_lsp = "basedpyright"
-- Set to "ruff_lsp" to use the old LSP implementation version.
vim.g.lazyvim_python_ruff = "ruff"

-- LSP Server to use for Rust.
-- Set to "bacon-ls" to use bacon-ls instead of rust-analyzer.
-- only for diagnostics. The rest of LSP support will still be
-- provided by rust-analyzer.
vim.g.lazyvim_rust_diagnostics = "rust-analyzer"

-- Enable the option to require a Prettier config file
-- If no prettier config file is found, the formatter will not be used
vim.g.lazyvim_prettier_needs_config = false

-- In case you don't want to use `:LazyExtras`,
-- then you need to set the option below.
vim.g.lazyvim_picker = "snacks"
