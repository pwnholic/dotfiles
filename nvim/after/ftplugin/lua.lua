require("utils.lsp").start({
	cmd = { vim.fn.stdpath("data") .. "/mason/bin/lua-language-server" },
	name = "lua_ls",
	root_patterns = { ".luarc.json", ".luarc.jsonc", "stylua.toml", ".stylua.toml" },
	on_attach = function(client, _)
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
	end,
	settings = {
		Lua = {
			codeLens = { enable = true },
			completion = { callSnippet = "Replace" },
			doc = { privateName = { "^_" } },
			runtime = { version = "LuaJIT" },
			workspace = {
				checkThirdParty = false,
				library = { vim.env.VIMRUNTIME .. "/lua", vim.fn.stdpath("data") .. "/lazy/lazy.nvim" },
			},
			hint = {
				enable = true,
				setType = false,
				paramType = true,
				paramName = "Disable",
				semicolon = "Disable",
				arrayIndex = "Disable",
			},
		},
	},
})
