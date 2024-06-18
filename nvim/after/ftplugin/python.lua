require("utils.lsp").start({
	cmd = { "basedpyright-langserver", "--stdio" },
	name = "pyright",
	root_patterns = vim.list_extend({ "pyrightconfig.json" }, {
		"Pipfile",
		"pyproject.toml",
		"requirements.txt",
		"setup.cfg",
		"setup.py",
	}),
	on_attach = function(client, _)
		client.server_capabilities.documentFormattingProvider = false
	end,
	settings = {
		python = {
			analysis = {
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
				diagnosticMode = "openFilesOnly",
			},
		},
	},
})
