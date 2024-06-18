vim.keymap.set({ "i", "c" }, "<Tab>", function()
	require("utils.tabout").jump(1)
end)

vim.keymap.set({ "i", "c" }, "<S-Tab>", function()
	require("utils.tabout").jump(-1)
end)
