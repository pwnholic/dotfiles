return {
	"folke/ts-comments.nvim",
	event = "BufRead",
	opts = function()
		return { lang = { http = "# %s", json = { "# %s", "/* %s */" } } }
	end,
}
