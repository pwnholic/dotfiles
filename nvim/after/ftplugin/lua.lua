require("utils.lsp").start({
	cmd = { "lua-language-server" },
	name = "lua_ls",
	root_patterns = { ".luarc.json", ".luarc.jsonc", "stylua.toml", ".stylua.toml", ".git" },
	on_attach = function(client, _)
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
	end or nil,
	settings = {
		Lua = {
			runtime = {
				version = "Lua 5.4.6",
				path = {
					"?.lua",
					"?/init.lua",
					vim.fn.expand("~/.luarocks/share/lua/5.4/?.lua"),
					vim.fn.expand("~/.luarocks/share/lua/5.4/?/init.lua"),
					"/usr/share/5.4/?.lua",
					"/usr/share/lua/5.4/?/init.lua",
				},
			},
			workspace = {
				library = {
					vim.fn.expand("~/.luarocks/share/lua/5.4"),
					"/usr/share/lua/5.4",
					"/usr/share/nvim/runtime/lua/",
				},
			},
			codeLens = {
				enable = true,
			},
			completion = {
				callSnippet = "Replace",
			},
			doc = {
				privateName = { "^_" },
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
