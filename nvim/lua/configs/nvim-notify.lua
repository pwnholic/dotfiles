require("notify").setup({
	fps = 60,
	timeout = 3000,
	on_open = function(win)
		vim.api.nvim_win_set_config(win, { zindex = 100 })
	end,
	max_height = math.max(10, math.ceil(vim.go.lines * 0.6)),
	max_width = math.max(15, math.ceil(vim.go.columns * 0.35)),
	render = "wrapped-compact",
})
