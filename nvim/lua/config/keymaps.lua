vim.keymap.set("n", "gQ", "mzgggqG`z<cmd>delmarks z<cr>zz", { desc = "Format buffer" })
vim.keymap.set({ "i", "c" }, "<C-l>", "<C-o>A", { desc = "Go to the end of the line" })

Snacks.toggle
    .option("laststatus", { off = 0, on = vim.o.laststatus > 0 and vim.o.laststatus or 3, name = "Last Status" })
    :map("<leader>ue")
