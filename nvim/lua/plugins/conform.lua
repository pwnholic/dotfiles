return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	cmd = "ConformInfo",
	init = function()
		vim.opt.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
	opts = function()
		return {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_format" },
				go = { "goimports" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				cs = { "clang_format" },
				typescript = { "prettier" },
				json = { "prettier" },
				javascript = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				markdown = { "prettier" },
				sql = { "sqlfluff" },
			},
			format_after_save = { lsp_format = "fallback" },
			formatters = {
				sqlfluff = {
					args = { "format", "--dialect=ansi", "-" },
				},
			},
		}
	end,
}
