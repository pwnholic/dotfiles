vim.keymap.del({ "i", "v", "n" }, "<A-j>")
vim.keymap.del({ "i", "v", "n" }, "<A-k>")

local keys = require("lazyvim.plugins.lsp.keymaps").get()
keys[#keys + 1] = { "<A-p>", false }
keys[#keys + 1] = { "<A-n>", false }

vim.keymap.set({ "i", "c" }, "<Tab>", function()
    require("utils.tabout").jump_next(1)
end)
vim.keymap.set({ "i", "c" }, "<S-Tab>", function()
    require("utils.tabout").jump_next(-1)
end)
