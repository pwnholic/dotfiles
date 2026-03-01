return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            local vt = vim.diagnostic.handlers.virtual_text
            local show_handler = assert(vt.show)
            local hide_handler = vt.hide
            vim.diagnostic.handlers.virtual_text = {
                show = function(ns, bufnr, diagnostics, dopts)
                    table.sort(diagnostics, function(a, b)
                        return a.severity < b.severity
                    end)
                    return show_handler(ns, bufnr, diagnostics, dopts)
                end,
                hide = hide_handler,
            }

            opts.inlay_hints = { enabled = false, exclude = { "vue" } }
            opts.codelens = { enabled = true }

            --- Options for vim.diagnostic.config()
            ---@type vim.diagnostic.Opts
            opts.diagnostics = {
                underline = true,
                update_in_insert = false,
                virtual_text = {
                    spacing = 4,
                    source = "if_many",
                    prefix = "icons",
                },
                severity_sort = true,
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
                        [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
                        [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
                        [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
                    },
                },
                ---@type vim.diagnostic.Opts.Float
                float = {
                    source = "if_many",
                    prefix = function(diag)
                        local level = vim.diagnostic.severity[diag.severity]
                        local hl = "Diagnostic" .. level
                        return string.format(" [%s] ", level), hl
                    end,
                },
            }
        end,
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                ---@type vim.lsp.Config
                ["*"] = {
                    ---@type lsp.ClientCapabilities
                    capabilities = {
                        general = {
                            positionEncodings = { "utf-16" },
                        },
                        textDocument = {
                            semanticTokens = vim.NIL,
                        },
                    },
                },
                gopls = {
                    settings = {
                        gopls = {
                            gofumpt = true,
                            codelenses = {
                                generate = true,
                                test = true,
                                gc_details = false,
                                regenerate_cgo = false,
                                run_govulncheck = false,
                                tidy = false,
                                upgrade_dependency = false,
                                vendor = false,
                            },
                            hints = {
                                assignVariableTypes = false,
                                compositeLiteralFields = false,
                                compositeLiteralTypes = false,
                                constantValues = false,
                                functionTypeParameters = false,
                                parameterNames = true,
                                rangeVariableTypes = false,
                            },
                            analyses = {
                                nilness = true,
                                unusedparams = true,
                                unusedwrite = true,
                                useany = true,
                            },
                            usePlaceholders = true,
                            completeUnimported = true,
                            staticcheck = false,
                            directoryFilters = { "-.git", "-.vscode", "-.idea", "-node_modules", "-vendor" },
                            semanticTokens = false,
                            hoverKind = "Structured",
                            vulncheck = "Off",
                            diagnosticsDelay = "3s",
                            diagnosticsTrigger = "Save",
                            completeFunctionCalls = true,
                        },
                    },
                },
            },
        },
    },
}
