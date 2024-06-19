require("utils.lsp").start({
	cmd = { "phpactor", "language-server" },
	root_patterns = { "composer.json", ".git", ".phpactor.json", ".phpactor.yml" },
	on_attach = function(client, _)
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
	end or nil,
	init_options = {
		["composer.enable"] = true,
		["language_server_php_cs_fixer.enabled"] = true,
		["worse_reflection.enable_cache"] = true,
		["file_path_resolver.enable_cache"] = true,
	},
})
