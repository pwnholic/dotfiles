vim.opt_local.expandtab = true

local lsp = require("utils.lsp")

lsp.start({
	filetypes = { "go", "gomod", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },
	cmd = { vim.fn.stdpath("data") .. "/mason/bin/gopls", "-remote.debug=:0" },
	name = "gopls",
	root_patterns = { "go.work", "go.mod" },
	flags = { allow_incremental_sync = true, debounce_text_changes = 500 },
	settings = {
		gopls = {
			gofumpt = false,
			codelenses = {
				gc_details = true,
				generate = true,
				regenerate_cgo = true,
				run_govulncheck = true,
				test = true,
				tidy = true,
				upgrade_dependency = true,
				vendor = true,
			},
			hints = {
				assignVariableTypes = true,
				compositeLiteralFields = true,
				compositeLiteralTypes = true,
				constantValues = true,
				functionTypeParameters = true,
				parameterNames = true,
				rangeVariableTypes = true,
			},
			analyses = {
				fieldalignment = true,
				nilness = true,
				unusedparams = true,
				unusedwrite = true,
				useany = true,
			},
			usePlaceholders = true,
			completeUnimported = true,
			staticcheck = true,
			directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
			semanticTokens = true,
		},
	},
})

lsp.on_attach(function(client, _)
	if not client.server_capabilities.semanticTokensProvider then
		local semantic = client.config.capabilities.textDocument.semanticTokens or {}
		client.server_capabilities.semanticTokensProvider = {
			full = true,
			legend = { tokenTypes = semantic.tokenTypes, tokenModifiers = semantic.tokenModifiers },
			range = true,
		}
	end
end, "gopls")
