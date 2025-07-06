vim.keymap.set("n", "gQ", "mzgggqG`z<cmd>delmarks z<cr>zz", { desc = "Format buffer" })
vim.keymap.set({ "i", "c" }, "<C-l>", "<C-o>A", { desc = "Go to the end of the line" })

Snacks.toggle
    .option("laststatus", { off = 0, on = vim.o.laststatus > 0 and vim.o.laststatus or 3, name = "Last Status" })
    :map("<leader>ue")

for i = 1, 9 do
    vim.keymap.set("n", string.format("<leader><tab>%d", i), function()
        if #vim.api.nvim_list_tabpages() >= i then
            vim.cmd(string.format("%dtabnext", i))
        else
            vim.cmd(string.format("tabnew | tabmove %d", i - 1))
        end
    end, { desc = string.format("Move/Create Tab %d", i) })
end
