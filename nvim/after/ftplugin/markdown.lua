vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.signcolumn = "no"
vim.opt_local.stc = nil
vim.opt_local.list = true
vim.opt_local.listchars = { tab = "  ", trail = "·" }

require("utils.lsp").start({
	cmd = { vim.fn.stdpath("data") .. "/mason/bin/marksman", "server" },
	name = "marksman",
	root_patterns = { ".git", ".marksman.toml" },
	single_file_support = true,
})
