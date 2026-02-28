return {
    "saghen/blink.cmp",
    opts = {
        keymap = {
            preset = "none",
            ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
            ["<C-e>"] = { "cancel", "fallback" },
            ["<C-y>"] = { "select_and_accept" },
            ["<CR>"] = { "accept", "fallback" },
            ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
            ["<C-n>"] = { "select_next", "fallback_to_mappings" },
            ["<Up>"] = { "select_prev", "fallback" },
            ["<Down>"] = { "select_next", "fallback" },
            ["<C-u>"] = { "scroll_documentation_up", "fallback" },
            ["<C-d>"] = { "scroll_documentation_down", "fallback" },
            ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
            ["<Tab>"] = { "snippet_forward", "fallback" },
            ["<S-Tab>"] = { "snippet_backward", "fallback" },
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
            per_filetype = {
                markdown = { "lsp", "path", "buffer", "snippets" },
            },
            -- Keyword minimum — jangan trigger completion untuk 1 karakter
            min_keyword_length = function(ctx)
                -- Di cmdline dan search, trigger dari 1 karakter
                if ctx.mode == "cmdline" then
                    return 1
                end
                return 2
            end,
            providers = {
                lsp = {
                    name = "LSP",
                    module = "blink.cmp.sources.lsp",
                    fallbacks = { "buffer" },
                    score_offset = 0,
                },
                path = {
                    name = "Path",
                    module = "blink.cmp.sources.path",
                    score_offset = 3,
                    fallbacks = { "buffer" },
                    opts = {
                        trailing_slash = true,
                        label_trailing_slash = true,
                        show_hidden_files_by_default = false,
                    },
                },
                snippets = {
                    name = "Snippets",
                    module = "blink.cmp.sources.snippets",
                    score_offset = -3,
                    opts = {
                        friendly_snippets = true,
                        search_paths = { vim.fn.stdpath("config") .. "/snippets" },
                        global_snippets = { "all" },
                    },
                },
                buffer = {
                    name = "Buffer",
                    module = "blink.cmp.sources.buffer",
                    score_offset = -5,
                    min_keyword_length = 3,
                    opts = {
                        get_bufnrs = function()
                            return vim.iter(vim.api.nvim_list_wins())
                                :map(function(win)
                                    return vim.api.nvim_win_get_buf(win)
                                end)
                                :filter(function(buf)
                                    return vim.bo[buf].buftype ~= "nofile"
                                end)
                                :totable()
                        end,
                    },
                },
            },
        },
        cmdline = {
            sources = function()
                local type = vim.fn.getcmdtype()
                if type == "/" or type == "?" then
                    return { "buffer" }
                end
                if type == ":" or type == "@" then
                    return { "cmdline" }
                end
                return {}
            end,
        },
        fuzzy = {
            implementation = "prefer_rust",
            max_typos = function(keyword)
                return math.floor(#keyword / 4)
            end,
            frecency = {
                enabled = true,
                path = vim.fn.stdpath("state") .. "/blink/cmp/frecency.dat",
            },
            use_proximity = true,
            sorts = {
                "exact",
                "score",
                "sort_text",
                "label",
            },
            prebuilt_binaries = {
                download = true,
            },
        },
        completion = {
            keyword = { range = "full" },
            trigger = {
                prefetch_on_insert = true,
                show_on_keyword = true,
                show_on_trigger_character = true,
                show_on_accept_on_trigger_character = true,
                show_on_insert_on_trigger_character = true,
            },
            list = {
                max_items = 100,
                selection = {
                    preselect = function(ctx)
                        return ctx.mode ~= "cmdline" and not require("blink.cmp").snippet_active({ direction = 1 })
                    end,
                    auto_insert = function(ctx)
                        return ctx.mode == "cmdline"
                    end,
                },
                cycle = { from_bottom = true, from_top = true },
            },
            accept = {
                dot_repeat = true,
                create_undo_point = true,
                auto_brackets = {
                    enabled = true,
                    kind_resolution = {
                        enabled = true,
                        blocked_filetypes = { "typescriptreact" },
                    },
                    semantic_token_resolution = {
                        enabled = true,
                        blocked_filetypes = {},
                        timeout_ms = 400,
                    },
                },
            },
            menu = {
                max_height = 12,
                scrolloff = 2,
                direction_priority = { "s", "n" },
                auto_show = true,
                draw = {
                    align_to = "label",
                    treesitter = { "lsp" },
                    columns = {
                        { "kind_icon" },
                        { "label", "label_description", gap = 1 },
                    },
                },
            },
        },
    },
}
