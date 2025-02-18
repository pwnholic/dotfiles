local blink_winhl = "Normal:Normal,FloatBorder:Comment,CursorLine:BlinkCmpMenuSelection,Search:None"

return {
    "saghen/blink.cmp",
    dependencies = { "stevearc/vim-vscode-snippets", "mikavilpas/blink-ripgrep.nvim" },
    opts = {
        enabled = function()
            return not vim.tbl_contains({ "bigfile" }, vim.bo.filetype) and vim.bo.buftype ~= "prompt" and vim.b.completion ~= false
        end,
        keymap = {
            ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
            ["<C-e>"] = { "hide", "fallback" },
            ["<CR>"] = { "select_and_accept", "fallback" },
            ["<Tab>"] = { "snippet_forward", "fallback" },
            ["<S-Tab>"] = { "snippet_backward", "fallback" },
            ["<Up>"] = { "select_prev", "fallback" },
            ["<Down>"] = { "select_next", "fallback" },
            ["<C-p>"] = { "select_prev", "fallback" },
            ["<C-n>"] = { "select_next", "fallback" },
            ["<C-b>"] = { "scroll_documentation_up", "fallback" },
            ["<C-f>"] = { "scroll_documentation_down", "fallback" },
        },
        cmdline = {
            keymap = {
                ["<C-p>"] = { "select_prev", "fallback" },
                ["<C-n>"] = { "select_next", "fallback" },
                ["<S-Tab>"] = { "select_prev", "fallback" },
                ["<Tab>"] = { "select_next", "fallback" },
                ["<CR>"] = { "accept", "fallback" },
                ["<Up>"] = { "select_prev", "fallback" },
                ["<Down>"] = { "select_next", "fallback" },
                ["<C-space>"] = { "show" },
            },
            sources = function()
                local type = vim.fn.getcmdtype()
                if type == "/" or type == "?" then
                    return { "buffer", "ripgrep" }
                elseif type == ":" or type == "@" then
                    return { "cmdline", "path" }
                else
                    return {}
                end
            end,
        },
        fuzzy = {
            sorts = { "score", "kind", "label", "sort_text" },
        },
        sources = {
            default = { "lsp", "path", "snippets", "ripgrep", "buffer" },

            providers = {
                path = {
                    name = "Path",
                    module = "blink.cmp.sources.path",
                    fallbacks = { "buffer", "ripgrep" },
                    score_offset = 100,
                    opts = {
                        trailing_slash = true,
                        label_trailing_slash = true,
                        get_cwd = function()
                            return os.getenv("PWD")
                        end,
                        show_hidden_files_by_default = true,
                    },
                },
                lsp = {
                    name = "LSP",
                    module = "blink.cmp.sources.lsp",
                    score_offset = 80,
                    max_items = 50,
                    fallbacks = { "buffer", "ripgrep" },
                    transform_items = function(_, items)
                        local blink_kinds = require("blink.cmp.types").CompletionItemKind
                        for _, item in ipairs(items) do
                            if item.kind == blink_kinds.Snippet then
                                item.score_offset = item.score_offset - 3
                            end
                        end
                        return vim.tbl_filter(function(item)
                            return item.kind ~= blink_kinds.Text
                        end, items)
                    end,
                },
                snippets = {
                    name = "Snippets",
                    max_items = 4,
                    module = "blink.cmp.sources.snippets",
                    score_offset = 60,
                    opts = {
                        friendly_snippets = true,
                        search_paths = {
                            vim.fn.stdpath("data") .. "/lazy/vim-vscode-snippets",
                            vim.fn.stdpath("config") .. "/snippets",
                        },
                        global_snippets = { "all" },
                    },
                },
                buffer = {
                    name = "Buffer",
                    module = "blink.cmp.sources.buffer",
                    score_offset = 20,
                    opts = {
                        prefix_min_len = 4,
                        get_bufnrs = function()
                            return vim.iter(vim.api.nvim_list_wins())
                                :map(function(win)
                                    return vim.api.nvim_win_get_buf(win)
                                end)
                                :filter(function(buf)
                                    return not vim.tbl_contains({ "nofile", "bigfile" }, vim.bo[buf].buftype)
                                end)
                                :totable()
                        end,
                    },
                },
                ripgrep = {
                    module = "blink-ripgrep",
                    name = "Ripgrep",
                    score_offset = 40,
                    ---@module "blink-ripgrep"
                    ---@type blink-ripgrep.Options
                    opts = {
                        prefix_min_len = 4,
                        context_size = 5,
                        max_filesize = "1M",
                        project_root_marker = { ".git", "go.mod", ".env", ".venv", "README.md", "Cargo.toml" },
                        project_root_fallback = true,
                        search_casing = "--ignore-case",
                        additional_rg_options = { "--max-depth", "4" },
                        fallback_to_regex_highlighting = true,
                        ignore_paths = { "node_modules", ".git", "tmp", "temp", ".venv", ".vscode" },
                        debug = false,
                    },
                },
            },
        },
        completion = {
            accept = {
                create_undo_point = true,
                resolve_timeout_ms = 100,
                auto_brackets = {
                    enabled = true,
                    default_brackets = { "(", ")" },
                    override_brackets_for_filetypes = {},
                    kind_resolution = {
                        enabled = true,
                        blocked_filetypes = { "typescriptreact", "javascriptreact", "vue" },
                    },
                    semantic_token_resolution = {
                        enabled = true,
                        blocked_filetypes = { "java" },
                        timeout_ms = 400,
                    },
                },
            },
            list = {
                max_items = 20,
                selection = {
                    preselect = function(ctx)
                        return ctx.mode ~= "cmdline"
                    end,
                    auto_insert = function(ctx)
                        return ctx.mode == "cmdline"
                    end,
                },
                cycle = { from_bottom = true, from_top = true },
            },
            menu = {
                enabled = true,
                border = vim.g.border,
                winblend = 0,
                min_width = 15,
                max_height = math.floor(vim.o.lines / 2) - 3,
                winhighlight = blink_winhl,
                direction_priority = { "s", "n" },
                draw = {
                    align_to = "label",
                    padding = 1,
                    gap = 1,
                    treesitter = { "lsp" },
                    columns = { { "kind_icon", gap = 1 }, { "label", "label_description", gap = 1 } },
                    components = {
                        kind_icon = {
                            ellipsis = false,
                            text = function(ctx)
                                if ctx.item.source_name == "Ripgrep" then
                                    ctx.kind_icon = ""
                                elseif ctx.item.source_name == "Buffer" then
                                    ctx.kind_icon = "󰯁"
                                end
                                return ctx.kind_icon .. ctx.icon_gap
                            end,
                        },
                        label = {
                            width = { fill = true, max = 50 },
                            text = function(ctx)
                                if ctx.label_detail ~= "" and ctx.mode ~= "cmdline" then
                                    return string.format("%s [%s]", ctx.label, ctx.label_detail)
                                else
                                    return string.format("%s", ctx.label)
                                end
                            end,
                            highlight = function(ctx)
                                local highlights = { { 0, #ctx.label, group = "BlinkCmpLabel" } }
                                if ctx.label_detail then
                                    table.insert(highlights, {
                                        #ctx.label,
                                        #ctx.label + #ctx.label_detail,
                                        group = "BlinkCmpKindKeyword",
                                    })
                                end
                                for _, idx in ipairs(ctx.label_matched_indices) do
                                    table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
                                end
                                return highlights
                            end,
                        },
                        label_description = {
                            width = { max = 30 },
                            text = function(ctx)
                                return ctx.label_description
                            end,
                            highlight = "FzfLuaPath",
                        },
                    },
                },
            },
            documentation = { auto_show = true, window = { border = vim.g.border, winhighlight = blink_winhl } },
            ghost_text = { enabled = true },
        },
        signature = { enabled = true, window = { border = vim.g.border, winhighlight = blink_winhl } },
    },
}
