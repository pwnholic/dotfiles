local c = require("tokyonight.colors").setup()
require("nvim-web-devicons").setup({
	override_by_filename = {
		["go.mod"] = { icon = "󰏗", color = c.green, name = "gomod_" },
		["go.sum"] = { icon = "", color = c.blue, name = "gomod_" },
	},
	override_by_extension = {
		["env"] = { icon = "", color = c.yellow1, name = "Env_" },
		["example"] = { icon = "󰺖", color = c.yellow, name = "Example_" },
		["http"] = { icon = "", color = c.orange, name = "Http_" },
	},
})
