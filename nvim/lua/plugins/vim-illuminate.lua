return {
	"RRethy/vim-illuminate",
	event = "BufRead",
	opts = function()
		return {
			delay = 0,
			providers = { "lsp", "treesitter", "regex" },
			large_file_cutoff = 2000,
			filetypes_denylist = {
				"oil",
				"harpoon",
			},
			modes_denylist = { "i", "v", "vs", "V", "Vs", "\22", "\22s" },
			large_file_overrides = { providers = { "lsp" } },
		}
	end,
	config = function(_, opts)
		require("illuminate").configure(opts)
	end,
}
