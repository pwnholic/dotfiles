require("utils.lsp").start({
	cmd = { "csharp-ls" },
	name = "csharp_ls",
	init_options = { AutomaticWorkspaceInit = true },
	root_patterns = { "*.sln", "*.csproj" },
	on_attach = function(client, _)
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
	end,
})
