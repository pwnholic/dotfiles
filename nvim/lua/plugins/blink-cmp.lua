return {
    {
        "saghen/blink.cmp",
        dependencies = {
            "stevearc/vim-vscode-snippets",
            "niuiic/blink-cmp-rg.nvim",
        },
        opts = {
            enabled = function()
                return not vim.tbl_contains({ "prompt", "bigfile" }, vim.bo.buftype)
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
                cmdline = {
                    ["<C-p>"] = { "select_prev", "fallback" },
                    ["<C-n>"] = { "select_next", "fallback" },
                    ["<S-Tab>"] = { "select_prev", "fallback" },
                    ["<Tab>"] = { "select_next", "fallback" },
                    ["<CR>"] = { "accept", "fallback" },
                },
            },
            fuzzy = {
                sorts = { "score", "kind", "label" },
            },
            sources = {
                default = { "lsp", "path", "snippets", "ripgrep", "buffer" },
                cmdline = function()
                    local type = vim.fn.getcmdtype()
                    if type == "/" or type == "?" then
                        return { "buffer", "ripgrep" }
                    end
                    if type == ":" then
                        return { "cmdline" }
                    end
                    return {}
                end,
                providers = {
                    path = {
                        name = "Path",
                        module = "blink.cmp.sources.path",
                        fallbacks = { "buffer", "ripgrep" },
                        score_offset = 100,
                        opts = {
                            get_cwd = function()
                                return LazyVim.root() or vim.uv.cwd()
                            end,
                            show_hidden_files_by_default = true,
                        },
                    },
                    lsp = {
                        name = "LSP",
                        module = "blink.cmp.sources.lsp",
                        score_offset = 3,
                        fallbacks = { "buffer", "ripgrep" },
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
                    buffer = {
                        name = "Buffer",
                        score_offset = 1,
                        module = "blink.cmp.sources.buffer",
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
                        module = "blink-cmp-rg",
                        score_offset = 2,
                        name = "Ripgrep",
                        opts = {
                            prefix_min_len = 4,
                            get_prefix = function(context)
                                return context.line:sub(1, context.cursor[2]):match("[%w_-]+$") or ""
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
                list = {
                    max_items = 20,
                    selection = function(ctx)
                        return ctx.mode == "cmdline" and "auto_insert" or "preselect"
                    end,
                    cycle = {
                        from_bottom = true,
                        from_top = true,
                    },
                },
                menu = {
                    enabled = true,
                    border = vim.g.border,
                    winblend = 0,
                    winhighlight = "Normal:Normal,FloatBorder:Comment,CursorLine:BlinkCmpMenuSelection,Search:None",
                    direction_priority = { "s", "n" },
                    draw = {
                        align_to = "label",
                        padding = 1,
                        gap = 1,
                        columns = { { "kind_icon", gap = 1 }, { "label", "label_description", gap = 1 } },
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
                            },
                            label = {
                                width = { fill = true, max = 50 },
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
                enabled = true,
                window = {
                    border = vim.g.border,
                    winhighlight = "Normal:Normal,FloatBorder:Comment,CursorLine:BlinkCmpMenuSelection,Search:None",
                },
            },
        },
    },
}
