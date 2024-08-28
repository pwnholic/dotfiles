return {
	"folke/ts-comments.nvim",
	event = "BufRead",
	opts = { lang = { http = "# %s", json = { "# %s", "/* %s */" } } },
}
