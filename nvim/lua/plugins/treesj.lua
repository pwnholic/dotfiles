-- TreeSJ: split/join code blocks via treesitter.
--
-- Default upstream keys (`<space>m/j/s`) collide with LazyVim: `<leader>s`
-- is the search group, `<leader>m` sits next to formatting prefixes. So
-- `use_default_keymaps = false` and the actions live under `<leader>J`
-- (capital-J: plain `J` joins lines, this joins/splits syntax nodes).
-- Collision scan 2026-10-09: no `<leader>J` anywhere in LazyVim core or
-- extras; `:TSJToggle/Split/Join` commands only exist inside treesj
-- itself. Trouble owns `<leader>cs`/`cS`, vtsls owns `<leader>cM` —
-- so split/join get `<leader>cJ`/`cK` and recursive gets `<leader>CK`
-- (all verified free 2026-10-09).
return {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = "LazyFile",
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
