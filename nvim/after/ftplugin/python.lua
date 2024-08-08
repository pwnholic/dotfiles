require("utils.lsp").start({
	cmd = { vim.fn.stdpath("data") .. "/mason/bin/basedpyright-langserver", "--stdio" },
	name = "basedpyright",
	root_patterns = { "Pipfile", "pyproject.toml", "requirements.txt", "setup.cfg", "setup.py" },
	on_attach = function(client, _)
		client.server_capabilities.documentFormattingProvider = false
	end,
	settings = {
		basedpyright = {
			analysis = {
				typeCheckingMode = "off",
				autoImportCompletions = true,
				diagnosticMode = "openFilesOnly",
			},
		},
	},
})
