vim.keymap.set("n", "gQ", "mzgggqG`z<cmd>delmarks z<cr>zz", { desc = "Format buffer" })
vim.keymap.set({ "i", "c" }, "<C-l>", "<C-o>A", { desc = "Go to the end of the line" })

vim.keymap.set("n", "<leader><Tab>1", "<cmd>tabn 1<cr>", { desc = "Go Tab 1" })
vim.keymap.set("n", "<leader><Tab>2", "<cmd>tabn 2<cr>", { desc = "Go Tab 2" })
vim.keymap.set("n", "<leader><Tab>3", "<cmd>tabn 3<cr>", { desc = "Go Tab 3" })
vim.keymap.set("n", "<leader><Tab>4", "<cmd>tabn 4<cr>", { desc = "Go Tab 4" })
vim.keymap.set("n", "<leader><Tab>5", "<cmd>tabn 5<cr>", { desc = "Go Tab 5" })
vim.keymap.set("n", "<leader><Tab>6", "<cmd>tabn 6<cr>", { desc = "Go Tab 6" })
vim.keymap.set("n", "<leader><Tab>7", "<cmd>tabn 7<cr>", { desc = "Go Tab 7" })
vim.keymap.set("n", "<leader><Tab>8", "<cmd>tabn 8<cr>", { desc = "Go Tab 8" })
vim.keymap.set("n", "<leader><Tab>9", "<cmd>tabn 9<cr>", { desc = "Go Tab 9" })

Snacks.toggle
    .option("laststatus", { off = 0, on = vim.o.laststatus > 0 and vim.o.laststatus or 3, name = "Last Status" })
    :map("<leader>ue")
