vim.api.nvim_create_autocmd({ "LspAttach", "DiagnosticChanged" }, {
	once = true,
	desc = "Apply lsp and diagnostic settings.",
	group = vim.api.nvim_create_augroup("LspDiagnosticSetup", {}),
	callback = function()
		require("utils.lsp.commands").setup()
		return true
	end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufWinEnter", "BufEnter" }, {
	group = vim.api.nvim_create_augroup("BufAutoCloser", {}),
	pattern = "*",
	callback = function()
		require("utils.bufcloser")
		return true
	end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
	once = true,
	group = vim.api.nvim_create_augroup("SmartExpandtabSetup", {}),
	callback = function()
		require("utils.expand-tab")
		return true
	end,
})

vim.schedule(function()
	require("utils.diag-conf")
	require("utils.tmux").setup()
end)