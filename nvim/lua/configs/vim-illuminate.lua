local ill = require("illuminate")

ill.configure({
	providers = { "lsp", "treesitter", "regex" },
	delay = 0,
	filetypes_denylist = {
		"^harpoon$",
		"^dashboard$",
		"^fzf$",
		"^lazy$",
		"^lazyterm$",
		"^netrw$",
		"^neotest--summary$",
		"^Trouble$",
		"^dbui$",
		"^dbout$",
	},
	large_file_cutoff = 2000,
	case_insensitive_regex = false,
	modes_denylist = { "i", "ic", "ix" },
})

vim.keymap.set("n", "]]", function()
	ill.goto_next_reference(false)
end, { desc = "Next Reference" })
vim.keymap.set("n", "[[", function()
	ill.goto_prev_reference(false)
end, { desc = "Prev Reference" })
