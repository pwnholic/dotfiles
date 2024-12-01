return {
    {
        "saghen/blink.cmp",
        dependencies = {
            "stevearc/vim-vscode-snippets",
            "niuiic/blink-cmp-rg.nvim",
        },
        opts = {
            keymap = {
                preset = "default",
                ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
                ["<C-e>"] = { "hide", "fallback" },
                ["<CR>"] = { "accept", "fallback" },
                ["<Tab>"] = { "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "snippet_backward", "fallback" },
                ["<Up>"] = { "select_prev", "fallback" },
                ["<Down>"] = { "select_next", "fallback" },
                ["<C-p>"] = { "select_prev", "fallback" },
                ["<C-n>"] = { "select_next", "fallback" },
                ["<C-b>"] = { "scroll_documentation_up", "fallback" },
                ["<C-f>"] = { "scroll_documentation_down", "fallback" },
            },
            fuzzy = { sorts = { "score" } },
            sources = {
                completion = {
                    enabled_providers = function()
                        return { "lsp", "path", "snippets", "ripgrep", "buffer" }
                    end,
                },
                providers = {
                    path = {
                        name = "Path",
                        module = "blink.cmp.sources.path",
                        score_offset = 4,
                        opts = {
                            get_cwd = function()
                                return LazyVim.root()
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
                        score_offset = -2,
                        opts = {
                            friendly_snippets = true,
                            search_paths = { vim.fn.stdpath("data") .. "/lazy/vim-vscode-snippets" },
                            global_snippets = { "all" },
                        },
                    },
                    ripgrep = {
                        module = "blink-cmp-rg",
                        score_offset = 2,
                        name = "Ripgrep",
                        opts = {
                            prefix_min_len = 5,
                            context_size = 5,
                            get_prefix = function()
                                local curpos = vim.fn.getcurpos()
                                local col = curpos[5] -- Kolom kursor (1-based indexing)
                                local line = vim.fn.getline(".")
                                local prefix = line:sub(1, col - 1):match("[%w_-]+$") or ""
                                return prefix
                            end,
                            get_command = function(_, prefix)
                                return {
                                    "rg",
                                    "--no-config",
                                    "--json",
                                    "--word-regexp",
                                    "--ignore-case",
                                    "--",
                                    prefix .. "[\\w_-]+",
                                    LazyVim.root() or vim.uv.cwd(),
                                }
                            end,
                        },
                    },
                },
            },
            completion = {
                menu = {
                    enabled = true,
                    min_width = 15,
                    max_height = 10,
                    border = vim.g.border,
                    winblend = 0,
                    winhighlight = "Normal:Normal,FloatBorder:Comment,CursorLine:BlinkCmpMenuSelection,Search:None",
                    scrolloff = 2,
                    scrollbar = false,
                    direction_priority = { "s", "n" },
                    draw = {
                        align_to_component = "label",
                        padding = 1,
                        gap = 2,
                        columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
                        components = {
                            kind_icon = {
                                ellipsis = false,
                                text = function(ctx)
                                    if ctx.item.source_name == "Ripgrep" then
                                        ctx.kind_icon = ""
                                    end
                                    return ctx.kind_icon .. ctx.icon_gap
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
                documentation = {
                    auto_show = true,
                    window = {
                        border = vim.g.border,
                        winhighlight = "Normal:Normal,FloatBorder:Comment,CursorLine:BlinkCmpMenuSelection,Search:None",
                    },
                },
                ghost_text = { enabled = true },
            },
            signature = {
                enabled = false,
                window = {
                    border = vim.g.border,
                    winhighlight = "Normal:Normal,FloatBorder:Comment,CursorLine:BlinkCmpMenuSelection,Search:None",
                },
            },
        },
    },
}
