return {
	"mfussenegger/nvim-lint",
	event = "LazyFile",
	opts = {
		events = { "BufWritePost" },
		linters_by_ft = {
			lua = { "selene" },
		},
		linters = {
			selene = {
				condition = function(ctx)
					return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
				end,
			},
		},
	},
}
