vim.keymap.set("n", "<A-n>", "<cmd>m .+1<cr>==", { desc = "Move Down", silent = true })
vim.keymap.set("i", "<A-p>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up", silent = true })
vim.keymap.set("i", "<A-n>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down", silent = true })
vim.keymap.set("v", "<A-n>", ":m '>+1<cr>gv=gv", { desc = "Move Down", silent = true })
vim.keymap.set("n", "<A-p>", "<cmd>m .-2<cr>==", { desc = "Move Up", silent = true })
vim.keymap.set("v", "<A-p>", ":m '<-2<cr>gv=gv", { desc = "Move Up", silent = true })

vim.keymap.del({ "n", "i", "v" }, "<A-k>")
vim.keymap.del({ "n", "i", "v" }, "<A-j>")

local keys = require("lazyvim.plugins.lsp.keymaps").get()
keys[#keys + 1] = { "<A-p>", false }
keys[#keys + 1] = { "<A-n>", false }
