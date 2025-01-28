vim.keymap.set("n", "gQ", "mzgggqG`z<cmd>delmarks z<cr>zz", { desc = "Format buffer" })
vim.keymap.set({ "i", "c" }, "<C-l>", "<C-o>A", { desc = "Go to the end of the line" })

local keys = require("lazyvim.plugins.lsp.keymaps").get()
keys[#keys + 1] = { "gd", "<cmd>Trouble lsp_definitions<cr>" }
keys[#keys + 1] = { "gr", "<cmd>Trouble lsp_references<cr>" }

vim.api.nvim_create_user_command("GitCommitMsg", function()
    return vim.cmd("Git add %") and vim.cmd("Git commit %")
end, {})
