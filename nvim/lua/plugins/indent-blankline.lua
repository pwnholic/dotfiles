return {
	"lukas-reineke/indent-blankline.nvim",
	event = "BufRead",
	main = "ibl",
	opts = function()
		return {
			indent = { char = "▏", tab_char = "▏", smart_indent_cap = true },
			debounce = 200,
			scope = {
				show_exact_scope = false,
				priority = 500,
				show_start = true,
				show_end = false,
				highlight = {
					"@markup.heading.1.markdown",
					"@markup.heading.2.markdown",
					"@markup.heading.3.markdown",
					"@markup.heading.4.markdown",
					"@markup.heading.5.markdown",
					"@markup.heading.6.markdown",
				},
			},
			exclude = {
				filetypes = {
					"help",
					"dashboard",
					"Trouble",
					"trouble",
					"lazy",
					"mason",
					"notify",
					"toggleterm",
					"lazyterm",
				},
			},
		}
	end,
	config = function(_, opts)
		local hooks = require("ibl.hooks")
		hooks.register(hooks.type.ACTIVE, function(bufnr)
			return vim.api.nvim_buf_line_count(bufnr) < 5000
		end)
		require("ibl").setup(opts)
	end,
}
