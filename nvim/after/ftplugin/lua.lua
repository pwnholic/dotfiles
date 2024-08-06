require("utils.lsp").start({
	cmd = { "lua-language-server" },
	name = "lua_lsp",
	root_patterns = { ".luarc.json", ".luarc.jsonc", "stylua.toml", ".stylua.toml" },
	settings = {
		Lua = {
			codeLens = { enable = true },
			completion = { callSnippet = "Replace" },
			doc = { privateName = { "^_" } },
			runtime = { version = "LuaJIT" },
			workspace = {
				checkThirdParty = false,
				library = { vim.env.VIMRUNTIME .. "/lua" },
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
