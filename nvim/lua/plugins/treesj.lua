return {
    "Wansmer/treesj",
    cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
    config = function()
        require("treesj").setup({
            use_default_keymaps = false,
            max_join_length = 1024,
        })
    end,
    keys = {
        {
            "gsk",
            function()
                require("treesj").join()
            end,
            desc = "Join current treesitter node",
        },
        {
            "gs<Up>",
            function()
                require("treesj").join()
            end,
            desc = "Join current treesitter node",
        },
        {
            "gsj",
            function()
                require("treesj").split()
            end,
            desc = "Split current treesitter node",
        },
        {
            "gs<Down>",
            function()
                require("treesj").split()
            end,
            desc = "Split current treesitter node",
        },
    },
}
