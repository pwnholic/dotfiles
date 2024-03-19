return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		kyes = {
			"<leader>uf",
			{
				"=",
				function()
					require("conform").format({ async = true, lsp_fallback = true }, function(err)
						if not err then
							if vim.startswith(vim.api.nvim_get_mode().mode:lower(), "v") then
								vim.api.nvim_feedkeys(
									vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
									"n",
									true
								)
							end
						end
					end)
				end,
				mode = "",
				desc = "Format Range",
			},
		},
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
		opts = {
			log_level = vim.log.levels.TRACE,
			format_after_save = function(bufnr)
				if vim.b[bufnr].bigfile or vim.b[bufnr].midfile then
					return false
				end
				return { timeout_ms = 5000, lsp_fallback = true }
			end,
			notify_on_error = true,
			formatters = { injected = { options = { lang_to_formatters = { html = {}, json = { "jq" } } } } },
			formatters_by_ft = {
				lua = { "stylua" },
				go = { "goimports" },
				python = { "black" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				vue = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				less = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier", "injected" },
				["markdown.mdx"] = { "prettier" },
				graphql = { "prettier" },
				handlebars = { "prettier" },
				cpp = { "clang-format" },
				c = { "clang-format" },
				sql = { "sqlfmt" },
				mysql = { "sqlfmt" },
				["_"] = { "trim_whitespace", "trim_newlines" },
			},
		},
		config = function(_, opts)
			local conform = require("conform")
			local enabled = true
			vim.keymap.set("n", "<leader>uf", function()
				enabled = not enabled
				if enabled then
					vim.notify("Enabled Formatter", 2, { title = "Formatter" })
					return conform.setup(opts)
				else
					vim.notify("Disabled Formatter", 2, { title = "Formatter" })
					return conform.setup({ format_after_save = enabled })
				end
			end, { desc = "Toggle Formatter" })

			conform.setup(opts)
		end,
	},
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = {
			max_concurrent_installers = 15,
			PATH = "prepend",
			ensure_installed = {
				"codelldb",
				"debugpy",
				"delve",
				"node-debug2-adapter",

				"pyright",
				"gopls",
				"clangd",
				"lua-language-server",
				"rust-analyzer",
				"typescript-language-server",
				"phpactor",
				"nomicfoundation-solidity-language-server",
				"solidity",
				"htmx-lsp",
				"templ",
				"html-lsp",
				"css-lsp",
				"marksman",
				"sqlls",

				-- linter
				"solhint",
				"ruff",
				"selene",
				"phpcs",
				"phpstan",
				"php-cs-fixer",
				"cpplint",
				"vale",
				"biome",
				"eslint_d",
				"golangci-lint",
				"staticcheck",

				"black",
				"clang-format",
				"stylua",
				"prettier",
				"sqlfmt",
				"goimports",
				"goimports-reviser",
			},
		},
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")
			mr:on("package:install:success", function()
				vim.defer_fn(function()
					require("lazy.core.handler.event").trigger({
						event = "FileType",
						buf = vim.api.nvim_get_current_buf(),
					})
				end, 100)
			end)
			local function ensure_installed()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end
			if mr.refresh then
				mr.refresh(ensure_installed)
			else
				ensure_installed()
			end
		end,
	},
	{
		"neovim/nvim-lspconfig",
		event = "FileType",
		config = function()
			local lang_servers = {
				lua = "lua_ls",
				c = "clangd",
				cpp = "clangd",
				markdown = "marksman",
				rust = "rust-analyzer",
				solidity = "solidity_ls_nomicfoundation",
				php = "phpactor",
				templ = "templ",
				python = "pyright",
				-- html =  "html" ,
				-- css =  "css-lsp" ,
			}
			local server_conf = {
				solidity_ls_nomicfoundation = { name = "solidity_ls" },
				lua_ls = {
					settings = {
						Lua = {
							-- workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
							-- runtime = {
							-- 	version = "LuaJIT",
							-- 	path = vim.tbl_extend("force", vim.split(package.path, ";", {}), { "lua/?.lua", "lua/?/init.lua" }),
							-- },
							completion = { callsnippet = "replace" },
							diagnostics = { enable = true, globals = { "vim", "describe" } },
							hint = { enable = true },
							telemetry = { enable = false },
							format = { enable = false },
						},
					},
				},
			}

			local lsp_default = require("lsp_default").default
			local function create_lsp_config(opts)
				local config = server_conf[opts]
				if not config then
					config = vim.deepcopy(lsp_default)
				else
					config = vim.tbl_extend("force", lsp_default, config)
				end
				return config
			end

			local methods = vim.lsp.protocol.Methods
			local register_capability = vim.lsp.handlers[methods.client_registerCapability]
			vim.lsp.handlers[methods.client_registerCapability] = function(err, res, ctx)
				local ret = register_capability(err, res, ctx)
				local bufnr = vim.api.nvim_get_current_buf()
				if not vim.api.nvim_buf_is_valid(bufnr) then
					return
				end
				require("lsp_default").lsp_keymaps(vim.lsp.get_client_by_id(ctx.client_id), bufnr)
				return ret
			end

			local diagIcons = require("icons").diagnostics
			for name, icon in pairs(diagIcons) do
				name = "DiagnosticSign" .. name
				vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
			end

			vim.diagnostic.config({
				underline = true,
				update_in_insert = false,
				severity_sort = true,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = diagIcons.Error,
						[vim.diagnostic.severity.WARN] = diagIcons.Warn,
						[vim.diagnostic.severity.INFO] = diagIcons.Hint,
						[vim.diagnostic.severity.HINT] = diagIcons.Info,
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
						local icons = {}
						for key, value in pairs(diagIcons) do
							icons[key:upper()] = value
						end
						return string.format(" %s : %s ", icons[vim.diagnostic.severity[d.severity]], d.message)
					end,
				},
				float = {
					header = setmetatable({}, {
						__index = function(_, k)
							local icon, hl = require("nvim-web-devicons").get_icon_by_filetype(vim.bo.filetype)
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
			})

			local hide = vim.diagnostic.handlers.virtual_text.hide
			local show = vim.diagnostic.handlers.virtual_text.show
			vim.diagnostic.handlers.virtual_text = {
				show = function(ns, bufnr, diagnostics, opts)
					table.sort(diagnostics, function(diag1, diag2)
						return diag1.severity > diag2.severity
					end)
					return show(ns, bufnr, diagnostics, opts)
				end,
				hide = hide,
			}

			local ft_servers = {}
			for langs, sname in pairs(lang_servers) do
				ft_servers[langs] = sname
			end

			return vim.schedule(function()
				local function setup_ft(ft)
					local servers = ft_servers[ft]
					if not servers then
						return false
					end
					if type(servers) ~= "table" then
						servers = { servers }
					end
					for _, server in ipairs(servers) do
						require("lspconfig")[server].setup(create_lsp_config(server))
					end
					ft_servers[ft] = nil
					vim.api.nvim_exec_autocmds("FileType", { pattern = ft })
					return true
				end

				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					setup_ft(vim.bo[buf].ft)
				end

				for ft, _ in pairs(ft_servers) do
					vim.api.nvim_create_autocmd("FileType", {
						once = true,
						pattern = ft,
						group = vim.api.nvim_create_augroup("LspServerLazySetup", { clear = false }),
						callback = function()
							return setup_ft(ft)
						end,
					})
				end
			end)
		end,
	},
}
