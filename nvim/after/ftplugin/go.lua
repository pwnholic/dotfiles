vim.opt_local.expandtab = true

require("utils.lsp").start({
	filetypes = { "go", "gomod", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },
	message_level = vim.lsp.protocol.MessageType.Error,
	cmd = { vim.fn.stdpath("data") .. "/mason/bin/gopls", "-remote.debug=:0" },
	root_patterns = { "go.work", "go.mod", ".git" },
	flags = { allow_incremental_sync = true, debounce_text_changes = 500 },
	on_attach = function(client, _)
		if not client.server_capabilities.semanticTokensProvider then
			local semantic = client.config.capabilities.textDocument.semanticTokens
			client.server_capabilities.semanticTokensProvider = {
				full = true,
				legend = { tokenTypes = semantic.tokenTypes, tokenModifiers = semantic.tokenModifiers },
				range = true,
			}
		end
	end,
	settings = {
		gopls = {
			analyses = {
				append = true,
				asmdecl = true,
				assign = true,
				atomic = true,
				unreachable = true,
				nilness = true,
				ST1003 = true,
				undeclaredname = true,
				fillreturns = true,
				nonewvars = true,
				fieldalignment = true,
				shadow = true,
				unusedvariable = true,
				unusedparams = true,
				useany = true,
				unusedwrite = true,
			},
			codelenses = {
				generate = true, -- show the `go generate` lens.
				gc_details = true, -- Show a code lens toggling the display of gc's choices.
				test = true,
				tidy = true,
				vendor = true,
				regenerate_cgo = true,
				upgrade_dependency = true,
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
			usePlaceholders = true,
			completeUnimported = true,
			staticcheck = true,
			matcher = "Fuzzy",
			diagnosticsDelay = "1s",
			diagnosticsTrigger = "200ms",
			symbolMatcher = "FastFuzzy",
			semanticTokens = true,
			noSemanticString = true, -- disable semantic string tokens so we can use treesitter highlight injection
			vulncheck = "Imports",
			gofumpt = false,
			buildFlags = { "-tags", "integration" },
		},
	},
})
