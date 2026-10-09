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
        keys = {
            {
                "<leader>e",
                function()
                    require("oil").open()
                end,
                desc = "Explorer (project root)",
            },
            {
                "<leader>E",
                function()
                    require("oil").open(LazyVim.root())
                end,
                desc = "Explorer (cwd)",
            },
        },

        ---@module "oil"
        ---@type oil.SetupOpts
        opts = {
            default_file_explorer = true,
            buf_options = {
                buflisted = false,
                bufhidden = "hide",
            },
            win_options = {
                number = false,
                relativenumber = false,
                wrap = false,
                signcolumn = "no",
                cursorcolumn = false,
                foldcolumn = "0",
                spell = false,
                list = false,
                conceallevel = 3,
                concealcursor = "nvic",
            },
            columns = { "icon" },
            float = {
                padding = 2,
                border = vim.o.winborder,
                win_options = { winblend = 0 },
            },
            delete_to_trash = true,
            skip_confirm_for_simple_edits = false,
            prompt_save_on_select_new_entry = true,
            cleanup_delay_ms = 2000,
            lsp_file_methods = {
                enabled = true,
                timeout_ms = 1000,
                autosave_changes = false,
            },
            constrain_cursor = "editable",
            watch_for_changes = false,
            keymaps = {
                ["g?"] = { "actions.show_help", mode = "n", desc = "Show Oil keymaps" },
                ["<CR>"] = { "actions.select", desc = "Open file or directory" },
                ["<C-s>"] = { "actions.select", opts = { vertical = true }, desc = "Open in vertical split" },
                ["<C-h>"] = { "actions.select", opts = { horizontal = true }, desc = "Open in horizontal split" },
                ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open in new tab" },
                ["<C-p>"] = { "actions.preview", desc = "Preview entry" },
                ["<C-c>"] = { "actions.close", mode = "n", desc = "Close Oil" },
                ["q"] = { "actions.close", mode = "n", desc = "Close Oil" },
                ["<C-l>"] = { "actions.refresh", desc = "Refresh directory" },
                ["-"] = { "actions.parent", mode = "n", desc = "Go to parent directory" },
                ["_"] = { "actions.open_cwd", mode = "n", desc = "Open working directory" },
                ["`"] = { "actions.cd", mode = "n", desc = "Change working directory" },
                ["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n", desc = "Change tab directory" },
                ["gs"] = { "actions.change_sort", mode = "n", desc = "Change sort order" },
                ["gx"] = { "actions.open_external", desc = "Open with external application" },
                ["g."] = { "actions.toggle_hidden", mode = "n", desc = "Toggle hidden files" },
                ["g\\"] = { "actions.toggle_trash", mode = "n", desc = "Toggle Trash" },
                ["gy"] = { "actions.yank_entry", desc = "Yank entry path" },
            },
            use_default_keymaps = false,
            view_options = {
                show_hidden = false,
                natural_order = "fast",
                case_insensitive = false,
                sort = {
                    { "type", "asc" },
                    { "name", "asc" },
                },
            },
        },
    },
}
