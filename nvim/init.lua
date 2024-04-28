vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

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
