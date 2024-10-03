vim.keymap.del({ "i", "v", "n" }, "<A-j>")
vim.keymap.del({ "i", "v", "n" }, "<A-k>")

local keys = require("lazyvim.plugins.lsp.keymaps").get()
keys[#keys + 1] = { "<A-p>", false }
keys[#keys + 1] = { "<A-n>", false }

vim.keymap.set({ "i", "c" }, "<Tab>", function()
    require("utils.tabout").jump(1)
end)
vim.keymap.set({ "i", "c" }, "<S-Tab>", function()
    require("utils.tabout").jump(-1)
end)

vim.keymap.set("i", "<A-p>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
vim.keymap.set("n", "<A-n>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
vim.keymap.set("n", "<A-p>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
vim.keymap.set("i", "<A-n>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
vim.keymap.set("v", "<A-p>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })
vim.keymap.set("v", "<A-n>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })

local utils = require("utils")

-- stylua: ignore start
utils.tmux.tmux_mapkey_fallback("<M-h>", utils.tmux.navigate_wrap("h"), utils.tmux.tmux_mapkey_navigate_condition("h"))
utils.tmux.tmux_mapkey_fallback("<M-j>", utils.tmux.navigate_wrap("j"), utils.tmux.tmux_mapkey_navigate_condition("j"))
utils.tmux.tmux_mapkey_fallback("<M-k>", utils.tmux.navigate_wrap("k"), utils.tmux.tmux_mapkey_navigate_condition("k"))
utils.tmux.tmux_mapkey_fallback("<M-l>", utils.tmux.navigate_wrap("l"), utils.tmux.tmux_mapkey_navigate_condition("l"))

utils.tmux.tmux_mapkey_fallback("<M-R>", "swap-pane -U")
utils.tmux.tmux_mapkey_fallback("<M-r>", "swap-pane -D")
utils.tmux.tmux_mapkey_fallback("<M-o>", "confirm 'kill-pane -a'")
utils.tmux.tmux_mapkey_fallback("<M-=>", "confirm 'select-layout tiled'")
utils.tmux.tmux_mapkey_fallback("<M-c>", "confirm kill-pane", utils.tmux.tmux_mapkey_close_win_condition)
utils.tmux.tmux_mapkey_fallback("<M-q>", "confirm kill-pane", utils.tmux.tmux_mapkey_close_win_condition)
utils.tmux.tmux_mapkey_fallback("<M-<>", "resize-pane -L 4", utils.tmux.tmux_mapkey_resize_pane_horiz_condition)
utils.tmux.tmux_mapkey_fallback("<M->>", "resize-pane -R 4", utils.tmux.tmux_mapkey_resize_pane_horiz_condition)
utils.tmux.tmux_mapkey_fallback("<M-,>", "resize-pane -L 4", utils.tmux.tmux_mapkey_resize_pane_horiz_condition)
utils.tmux.tmux_mapkey_fallback("<M-.>", "resize-pane -R 4", utils.tmux.tmux_mapkey_resize_pane_horiz_condition)
utils.tmux.tmux_mapkey_fallback( "<M-->", [[run "tmux resize-pane -y $(($(tmux display -p '#{pane_height}') - 2))"]], utils.tmux.tmux_mapkey_resize_pane_vert_condition)
utils.tmux.tmux_mapkey_fallback( "<M-+>", [[run "tmux resize-pane -y $(($(tmux display -p '#{pane_height}') + 2))"]], utils.tmux.tmux_mapkey_resize_pane_vert_condition)
-- stylua: ignore end
