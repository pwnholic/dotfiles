return {
	condition = function()
		return not require("heirline.conditions").buffer_matches({
			buftype = { "nofile", "prompt", "help", "quickfix", "terminal" },
			filetype = { "dashboard", "fzf", "harpoon", "oil", "diff" },
		})
	end,
	provider = require("utils.stc").statuscolumn,
}
