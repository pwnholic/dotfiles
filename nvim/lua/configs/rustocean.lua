local M = {}

function M.setup()
	vim.g.rustaceanvim = {
		tools = { hover_actions = { replace_builtin_hover = false } },
		server = {
			on_attach = function(client, bufnr)
				return require("lsp-default").on_attach(client, bufnr)
			end,
			settings = {
				["rust-analyzer"] = {
					imports = { prefix = "self", granularity = { group = "module" } },
					cargo = { allFeatures = true, loadOutDirsFromCheck = true, runBuildScripts = true },
					checkOnSave = { allFeatures = true, command = "clippy", extraArgs = { "--no-deps" } },
					inlayHints = {
						bindingModeHints = { enable = true },
						closureReturnTypeHints = { enable = "always" },
						discriminantHints = { enable = "always" },
						parameterHints = { enable = true },
					},
					diagnostics = { disabled = { "inactive-code", "unresolved-proc-macro" } },
					files = {
						excludeDirs = {
							".direnv",
							"target",
							"js",
							"node_modules",
							"assets",
							"ci",
							"data",
							"docs",
							"store-metadata",
							".gitlab",
							".vscode",
							".git",
						},
					},
					procMacro = {
						enable = true,
						ignored = {
							["async-trait"] = { "async_trait" },
							["napi-derive"] = { "napi" },
							["async-recursion"] = { "async_recursion" },
						},
					},
				},
			},
		},
		dap = {
			adapter = function()
				local ok, mason_registry = pcall(require, "mason-registry")
				local adapter
				if ok then
					local codelldb = mason_registry.get_package("codelldb")
					local extension_path = codelldb:get_install_path() .. "/extension/"
					local codelldb_path = extension_path .. "adapter/codelldb"
					local liblldb_path = ""
					if vim.uv.os_uname().sysname:find("Windows") then
						liblldb_path = extension_path .. "lldb\\bin\\liblldb.dll"
					elseif vim.fn.has("mac") == 1 then
						liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"
					else
						liblldb_path = extension_path .. "lldb/lib/liblldb.so"
					end
					adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb_path, liblldb_path)
				end
				return adapter
			end,
		},
	}
end

return M
