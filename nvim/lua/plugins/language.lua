return {
	{
		"ray-x/go.nvim",
		ft = { "go", "gomod" },
		branch = "master",
		dependencies = { "ray-x/guihua.lua", build = "cd lua/fzy && make", branch = "master" },
		opts = {
			disables = false,
			go = "go",
			goimport = "goimports",
			fillstruct = "gopls",
			gofmt = false,
			tag_transform = false,
			tag_options = "",
			icons = false,
			verbose = false,
			lsp_gofumpt = false,
			lsp_keymaps = false,
			lsp_inlay_hints = { enable = false },
			sign_priority = 5,
			textobjects = false,
			trouble = true,
			test_efm = false,
			luasnip = true,
			iferr_vertical_shift = 4,
			dap_debug = true,
			diagnostic = require("utils").diagnostic_conf,
			dap_debug_keymap = false,
			dap_debug_vt = { enabled_commands = true, all_frames = true },
			dap_port = 38697,
			dap_timeout = 15,
			dap_retries = 20,
			dap_debug_gui = {
				floating = { border = "solid" },
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.2 },
							{ id = "breakpoints", size = 0.2 },
							{ id = "stacks", size = 0.2 },
							{ id = "watches", size = 0.2 },
							{ id = "console", size = 0.2 },
						},
						position = "right",
						size = 55,
					},
					{
						elements = { { id = "repl", size = 1 } },
						position = "bottom",
						size = 8,
					},
				},
			},
			lsp_on_attach = function(client, bufnr)
				require("lsp_default").default.on_attach(client, bufnr)
				if not client.server_capabilities.semanticTokensProvider then
					local semantic = client.config.capabilities.textDocument.semanticTokens
					client.server_capabilities.semanticTokensProvider = {
						full = true,
						legend = { tokenTypes = semantic.tokenTypes, tokenModifiers = semantic.tokenModifiers },
						range = true,
					}
				end
			end,
			lsp_cfg = {
				capabilities = require("lsp_default").capabilities,
				settings = {
					gopls = {
						gofumpt = false,
						codelenses = {
							gc_details = false,
							generate = true,
							regenerate_cgo = true,
							run_govulncheck = true,
							test = true,
							tidy = true,
							upgrade_dependency = true,
							vendor = true,
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
						analyses = {
							fieldalignment = true,
							nilness = true,
							unusedparams = true,
							unusedwrite = true,
							useany = true,
							unreachable = true,
							ST1003 = true,
							undeclaredname = true,
							fillreturns = true,
							nonewvars = true,
							shadow = true,
						},
						usePlaceholders = true,
						completeUnimported = true,
						staticcheck = true,
						directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
						semanticTokens = true,
						matcher = "Fuzzy",
						diagnosticsDelay = "500ms",
						symbolMatcher = "fuzzy",
						buildFlags = { "-tags", "integration" },
					},
				},
			},
		},
	},
	{
		"jakewvincent/mkdnflow.nvim",
		ft = "markdown",
		opts = {
			modules = { maps = false, cmp = true },
			filetypes = { md = true, rmd = true, markdown = true },
			create_dirs = false,
			perspective = {
				priority = "first",
				fallback = "current",
				root_tell = false,
				nvim_wd_heel = false,
				update = true,
			},
			wrap = true,
			silent = false,
			links = {
				style = "markdown",
				name_is_source = false,
				conceal = true,
				context = 0,
				transform_explicit = function()
					math.randomseed(os.time())
					local len = 7
					local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
					local name = ""
					for _ = 1, len do
						local ridx = math.random(1, #chars)
						name = string.format("%s%s", name, string.sub(chars, ridx, ridx))
					end
					if string.len(name) > len then
						string.lower(name:gsub(" ", "_"))
					end
					return string.format("%s_%s%s", os.date("%d%m%Y"), os.date("%S"), name)
				end,
			},
			to_do = {
				symbols = { " ", "-", "X" },
				update_parents = true,
				not_started = " ",
				in_progress = "-",
				complete = "X",
			},
			tables = {
				trim_whitespace = true,
				format_on_move = true,
				auto_extend_rows = true,
				auto_extend_cols = true,
				style = {
					cell_padding = 1,
					separator_padding = 1,
					outer_pipes = true,
					mimic_alignment = true,
				},
			},
		},
	},
	{
		"p00f/clangd_extensions.nvim",
		ft = { "c", "cpp" },
		opts = {
			inlay_hints = { inline = false },
			ast = {
				role_icons = {
					type = " ",
					declaration = " ",
					expression = " ",
					specifier = " ",
					statement = " ",
					["template argument"] = " ",
				},
				kind_icons = {
					Compound = " ",
					Recovery = " ",
					TranslationUnit = " ",
					PackExpansion = " ",
					TemplateTypeParm = " ",
					TemplateTemplateParm = " ",
					TemplateParamObject = " ",
				},
			},
		},
	},
	{
		"pmizio/typescript-tools.nvim",
		ft = { "javascript", "typescript" },
		opts = {
			on_attach = function(client, bufnr)
				require("lsp_default").default.on_attach(client, bufnr)
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
		},
	},
	{
		"mrcjkb/rustaceanvim",
		version = "^3",
		branch = "master",
		cmd = "RustLsp",
		ft = { "rust" },
		config = function()
			vim.g.rustaceanvim = {
				tools = { hover_actions = { replace_builtin_hover = false } },
				server = {
					on_attach = function(client, bufnr)
						return require("lsp_default").default.on_attach(client, bufnr)
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
		end,
	},
}
