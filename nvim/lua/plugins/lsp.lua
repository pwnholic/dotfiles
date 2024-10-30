return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            inlay_hints = { enabled = false, exclude = {} },
            servers = {
                solidity_ls = {},
                zls = {},
                -- kulala_ls = {},
                bashls = {},
                templ = {},
                fish_lsp = {},
                graphql = {},
                html = {},
                markdown_oxide = {
                    root_dir = function(fname, _)
                        return require("lspconfig").util.root_pattern(".obsidian", ".moxide.toml", ".git")(fname)
                            or LazyVim.root()
                    end,
                    on_attach = function(client, bufnr)
                        client.server_capabilities.documentFormattingProvider = false
                        client.server_capabilities.documentRangeFormattingProvider = false
                        vim.b[bufnr].autoformat = false
                    end,
                    commands = {
                        Today = {
                            function()
                                vim.lsp.buf.execute_command({ command = "jump", arguments = { "today" } })
                            end,
                            description = "Open today's daily note",
                        },
                        Tomorrow = {
                            function()
                                vim.lsp.buf.execute_command({ command = "jump", arguments = { "tomorrow" } })
                            end,
                            description = "Open tomorrow's daily note",
                        },
                        Yesterday = {
                            function()
                                vim.lsp.buf.execute_command({ command = "jump", arguments = { "yesterday" } })
                            end,
                            description = "Open yesterday's daily note",
                        },
                    },
                },
            },
            setup = {
                gopls = function()
                    return true
                end,
                marksman = function()
                    return true
                end,
            },
            diagnostics = {
                underline = true,
                update_in_insert = false,
                severity_sort = true,
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
                        [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
                        [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
                        [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
                    },
                    numhl = {
                        [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
                        [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
                        [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
                        [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
                    },
                },
                virtual_text = {
                    prefix = "",
                    spacing = 3,
                    format = function(d)
                        local severity = vim.diagnostic.severity[d.severity]
                        severity = severity:lower():gsub("(%a)(%w*)", function(first, rest)
                            return first:upper() .. rest:lower()
                        end)
                        local icons = LazyVim.config.icons.diagnostics[severity]
                        return string.format("%s %s [%s]", icons, d.message, d.source)
                    end,
                },
                float = {
                    header = setmetatable({}, {
                        __index = function(_, k)
                            local icon, icons_hl = require("mini.icons").get("file", vim.api.nvim_buf_get_name(0))
                            return ({ string.format("Diagnostics= %s  %s", icon, vim.bo.filetype), icons_hl })[k]
                        end,
                    }),
                    format = function(d)
                        return string.format("[%s] %s", d.source, d.message)
                    end,
                    source = "if_many",
                    severity_sort = true,
                    wrap = true,
                    border = vim.g.border,
                    max_width = math.floor(vim.o.columns / 2),
                    max_height = math.floor(vim.o.lines / 3),
                },
            },
        },
    },
    {
        "conform.nvim",
        opts = {
            formatters_by_ft = {
                templ = { "templ" },
                solidity = { "forge_fmt" },
                zig = { "zigfmt" },
                http = { "kulala-fmt" },
                fish = { "fish_indent" },
            },
        },
    },
}
