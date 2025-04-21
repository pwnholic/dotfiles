vim.keymap.set("n", "gQ", "mzgggqG`z<cmd>delmarks z<cr>zz", { desc = "Format buffer" })
vim.keymap.set({ "i", "c" }, "<C-l>", "<C-o>A", { desc = "Go to the end of the line" })

Snacks.toggle
    .option("laststatus", { off = 0, on = vim.o.laststatus > 0 and vim.o.laststatus or 3, name = "Last Status" })
    :map("<leader>ue")

vim.keymap.set("n", "<leader><tab>1", function()
    if #vim.api.nvim_list_tabpages() >= 1 then
        vim.cmd("1tabnext")
    else
        vim.cmd("tabnew | tabmove 0")
    end
end, { desc = "Move/Create Tab 1" })

vim.keymap.set("n", "<leader><tab>2", function()
    if #vim.api.nvim_list_tabpages() >= 2 then
        vim.cmd("2tabnext")
    else
        vim.cmd("tabnew | tabmove 1")
    end
end, { desc = "Move/Create Tab 2" })

vim.keymap.set("n", "<leader><tab>3", function()
    if #vim.api.nvim_list_tabpages() >= 3 then
        vim.cmd("3tabnext")
    else
        vim.cmd("tabnew | tabmove 2")
    end
end, { desc = "Move/Create Tab 3" })

vim.keymap.set("n", "<leader><tab>4", function()
    if #vim.api.nvim_list_tabpages() >= 4 then
        vim.cmd("4tabnext")
    else
        vim.cmd("tabnew | tabmove 3")
    end
end, { desc = "Move/Create Tab 4" })

vim.keymap.set("n", "<leader><tab>5", function()
    if #vim.api.nvim_list_tabpages() >= 5 then
        vim.cmd("5tabnext")
    else
        vim.cmd("tabnew | tabmove 4")
    end
end, { desc = "Move/Create Tab 5" })

vim.keymap.set("n", "<leader><tab>6", function()
    if #vim.api.nvim_list_tabpages() >= 6 then
        vim.cmd("6tabnext")
    else
        vim.cmd("tabnew | tabmove 5")
    end
end, { desc = "Move/Create Tab 6" })

vim.keymap.set("n", "<leader><tab>7", function()
    if #vim.api.nvim_list_tabpages() >= 7 then
        vim.cmd("7tabnext")
    else
        vim.cmd("tabnew | tabmove 6")
    end
end, { desc = "Move/Create Tab 7" })

vim.keymap.set("n", "<leader><tab>8", function()
    if #vim.api.nvim_list_tabpages() >= 8 then
        vim.cmd("8tabnext")
    else
        vim.cmd("tabnew | tabmove 7")
    end
end, { desc = "Move/Create Tab 8" })

vim.keymap.set("n", "<leader><tab>9", function()
    if #vim.api.nvim_list_tabpages() >= 9 then
        vim.cmd("9tabnext")
    else
        vim.cmd("tabnew | tabmove 8")
    end
end, { desc = "Move/Create Tab 9" })
