return {
	"rcarriga/nvim-notify",
	event = "VeryLazy",
	init = vim.schedule_wrap(function()
		vim.notify = require("notify")
	end),
	opts = function()
		return {
			stages = "slide",
			timeout = 3000,
			render = "wrapped-compact",
			max_height = function()
				return math.floor(vim.o.lines * 0.75)
			end,
			max_width = function()
				return math.floor(vim.o.columns * 0.75)
			end,
			on_open = function(win)
				vim.api.nvim_win_set_config(win, { zindex = 100 })
			end,
		}
	end,
}
