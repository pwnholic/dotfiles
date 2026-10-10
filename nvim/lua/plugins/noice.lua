-- Merges over LazyVim's noice spec; keys/routes inherited. Ownership:
-- blink owns `:` menu + signature, snacks owns input + notifier, noice owns
-- classic cmdline + hover. Requires `vim/regex/lua/bash/markdown` parsers.
return {
    {
        "folke/noice.nvim",
        opts = {
            cmdline = {
                enabled = true, -- enables the Noice cmdline UI
                view = "cmdline", -- classic bottom cmdline, not `cmdline_popup`
            },
            messages = {
                enabled = true,
                view = "notify",
                view_error = "notify",
                view_warn = "notify",
                view_history = "messages",
                view_search = "virtualtext",
            },
            popupmenu = {
                enabled = false,
                ---@type 'nui'|'cmp'
                backend = "nui",
                ---@type NoicePopupmenuItemKind|false
                kind_icons = {},
            },
            notify = {
                -- Routes through snacks notifier (`views.lua` backend order).
                enabled = true,
                view = "notify",
            },
            lsp = {
                progress = {
                    enabled = true,
                    --- @type NoiceFormat|string
                    format = "lsp_progress",
                    --- @type NoiceFormat|string
                    format_done = "lsp_progress_done",
                    throttle = 1000 / 30,
                    view = "mini",
                },
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                    -- nvim-cmp absent (blink instead); enabling calls a missing module.
                    ["cmp.entry.get_documentation"] = false,
                },
                hover = {
                    enabled = true,
                    silent = false,
                    view = nil,
                    ---@type NoiceViewOptions
                    opts = {},
                },
                signature = {
                    enabled = false,
                    auto_open = {
                        enabled = false,
                        trigger = true,
                        luasnip = true,
                        throttle = 50,
                    },
                    view = nil,
                    ---@type NoiceViewOptions
                    opts = {},
                },
                message = {
                    enabled = true,
                    view = "notify",
                    opts = {},
                },
                -- defaults for hover and signature help
                documentation = {
                    view = "hover",
                    ---@type NoiceViewOptions
                    opts = {
                        lang = "markdown",
                        replace = true,
                        render = "plain",
                        format = { "{message}" },
                        win_options = { concealcursor = "n", conceallevel = 3 },
                    },
                },
            },
            ---@type NoicePresets
            presets = {
                bottom_search = true,
                command_palette = false,
                long_message_to_split = true,
                inc_rename = false,
                lsp_doc_border = false,
            },
            throttle = 1000 / 30,
            ---@type NoiceConfigViews
            views = {
                popup = { border = { style = vim.o.winborder } },
                hover = { border = { style = vim.o.winborder } },
                cmdline_popup = { border = { style = vim.o.winborder } },
                confirm = { border = { style = vim.o.winborder } },
            }, ---@see section on views
        },
    },
}
