local M = {}

function M.comment_setup()
	return require("Comment").setup({
		pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
		toggler = {
			---Line-comment toggle keymap
			line = "gcc",
			---Block-comment toggle keymap
			block = "gbc",
		},
		---LHS of operator-pending mappings in NORMAL and VISUAL mode
		opleader = {
			---Line-comment keymap
			line = "gc",
			---Block-comment keymap
			block = "gb",
		},
		---LHS of extra mappings
		extra = {
			---Add comment on the line above
			above = "gcO",
			---Add comment on the line below
			below = "gco",
			---Add comment at the end of line
			eol = "gcA",
		},
	})
end

M.comment_keys = {
	"gcc",
	"gcb",
	{ "gc", desc = "Line Comment" },
	{ "gb", desc = "Block Commemt" },
	"gcO",
	"gco",
	"gcA",
}

function M.todo_comment_setup()
	require("todo-comments").setup({
		colors = {
			error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
			warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
			info = { "DiagnosticInfo", "#2563EB" },
			hint = { "DiagnosticHint", "#10B981" },
			default = { "Identifier", "#7C3AED" },
			test = { "Identifier", "#FF00FF" },
		},
		keywords = {
			FIX = {
				icon = " ", -- icon used for the sign, and in search results
				color = "error", -- can be a hex color, or a named color (see below)
				alt = { "FIXME", "BUG", "FIXIT", "ISSUE" }, -- a set of other keywords that all map to this FIX keywords
				-- signs = false, -- configure signs for some keywords individually
			},
			TODO = { icon = " ", color = "info" },
			HACK = { icon = " ", color = "warning" },
			WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
			PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
			NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
			TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
		},
		gui_style = {
			fg = "NONE", -- The gui style to use for the fg highlight group.
			bg = "BOLD", -- The gui style to use for the bg highlight group.
		},
	})
end

M.todo_comment_keys = {
    --stylua: ignore start
	{ "]t", function() require("todo-comments").jump_next() end, desc = "Next Todo Comment", },
	{ "[t", function() require("todo-comments").jump_prev() end, desc = "Previous Todo Comment", },
	{ "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
	{ "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
	{ "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo" },
	{ "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },
	--stylua: ignore end
}

return M
