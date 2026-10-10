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
        -- Join guard follows the current split: a joined line longer than
        -- the window just re-wraps (no overflow, but unreadable).
        max_join_length = math.max(80, math.floor((vim.api.nvim_win_get_width(0) or 120) * 0.9)),
        cursor_behavior = "hold",
        notify = true,
        dot_repeat = true,
    },
}
