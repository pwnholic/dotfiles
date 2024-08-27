return {
	"NvChad/nvim-colorizer.lua",
	event = "BufReadPre",
	opts = function()
		return {
			user_default_options = {
				RGB = true,
				RRGGBB = true,
				names = true,
				RRGGBBAA = false,
				AARRGGBB = false,
				rgb_fn = false,
				hsl_fn = false,
				css = true,
				css_fn = true,
				mode = "virtualtext",
				virtualtext = " ",
				always_update = false,
			},
			buftypes = {},
		}
	end,
}
