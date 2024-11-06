return {
    "saghen/blink.cmp",
    dependencies = { "stevearc/vim-vscode-snippets", "niuiic/blink-cmp-rg.nvim" },
    build = "cargo build --release",
    opts = {
        sources = {
            completion = { enabled_providers = { "lsp", "path", "snippets", "ripgrep" } },
            providers = {
                path = {
                    name = "Path",
                    module = "blink.cmp.sources.path",
                    score_offset = 4,
                    opts = {
                        get_cwd = function(ctx)
                            return vim.fn.expand(("#%d:p:h"):format(ctx.bufnr)) or LazyVim.root()
                        end,
                        show_hidden_files_by_default = true,
                    },
                },
                lsp = {
                    name = "LSP",
                    module = "blink.cmp.sources.lsp",
                    score_offset = 3,
                },
                snippets = {
                    name = "Snippets",
                    module = "blink.cmp.sources.snippets",
                    score_offset = 2,
                    opts = {
                        friendly_snippets = true,
                        search_paths = { vim.fn.stdpath("data") .. "/lazy/vim-vscode-snippets" },
                        global_snippets = { "all" },
                    },
                },
                ripgrep = {
                    name = "Ripgrep",
                    module = "blink-cmp-rg",
                    score_offset = 1,
                    prefix_min_len = 3,
                    get_command = function(_, prefix)
                        return {
                            "rg",
                            "--no-config",
                            "--json",
                            "--word-regexp",
                            "--ignore-case",
                            "--",
                            prefix .. "[\\w_-]+",
                            LazyVim.root() or vim.fn.getcwd(),
                        }
                    end,
                    get_prefix = function()
                        local col = vim.api.nvim_win_get_cursor(0)[2]
                        local line = vim.api.nvim_get_current_line()
                        local prefix = line:sub(1, col):match("[%w_-]+$") or ""
                        return prefix
                    end,
                },
            },
        },
        fuzzy = {
            prebuiltBinaries = { download = true },
            sorts = { "score", "label", "kind" },
        },
        trigger = {
            signature_help = {
                enabled = true,
                show_on_insert_on_trigger_character = true,
            },
        },
        windows = {
            ghost_text = { enabled = true },
        },
    },
}
