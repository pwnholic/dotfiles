local ibl, hooks = require("ibl"), require("ibl.hooks")
ibl.setup({
	indent = { char = "▏", tab_char = "▏" },
	scope = {
		enabled = true,
		show_exact_scope = false,
		highlight = {
			"RainbowDelimiterRed",
			"RainbowDelimiterYellow",
			"RainbowDelimiterBlue",
			"RainbowDelimiterOrange",
			"RainbowDelimiterGreen",
			"RainbowDelimiterViolet",
			"RainbowDelimiterCyan",
		},
	},
	exclude = {
		filetypes = { "help", "dashboard", "Trouble", "lazy", "mason", "notify", "toggleterm", "oil" },
	},
})
hooks.register(hooks.type.ACTIVE, function(bufnr)
	return vim.api.nvim_buf_line_count(bufnr) < 5000
end)
