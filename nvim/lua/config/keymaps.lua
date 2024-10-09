vim.keymap.del({ "i", "v", "n" }, "<A-j>")
vim.keymap.del({ "i", "v", "n" }, "<A-k>")

local keys = require("lazyvim.plugins.lsp.keymaps").get()
keys[#keys + 1] = { "<A-p>", false }
keys[#keys + 1] = { "<A-n>", false }

-- vim.keymap.set({ "i", "c" }, "<Tab>", function()
--     require("utils.tabout").jump(1)
-- end)
-- vim.keymap.set({ "i", "c" }, "<S-Tab>", function()
--     require("utils.tabout").jump(-1)
-- end)

vim.keymap.set("n", "<A-n>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
vim.keymap.set("n", "<A-p>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
vim.keymap.set("i", "<A-n>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
vim.keymap.set("i", "<A-p>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
vim.keymap.set("v", "<A-n>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
vim.keymap.set("v", "<A-p>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })
