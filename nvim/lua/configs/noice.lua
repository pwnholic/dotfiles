require("noice").setup({
	cmdline = { view = "cmdline" },
	popupmenu = { enabled = false },
	lsp = {
		signature = {
			enabled = true,
			auto_open = { enabled = true, trigger = true, luasnip = true, throttle = 100 },
			view = "hover",
			opts = {
				win_options = {
					concealcursor = vim.wo.concealcursor,
					conceallevel = vim.wo.conceallevel,
					wrap = true,
				},
				position = { row = 2, col = 0 },
			},
		},
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true,
		},
		documentation = {
			view = "hover",
			opts = {
				lang = "markdown",
				replace = true,
				render = "plain",
				format = { "{message}" },
				win_options = {
					concealcursor = vim.wo.concealcursor,
					conceallevel = vim.wo.conceallevel,
				},
			},
		},
	},
	markdown = {
		highlights = {
			["|%S-|"] = "@text.reference",
			["@%S+"] = "@parameter",
			["^%s*(Parameters:)"] = "@text.title",
			["^%s*(Return:)"] = "@text.title",
			["^%s*(See also:)"] = "@text.title",
			["{%S-}"] = "@parameter",
		},
	},
	routes = {
		{
			filter = {
				event = "msg_show",
				any = {
					{ find = "%d+L, %d+B" },
					{ find = "; after #%d+" },
					{ find = "; before #%d+" },
				},
			},
			view = "mini",
		},
	},
	views = {
		popup = {
			border = { style = vim.g.border },
			padding = { 0, 0 },
			size = { max_width = 80, max_height = 15 },
		},
		hover = {
			border = { style = vim.g.border },
			padding = { 0, 0 },
			win_options = {
				concealcursor = vim.wo.concealcursor,
				conceallevel = vim.wo.conceallevel,
				wrap = true,
				linebreak = true,
			},
			position = { row = 2, col = 0 },
			lang = "markdown",
			size = { max_width = 80, max_height = 13 },
		},
	},
	smart_move = { enabled = true, excluded_filetypes = { "cmp_menu", "cmp_docs", "notify" } },
	presets = {
		bottom_search = true,
		command_palette = true,
		long_message_to_split = true,
		inc_rename = true,
		lsp_doc_border = true,
	},
})

vim.keymap.set({ "n", "s" }, "<c-f>", function()
	if not require("noice.lsp").scroll(4) then
		return "<c-f>"
	end
end, { silent = true, expr = true })
vim.keymap.set({ "n", "s" }, "<c-b>", function()
	if not require("noice.lsp").scroll(-4) then
		return "<c-b>"
	end
end, { silent = true, expr = true })
