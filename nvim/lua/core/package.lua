local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.uv).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	root = vim.fn.stdpath("data") .. "/lazy",
	defaults = { lazy = true, version = "*" },
	spec = require("core.plugins"),
	concurrency = 10,
	install = { missing = true, colorscheme = { "tokyonight" } },
	ui = {
		size = { width = 0.8, height = 0.8 },
		wrap = true, -- wrap the lines in the ui
		border = "rounded",
		backdrop = 60,
		pills = true, ---@type boolean
		ui = { icons = { ft = " ", lazy = "󰂠 ", loaded = " ", not_loaded = " " } },
		throttle = 20,
	},
	diff = { cmd = "git" },
	checker = { enabled = true, concurrency = 10, notify = false, frequency = 3600 * 24 * 7 },
	change_detection = { enabled = true, notify = false },
	performance = {
		cache = { enabled = true },
		reset_packpath = true, -- reset the package path to improve startup time
	},
})
