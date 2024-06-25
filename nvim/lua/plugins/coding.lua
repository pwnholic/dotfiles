return {
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
		opts = {
			format_after_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
			formatters_by_ft = {
				lua = { "stylua" },
				go = { "goimports", "gofmt" },
				php = { "php_cs_fixer" },
				markdown = { "prettier" },
				yaml = { "prettier" },
				sql = { "sqlfluff" },
				mysql = { "sqlfluff" },
				-- solidity = { "forge" },
				javascript = { { "prettierd", "prettier" } },
				python = function(bufnr)
					if require("conform").get_formatter_info("ruff_format", bufnr).available then
						return { "ruff_format" }
					else
						return { "isort", "black" }
					end
				end,
				["_"] = { "trim_whitespace" },
			},
			formatters = {
				sqlfluff = {
					args = { "format", "--dialect=ansi", "-" },
				},
				-- forge = {
				-- 	command = "forge",
				-- 	args = { "fmt", "$FILENAME" },
				-- },
			},
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
				"vtsls",
				"prettier",
				"vscode-solidity-server",
				"basedpyright",
				"black",
				"rust-analyzer",
				"clangd",
				"marksman",
				"phpactor",
				"php-cs-fixer",
				"sqls",
				"sqlfluff",
			},
		},
		---@param opts MasonSettings | {ensure_installed: string[]}
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")
			mr:on("package:install:success", function()
				vim.defer_fn(function()
					-- trigger FileType event to possibly load this newly installed LSP server
					require("lazy.core.handler.event").trigger({
						event = "FileType",
						buf = vim.api.nvim_get_current_buf(),
					})
				end, 100)
			end)

			mr.refresh(function()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end)
		end,
	},
	{
		"folke/ts-comments.nvim",
		event = "VeryLazy",
		opts = {},
	},
	{
		"RRethy/vim-illuminate",
		keys = { "]]", "[[" },
		event = "BufReadPost",
		config = function()
			local ill = require("illuminate")
			ill.configure({
				providers = { "lsp", "treesitter", "regex" },
				delay = 0,
				filetypes_denylist = {
					"harpoon",
					"dashboard",
					"fzf",
					"lazy",
					"lazyterm",
					"netrw",
					"neotest--summary",
					"Trouble",
					"oil",
				},
				large_file_cutoff = 2000,
				case_insensitive_regex = false,
				modes_denylist = { "i", "ic", "ix", "v", "vs", "V", "Vs", "CTRL-V", "CTRL-Vs", "\22" },
			})

			vim.keymap.set("n", "]]", function()
				ill.goto_next_reference(false)
			end, { desc = "Next Reference" })
			vim.keymap.set("n", "[[", function()
				ill.goto_prev_reference(false)
			end, { desc = "Prev Reference" })
		end,
	},
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = { "tpope/vim-dadbod", lazy = true },
		cmd = "DBUI",
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
		end,
	},
}
