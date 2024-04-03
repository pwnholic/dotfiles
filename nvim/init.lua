vim.loader.enable()

local lazy_path, config_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim", vim.fn.stdpath("config") --[[@as string]]

vim.opt.rtp:prepend(lazy_path)

require("options")

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

require("lazy").setup({
	{ import = "plugins" },
	{
		name = "autocmds",
		main = "autocmds",
		dir = config_path,
		event = "VeryLazy",
		config = true,
	},
	{
		name = "keymaps",
		main = "keymaps",
		dir = config_path,
		event = "VeryLazy",
		config = true,
	},
	{
		name = "tmux",
		main = "tmux",
		dir = config_path,
		event = "BufRead",
		config = true,
	},
	{
		name = "buffer",
		main = "buffer",
		dir = config_path,
		event = "BufRead",
		config = true,
	},
}, {
	defaults = {
		lazy = true,
		version = "*",
	},
	install = {
		missing = true,
		colorscheme = { "tokyonight" },
	},
	change_detection = {
		enabled = true,
		notify = false,
	},
	checker = {
		enabled = true,
		notify = false,
		frequency = (3600 * 24) * 7,
	},
	diff = { cmd = "diffview.nvim" },
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
})

vim.env.PATH = vim.fn.stdpath("data")
	.. "/mason/bin"
	.. (vim.uv.os_uname().sysname == "Windows_NT" and ";" or ":")
	.. vim.env.PATH
