return {
	"kylechui/nvim-surround",
	event = "BufRead",
	keys = function()
		return {
			"ys",
			"ds",
			"cs",
			{ "S", mode = "x" },
			{ "<C-g>s", mode = "i" },
		}
	end,
	opts = function()
		return {
			keymaps = {
				insert = "<C-g>s",
				insert_line = "<C-g>S",
				normal = "ys",
				normal_cur = "yss",
				normal_line = "yS",
				normal_cur_line = "ySS",
				visual = "S",
				visual_line = "gS",
				delete = "ds",
				change = "cs",
				change_line = "cS",
			},
		}
	end,
}
