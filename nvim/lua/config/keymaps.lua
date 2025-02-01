vim.keymap.set("n", "gQ", "mzgggqG`z<cmd>delmarks z<cr>zz", { desc = "Format buffer" })
vim.keymap.set({ "i", "c" }, "<C-l>", "<C-o>A", { desc = "Go to the end of the line" })

vim.api.nvim_create_user_command("GitCommitMsg", function()
    return vim.cmd("Git add %") and vim.cmd("Git commit %")
end, {})
