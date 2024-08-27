return {
	"folke/todo-comments.nvim",
	cmd = "TodoTrouble",
	event = "BufRead",
	opts = function()
		return {
			keywords = {
				FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
				TODO = { icon = " ", color = "info" },
				HACK = { icon = " ", color = "warning" },
				WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
				PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
				NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
				TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
			},
		}
	end,
	keys = function()
		return {
                -- stylua: ignore start
				{ "]t", function() require("todo-comments").jump_next() end, desc = "Next Todo Comment", },
				{ "[t", function() require("todo-comments").jump_prev() end, desc = "Previous Todo Comment", },
				{ "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
				{ "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", desc = "Todo/Fix/Fixme (Trouble)", },
			-- stylua: ignore end
		}
	end,
}
