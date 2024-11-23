return {
    {
        "saghen/blink.cmp",
        dependencies = { "stevearc/vim-vscode-snippets", "niuiic/blink-cmp-rg.nvim" },
        opts = {
            fuzzy = { sorts = { "score" } },
            sources = {
                completion = { enabled_providers = { "lsp", "path", "snippets", "ripgrep", "buffer" } },
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
                        transform_items = function(_, items)
                            if items.kind == "Text" or items.kind == "Snippet" then
                                return nil
                            end
                            return items
                        end,
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
                                    "--glob=!.git/*",
                                    "--glob=!client/*", -- change this
                                    "--glob=!node_modules/*",
                                    "--glob=!temp/*",
                                    "--glob=!.temp/*",
                                    "--glob=!tmp/*",
                                    "--glob=!.tmp/*",
                                    "--glob=!.vscode/*",
                                    "--",
                                    prefix .. "[\\w_-]+",
                                    LazyVim.root() or vim.uv.cwd(),
                                }
                            end,
                        },
                    },
                },
            },
            windows = {
                autocomplete = {
                    border = vim.g.border,
                    winhighlight = "Normal:Normal,FloatBorder:Comment,CursorLine:BlinkCmpMenuSelection,Search:None",
                    scrollbar = false,
                    draw = {
                        align_to_component = "label",
                        padding = 1,
                        gap = 1,
                        columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
                        components = {
                            kind_icon = {
                                ellipsis = false,
                                text = function(ctx)
                                    if ctx.item.source_name == "Ripgrep" then
                                        ctx.kind_icon = " "
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
                    auto_show = false,
                    border = vim.g.border,
                    winhighlight = "Normal:Normal,FloatBorder:Comment,CursorLine:BlinkCmpMenuSelection,Search:None",
                },
                signature_help = {
                    auto_show = false,
                    border = vim.g.border,
                    winhighlight = "Normal:Normal,FloatBorder:Comment,CursorLine:BlinkCmpMenuSelection,Search:None",
                },
                ghost_text = { enabled = true },
            },
        },
    },
    {
        "mfussenegger/nvim-dap",
        keys = {
            -- stylua: ignore start
            { "<F1>", function() require("dap").up() end, "Stack up" },
            { "<F2>", function() require("dap").down() end, "Stack down" },
            { "<F5>", function() require("dap").continue() end, "Continue program execution" },
            { "<F6>", function() require("dap").pause() end, "Pause program execution" },
            { "<F8>", function() require("dap").repl.open() end, "Open debug REPL" },
            { "<F9>", function() require("dap").toggle_breakpoint() end, "Toggle breakpoint" },
            { "<F10>", function() require("dap").step_over() end, "Step over" },
            { "<F11>", function() require("dap").step_into() end, "Step into" },
            { "<F17>", function() require("dap").terminate() end, "Terminate debug session" },
            { "<F23>", function() require("dap").step_out() end, "Step out" },
            { "<F41>", function() require("dap").restart() end, "Restart debug session" },
            { "<F21>", function() require("dap").set_breakpoint(nil, vim.fn.input("Breakpoint condition: ")) end, "Set conditional breakpoint" },
            { "<F45>", function() require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: ")) end, "Set logpoint" },
            -- stylua: ignore end
        },
    },
}
