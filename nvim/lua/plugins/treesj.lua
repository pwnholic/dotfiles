return {
    "Wansmer/treesj",
    cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
    opts = {
        use_default_keymaps = false,
        max_join_length = 1024,
    },
    keys = {
        { "<leader>cj", "<cmd>TSJToggle<cr>", desc = "Split/Join Current Node" },
    },
}
