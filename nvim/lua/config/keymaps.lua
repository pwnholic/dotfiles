vim.keymap.del({ "i", "v", "n" }, "<A-j>")
vim.keymap.del({ "i", "v", "n" }, "<A-k>")

local keys = require("lazyvim.plugins.lsp.keymaps").get()
keys[#keys + 1] = { "<A-p>", false }
keys[#keys + 1] = { "<A-n>", false }

local map = vim.keymap.set

-- map({ "i", "c" }, "<Tab>", function()
--     require("utils.tabout").jump(1)
-- end)
-- map({ "i", "c" }, "<S-Tab>", function()
--     require("utils.tabout").jump(-1)
-- end)

keys[#keys + 1] = {
    "<C-LeftMouse>",
    [[<cmd>FzfLua lsp_definitions jump_to_single_result=true ignore_current_line=true<cr>]],
    desc = "Goto Definition",
    has = "definition",
}

map("n", "<C-RightMouse>", "<C-o>")

local lazyterm = function()
    LazyVim.terminal(nil, { cwd = LazyVim.root(), border = "single", size = { height = 1, width = 1 } })
end

map("n", "<leader>ft", lazyterm, { desc = "Terminal (Root Dir)" })
map("n", "<leader>fT", function()
    LazyVim.terminal(nil, { border = "single", size = { height = 1, width = 1 } })
end, { desc = "Terminal (cwd)" })
map("n", "<c-/>", lazyterm, { desc = "Terminal (Root Dir)" })
map("n", "<c-_>", lazyterm, { desc = "which_key_ignore" })

map("n", "<leader>gg", function()
    LazyVim.lazygit({ cwd = LazyVim.root.git(), border = "single", size = { height = 1, width = 1 } })
end, { desc = "Lazygit (Root Dir)" })
map("n", "<leader>gG", function()
    LazyVim.lazygit({ border = "single", size = { height = 1, width = 1 } })
end, { desc = "Lazygit (cwd)" })
map("n", "<leader>gb", LazyVim.lazygit.blame_line, { desc = "Git Blame Line" })
map("n", "<leader>gB", LazyVim.lazygit.browse, { desc = "Git Browse" })

map("n", "<leader>gf", function()
    local git_path = vim.api.nvim_buf_get_name(0)
    LazyVim.lazygit({ args = { "-f", vim.trim(git_path) }, border = "single", size = { height = 1, width = 1 } })
end, { desc = "Lazygit Current File History" })

map("n", "<leader>gl", function()
    LazyVim.lazygit({ args = { "log" }, cwd = LazyVim.root.git(), border = "single", size = { height = 1, width = 1 } })
end, { desc = "Lazygit Log" })
map("n", "<leader>gL", function()
    LazyVim.lazygit({ args = { "log" }, border = "single", size = { height = 1, width = 1 } })
end, { desc = "Lazygit Log (cwd)" })

map("n", "<A-n>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
map("n", "<A-p>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
map("i", "<A-n>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-p>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-n>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-p>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })
