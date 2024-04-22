local ls = require("luasnip")
local ls_type = require("luasnip.util.types")

ls.setup({
	region_check_events = "CursorMoved,CursorMovedI",
	delete_check_events = "TextChanged,TextChangedI",
	enable_autosnippets = true,
	ext_base_prio = 300,
	ft_func = require("luasnip.extras.filetype_functions").from_cursor_pos,
	store_selection_keys = "<Tab>",
	ext_opts = {
		[ls_type.choiceNode] = { active = { virt_text = { { "│", "DashboardKey" } } } },
		[ls_type.insertNode] = {
			unvisited = { virt_text = { { "│", "Comment" } }, virt_text_pos = "inline" },
		},
		[ls_type.exitNode] = {
			unvisited = { virt_text = { { "│", "Comment" } }, virt_text_pos = "inline" },
		},
	},
})

local paths = vim.fn.stdpath("config") .. "/snippets" --[[@as string]]
require("luasnip.loaders.from_vscode").lazy_load({ paths = paths })

vim.api.nvim_create_autocmd("InsertLeave", {
	group = vim.api.nvim_create_augroup("Unlink_Snippet", { clear = true }),
	desc = "Cancel the snippet session when leaving insert mode",
	pattern = { "s:n", "i:*" },
	callback = function(args)
		if
			ls.session
			and ls.session.current_nodes[args.buf]
			and not ls.session.jump_active
			and not ls.choice_active()
		then
			ls.unlink_current()
		end
	end,
})
