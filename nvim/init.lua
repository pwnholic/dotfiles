vim.loader.enable()

vim.g.loaded_2html_plugin = 0
vim.g.loaded_gzip = 0
vim.g.loaded_matchit = 0
vim.g.loaded_tar = 0
vim.g.loaded_tarPlugin = 0
vim.g.loaded_tutor_mode_plugin = 0
vim.g.loaded_zip = 0
vim.g.loaded_zipPlugin = 0

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
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

require("options")

vim.env.PATH = vim.fn.stdpath("data")
	.. "/mason/bin"
	.. (vim.uv.os_uname().sysname == "Windows_NT" and ";" or ":")
	.. vim.env.PATH

require("lazy").setup({
	root = vim.fn.stdpath("data") .. "/lazy",
	defaults = { lazy = false, version = false },
	spec = { import = "plugins" },
	local_spec = true,
	lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
	install = { missing = true, colorscheme = { "tokyonight" } },
	checker = {
		enabled = true,
		concurrency = 10,
		notify = true,
		frequency = 3600,
		check_pinned = false,
	},
	change_detection = {
		enabled = true,
		notify = false, -- get a notification when changes are found
	},
	performance = {
		cache = { enabled = true },
		reset_packpath = true, -- reset the package path to improve startup time
		rtp = {
			reset = true,
			paths = {},
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

local group = vim.api.nvim_create_augroup("OnMales", { clear = true })
vim.api.nvim_create_autocmd("User", {
	group = group,
	pattern = "VeryLazy",
	callback = function()
		package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.4/?.lua"
		package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.4/?/init.lua"
		package.cpath = package.cpath .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/lib/lua/5.4/?.so"

		require("utils.diagnostic")
		require("keybindings")
		require("autocmds")
	end,
})
