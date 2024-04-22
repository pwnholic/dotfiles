local notify = require("notify")

notify.setup({
	on_open = function(win)
		vim.api.nvim_win_set_config(win, { zindex = 100 })
	end,
	fps = 60,
	timeout = 4000, -- 4 sec
	stages = "fade_in_slide_out",
	render = "wrapped-compact",
	max_height = math.max(10, math.ceil(vim.go.lines * 0.6)),
	max_width = math.max(15, math.ceil(vim.go.columns * 0.35)),
})
