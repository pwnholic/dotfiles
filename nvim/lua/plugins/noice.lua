return {
	"folke/noice.nvim",
	event = "VeryLazy",
	keys = {
		{
			"<c-f>",
			function()
				if not require("noice.lsp").scroll(4) then
					return "<c-f>"
				end
			end,
			silent = true,
			expr = true,
			desc = "Scroll Forward",
			mode = { "i", "n", "s" },
		},
		{
			"<c-b>",
			function()
				if not require("noice.lsp").scroll(-4) then
					return "<c-b>"
				end
			end,
			silent = true,
			expr = true,
			desc = "Scroll Backward",
			mode = { "i", "n", "s" },
		},
	},
	opts = function()
		return {
			cmdline = { enabled = true, view = "cmdline", format = { input = { view = "cmdline" } } },
			notify = { enabled = true, view = "notify" },
			popupmenu = { enabled = true, backend = "cmp" },
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
				hover = { enabled = true, opts = {} },
				signature = {
					enabled = true,
					auto_open = { enabled = true, trigger = true, luasnip = true, throttle = 50 },
					opts = {},
				},
				documentation = {
					view = "hover",
					opts = {
						lang = "markdown",
						replace = true,
						render = "plain",
						format = { "{message}" },
						win_options = { concealcursor = "n", conceallevel = 3 },
					},
				},
			},
			markdown = {
				hover = { ["|(%S-)|"] = vim.cmd.help, ["%[.-%]%((%S-)%)"] = require("noice.util").open },
				highlights = {
					["|%S-|"] = "@text.reference",
					["@%S+"] = "@parameter",
					["^%s*(Parameters:)"] = "@text.title",
					["^%s*(Return:)"] = "@text.title",
					["^%s*(See also:)"] = "@text.title",
					["{%S-}"] = "@parameter",
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				lsp_doc_border = false,
			},
			routes = {
				{
					filter = {
						event = "msg_show",
						any = { { find = "%d+L, %d+B" }, { find = "; after #%d+" }, { find = "; before #%d+" } },
					},
					view = "mini",
				},
			},
		}
	end,
}
