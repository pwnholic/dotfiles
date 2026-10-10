-- TreeSJ under `<leader>J` (defaults collide with LazyVim search/format).
-- Collision scan 2026-10-09: all four keys free in core + extras.
return {
    "Wansmer/treesj",
    keys = {
        {
            "<leader>J",
            function()
                require("treesj").toggle()
            end,
            desc = "Split/Join block (toggle)",
        },
        {
            "<leader>cJ",
            function()
                require("treesj").split()
            end,
            desc = "Split block",
        },
        {
            "<leader>cK",
            function()
                require("treesj").join()
            end,
            desc = "Join block",
        },
        {
            "<leader>CK",
            function()
                require("treesj").toggle({ split = { recursive = true } })
            end,
            desc = "Split/Join block (recursive)",
        },
    },
    opts = {
        use_default_keymaps = false,
        check_syntax_error = true,
        max_join_length = 120,
        cursor_behavior = "hold",
        notify = true,
        dot_repeat = true,
    },
}
