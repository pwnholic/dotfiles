-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.lazyvim_picker = "fzf"

vim.opt.cmdheight = 0
vim.opt.shell = "/usr/bin/fish"
vim.opt.guicursor = {
	"i-c-ci-ve:blinkoff500-blinkon500-block-TermCursor",
	"n-v:block-Cursor/lCursor",
	"o:hor50-Cursor/lCursor",
	"r-cr:hor20-Cursor/lCursor",
}
