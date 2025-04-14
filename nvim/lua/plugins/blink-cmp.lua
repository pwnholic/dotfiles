local win_hl = "Normal:Normal,FloatBorder:Comment,CursorLine:BlinkCmpMenuSelection,Search:None"
return {
    "saghen/blink.cmp",
    dependencies = {
        { "mikavilpas/blink-ripgrep.nvim" },
        { "stevearc/vim-vscode-snippets" },
    },
    opts = {
        cmdline = {
            enabled = true,
            keymap = { preset = "cmdline" },
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
            completion = {
                menu = {
                    auto_show = true,
                    draw = { columns = { { "kind_icon" }, { "label" } } },
                },
            },
        },
        fuzzy = {
            implementation = "prefer_rust_with_warning",
            sorts = { "exact", "score", "sort_text" },
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
                            return vim.uv.cwd() or (os.getenv("PWD") or os.getenv("USERPROFILE")) or ""
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
                            vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "vim-vscode-snippets"),
                            vim.fs.joinpath(vim.fn.stdpath("config"), "snippets"),
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
                                :map(function(winnr)
                                    return vim.api.nvim_win_get_buf(winnr)
                                end)
                                :filter(function(bufnr)
                                    return vim.bo[bufnr].buftype ~= "nofile"
                                end)
                                :totable()
                        end,
                    },
                },
                ripgrep = {
                    module = "blink-ripgrep",
                    name = "Ripgrep",
                    score_offset = 40,
                    opts = {
                        prefix_min_len = 4,
                        context_size = 5,
                        max_filesize = "1M",
                        project_root_marker = { ".git", "go.mod", ".env", "Cargo.toml" },
                        project_root_fallback = true,
                        -- search_casing = "--ignore-case", -- kerana saya pake golang
                        search_casing = "--smart-case",
                        additional_rg_options = {
                            "--max-depth",
                            "4",
                            "--hidden",
                            "--trim",
                            "--color=always",
                            "--engine=auto",
                            "--type-add=go:*.go",
                            "--type-add=proto:*.proto",
                            "--glob=!vendor/**",
                            "--glob=!**/*_test.go",
                            "--glob=!*.pb.go",
                            "--glob=!*.gen.go",
                            "--glob=!bin/**",
                            "--glob=!**/testdata/**",
                            "--glob=!*.wire.go",
                        },
                        fallback_to_regex_highlighting = true,
                        ignore_paths = {
                            "**/vendor/**",
                            "**/bin/**",
                            "**/.cache/**",
                            "**/testdata/**",
                            "**/coverage/**",
                            "**/docs/**",
                            "**/api/**/mock_*",
                        },
                        debug = false,
                    },
                },
            },
        },
        signature = { window = { winhighlight = win_hl } },
        completion = {
            documentation = {
                auto_show = true,
                window = { winhighlight = win_hl, border = vim.g.border },
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
                scrollbar = false,
                min_width = 15,
                max_height = math.floor(vim.o.lines / 2) - 3,
                winhighlight = win_hl,
                direction_priority = { "s", "n" },
                draw = {
                    align_to = "label",
                    padding = 1,
                    gap = 1,
                    columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
                    components = {
                        kind_icon = {
                            ellipsis = false,
                            text = function(ctx)
                                if ctx.item.source_name == "Ripgrep" then
                                    ctx.kind_icon = " "
                                elseif ctx.item.source_name == "Buffer" then
                                    ctx.kind_icon = "󰯁 "
                                end
                                return ctx.kind_icon .. ctx.icon_gap
                            end,
                            highlight = function(ctx)
                                return { { group = ctx.kind_hl, priority = 20000 } }
                            end,
                        },
                        label = {
                            width = { fill = true, max = 60 },
                            text = function(ctx)
                                return ctx.label .. ctx.label_detail
                            end,
                            highlight = function(ctx)
                                local highlights = {
                                    {
                                        0,
                                        #ctx.label,
                                        group = ctx.deprecated and "BlinkCmpLabelDeprecated" or "BlinkCmpLabel",
                                    },
                                }
                                if ctx.label_detail then
                                    table.insert(highlights, {
                                        #ctx.label,
                                        #ctx.label + #ctx.label_detail,
                                        group = "BlinkCmpLabelDetail",
                                    })
                                end
                                -- characters matched on the label by the fuzzy matcher
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
                            highlight = "BlinkCmpLabelDescription",
                        },
                    },
                },
            },
        },
    },
}
