require("typescript-tools").setup({
	on_attach = function(client, bufnr)
		require("utils.lsp.default").on_attach(client, bufnr)
	end,
	settings = {
		separate_diagnostic_server = true,
		publish_diagnostic_on = "insert_leave",
		expose_as_code_action = "all",
		tsserver_path = vim.fn.stdpath("data")
			.. "/mason/packages/typescript-language-server/node_modules/typescript/lib/tsserver.js",
		tsserver_max_memory = "auto",
		-- https://github.com/microsoft/TypeScript/blob/v5.0.4/src/server/protocol.ts#L3418
		tsserver_format_options = {
			insertSpaceAfterTypeAssertion = true,
			insertSpaceAfterCommaDelimiter = true,
		},

		-- https://github.com/microsoft/TypeScript/blob/v5.0.4/src/server/protocol.ts#L3439
		tsserver_file_preferences = {
			includeInlayParameterNameHints = "all",
			includeCompletionsForModuleExports = true,
			quotePreference = "auto",
			allowRenameOfImportPath = true,
			displayPartsForJSDoc = true,
		},
		tsserver_locale = "en",
		complete_function_calls = false,
		include_completions_with_insert_text = true,
		code_lens = "all",
		disable_member_code_lens = false,
		jsx_close_tag = { enable = false },
	},
})
