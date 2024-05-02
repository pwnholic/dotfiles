vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.g.loaded_2html_plugin = 0
vim.g.loaded_gzip = 0
vim.g.loaded_matchit = 0
vim.g.loaded_tar = 0
vim.g.loaded_tarPlugin = 0
vim.g.loaded_tutor_mode_plugin = 0
vim.g.loaded_zip = 0
vim.g.loaded_zipPlugin = 0

vim.env.PATH = vim.fn.stdpath("data")
	.. "/mason/bin"
	.. (vim.uv.os_uname().sysname == "Windows_NT" and ";" or ":")
	.. vim.env.PATH

require("core.options")
require("core.package")

vim.api.nvim_create_autocmd("User", {
	group = vim.api.nvim_create_augroup("OnMales", { clear = true }),
	pattern = "VeryLazy",
	callback = function()
		require("utils.root").setup()
		require("core.autocmds")
		require("core.keymaps")
		require("core.commands")
	end,
})

