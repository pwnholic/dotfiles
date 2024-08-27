return {
	"Bekaboo/deadcolumn.nvim",
	event = "BufRead",
	opts = function()
		return {
			scope = "line",
			modes = function(mode)
				return mode:find("^[ictRss\x13]") ~= nil
			end,
			blending = {
				threshold = 0.75,
				colorcode = "#000000",
				hlgroup = { "Normal", "bg" },
			},
			warning = {
				alpha = 0.4,
				offset = 0,
				colorcode = "#FF0000",
				hlgroup = { "Error", "bg" },
			},
			extra = { follow_tw = nil },
		}
	end,
}
