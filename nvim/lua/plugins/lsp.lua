local icons = require("utils.icons")
local function disabled_formater(client, _)
	client.server_capabilities.documentFormattingProvider = false
	client.server_capabilities.documentRangeFormattingProvider = false
end

return {
	{
		"neovim/nvim-lspconfig",
		event = "LazyFile",
		opts = {
			diagnostics = {
				underline = true,
				update_in_insert = false,
				severity_sort = true,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
						[vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
						[vim.diagnostic.severity.INFO] = icons.diagnostics.Hint,
						[vim.diagnostic.severity.HINT] = icons.diagnostics.Info,
					},
					numhl = {
						[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
						[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
						[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
						[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
					},
				},
				virtual_text = {
					spacing = 4,
					source = "if_many",
					prefix = "",
					format = function(d)
						local dicons = {}
						for key, value in pairs(icons.diagnostics) do
							dicons[key:upper()] = value
						end
						return string.format(" %s : %s ", dicons[vim.diagnostic.severity[d.severity]], d.message)
					end,
				},
				float = {
					header = setmetatable({}, {
						__index = function(_, k)
							local icon, hl = require("mini.icons").get("file", vim.api.nvim_buf_get_name(0))
							local arr = {
								function()
									return string.format("Diagnostics: %s  %s", icon, vim.bo.filetype)
								end,
								function()
									return hl
								end,
							}
							return arr[k]()
						end,
					}),
					format = function(d)
						return string.format("[%s] : %s", d.source, d.message)
					end,
					source = "if_many",
					severity_sort = true,
					wrap = true,
					border = "single",
					max_width = math.floor(vim.o.columns / 2),
					max_height = math.floor(vim.o.lines / 3),
				},
			},
			-- Enable this to enable the builtin LSP inlay hints on Neovim >= 0.10.0
			-- Be aware that you also will need to properly configure your LSP server to
			-- provide the inlay hints.
			inlay_hints = {
				enabled = false,
				exclude = { "vue" }, -- filetypes for which you don't want to enable inlay hints
			},
			-- Enable this to enable the builtin LSP code lenses on Neovim >= 0.10.0
			-- Be aware that you also will need to properly configure your LSP server to
			-- provide the code lenses.
			codelens = {
				enabled = true,
			},
			-- Enable lsp cursor word highlighting
			document_highlight = {
				enabled = true,
			},
			-- add any global capabilities here
			capabilities = {
				workspace = {
					fileOperations = {
						didRename = true,
						willRename = true,
					},
				},
			},
			-- options for vim.lsp.buf.format
			-- `bufnr` and `filter` is handled by the LazyVim formatter,
			-- but can be also overridden when specified
			format = {
				formatting_options = nil,
				timeout_ms = nil,
			},
			servers = {
				sqls = {
					on_attach = disabled_formater,
				},
				jsonls = {
					on_attach = disabled_formater,
				},
				marksman = {
					on_attach = disabled_formater,
				},

				solidity_ls = {},
				lua_ls = {
					settings = {
						Lua = {
							workspace = {
								checkThirdParty = false,
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
				},
			},
			setup = {},
		},
	},
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		opts = {
			ensure_installed = {
				"stylua",
				"shfmt",
				"sqls",
				"jq",
				"vscode-solidity-server",
			},
		},
	},
}
