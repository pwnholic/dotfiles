-- File explorer: oil.nvim replaces the snacks explorer.
--
-- Official docs (https://github.com/stevearc/oil.nvim, doc/oil.txt):
--   * `lazy = false` — "Lazy loading is not recommended because it is very tricky to make it work
--     correctly in all situations."
--   * `default_file_explorer = true` (default) — "Oil will take over directory buffers
--     (e.g. `vim .` or `:e src/`)"; oil then sets `vim.g.loaded_netrw = 1` /
--     `loaded_netrwPlugin = 1`, i.e. it does the same directory-buffer hijack that
--     `snacks.explorer.replace_netrw` used to do.
--   * icon provider is optional: mini.icons (LazyVim already ships it and mocks nvim-web-devicons).
--   * default `keymaps` (`<CR>` select, `-` parent, `g.` hidden, `g?` help, ...) are kept as-is.
--
-- snacks.nvim's explorer is switched off in the same fragment (`explorer.enabled = false`), which
-- makes `Snacks.explorer.setup()` a no-op: no netrw hijack, no `BufEnter` picker. Its explorer
-- keymaps (`<leader>e`, `<leader>E`, `<leader>fe`, `<leader>fE` from the
-- `editor.snacks_explorer` extra) are removed with `false` so oil can own `<leader>e`/`<leader>E`.
-- Everything else from snacks (picker, notifier, bufdelete, rename, ...) keeps working.
return {
    {
        "folke/snacks.nvim",
        opts = { explorer = { enabled = false } },
        keys = {
            { "<leader>e", false },
            { "<leader>E", false },
            { "<leader>fe", false },
            { "<leader>fE", false },
        },
    },
    {
        "stevearc/oil.nvim",
        lazy = false,
        dependencies = { { "nvim-mini/mini.icons", opts = {} } },
        keys = {
            {
                "<leader>e",
                function()
                    require("oil").open(LazyVim.root())
                end,
                desc = "Explorer Oil (root dir)",
            },
            {
                "<leader>E",
                function()
                    require("oil").open(vim.uv.cwd())
                end,
                desc = "Explorer Oil (cwd)",
            },
        },
        opts = {
            default_file_explorer = true,
            -- deleted files go to the system trash instead of being removed permanently
            delete_to_trash = true,
            view_options = { show_hidden = true },
            float = { padding = 2 },
            win_options = {
                number = false,
                relativenumber = false,
            },
        },
    },
}
