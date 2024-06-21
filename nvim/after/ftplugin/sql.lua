require("utils.lsp").start({
	cmd = { "sqls" },
	filetypes = { "sql", "mysql" },
})

local ok, cmp = pcall(require, "cmp")
if not ok then
	return
end

cmp.setup.filetype({ "sql", "mysql" }, {
	sources = { { name = "nvim_lsp" }, { name = "vim-dadbod-completion" } },
})
