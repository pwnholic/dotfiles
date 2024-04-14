vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local lazy_path, cfg_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim", vim.fn.stdpath("config") --[[@as string]]
vim.opt.rtp:prepend(lazy_path)

vim.env.PATH = vim.fn.stdpath("data")
	.. "/mason/bin"
	.. (vim.uv.os_uname().sysname == "Windows_NT" and ";" or ":")
	.. vim.env.PATH

if not vim.uv.fs_stat(lazy_path) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazy_path,
	})
end

local lazy_specs = {
	{ import = "plugins" },
	{ name = "options", main = "options", dir = cfg_path, event = "VimEnter", config = true },
	{ name = "autocmds", main = "autocmds", dir = cfg_path, event = "VeryLazy", config = true },
	{ name = "keymaps", main = "keymaps", dir = cfg_path, event = "VeryLazy", config = true },
	{ name = "tmux", main = "tmux", dir = cfg_path, event = "BufRead", config = true },
	{ name = "buffer", main = "buffer", dir = cfg_path, event = "BufRead", config = true },
}

local lazy_opts = {
	defaults = { lazy = true, version = "*" },
	install = { missing = true, colorscheme = { "tokyonight" } },
	change_detection = { enabled = true, notify = false },
	checker = { enabled = true, notify = false, frequency = (3600 * 24) * 7 },
	ui = { border = "single" },
	performance = {
		cache = { enabled = true },
		reset_packpath = true,
		rtp = {
			reset = true,
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
}

require("lazy").setup(lazy_specs, lazy_opts)
