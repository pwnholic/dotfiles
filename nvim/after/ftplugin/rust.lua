require("utils.lsp").start({
	cmd = { vim.fn.stdpath("data") .. "/mason/bin/rust-analyzer" },
	name = "rust-analyzer",
	root_patterns = { "Cargo.toml", "rust-project.json" },
	settings = {
		["rust-analyzer"] = {
			cargo = {
				allFeatures = true,
				loadOutDirsFromCheck = true,
				buildScripts = {
					enable = true,
				},
			},
			checkOnSave = true,
			procMacro = {
				enable = true,
				ignored = {
					["async-trait"] = { "async_trait" },
					["napi-derive"] = { "napi" },
					["async-recursion"] = { "async_recursion" },
				},
			},
			imports = {
				prefix = "self",
				granularity = { group = "module" },
			},
		},
	},
	capabilities = {
		experimental = {
			serverStatusNotification = true,
		},
	},
})
