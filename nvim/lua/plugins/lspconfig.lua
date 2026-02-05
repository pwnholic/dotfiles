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
                gopls = {
                    settings = {
                        gopls = {
                            gofumpt = true,
                            codelenses = {
                                gc_details = false,
                                generate = true,
                                regenerate_cgo = true,
                                run_govulncheck = true,
                                test = true,
                                tidy = true,
                                upgrade_dependency = true,
                                vendor = true,
                            },
                            hints = {
                                assignVariableTypes = true,
                                compositeLiteralFields = true,
                                compositeLiteralTypes = true,
                                constantValues = true,
                                functionTypeParameters = true,
                                parameterNames = true,
                                rangeVariableTypes = true,
                            },
                            analyses = {
                                nilness = true,
                                unusedparams = true,
                                unusedwrite = true,
                                useany = true,

                                SA1029 = true, -- reflectvaluecompare - has effective key type
                                SA4006 = true, -- value never read before overwrite
                                SA4008 = true, -- loop variable never changes
                                SA4009 = true, -- function argument overwritten before use
                                SA4010 = true, -- append result never observed
                                SA4012 = true, -- comparing with NaN
                                SA4019 = true, -- duplicate build constraints
                                SA4023 = true, -- impossible interface nil comparison
                                SA5000 = true, -- assignment to nil map
                                SA5002 = true, -- empty for loop spins
                                SA5007 = true, -- infinite recursive call
                                SA5011 = true, -- possible nil pointer dereference
                                SA6000 = true, -- regexp in loop should use Compile
                                SA6001 = true, -- map byte slice key optimization
                                SA6002 = true, -- storing non-pointer in sync.Pool
                                SA6003 = true, -- string to []byte before range

                                -- Staticcheck ST (default: off - style checks)
                                ST1000 = true, -- missing package comment
                                ST1003 = true, -- poorly chosen identifier
                                ST1005 = true, -- incorrectly formatted error string
                                ST1006 = true, -- poorly chosen receiver name
                                ST1011 = true, -- poorly chosen time.Duration variable name
                                ST1012 = true, -- poorly chosen error variable name
                                ST1013 = true, -- use HTTP status code constants
                                ST1015 = true, -- default case should be first or last
                                ST1016 = true, -- consistent method receiver names
                                ST1017 = true, -- no Yoda conditions
                                ST1019 = true, -- duplicate imports
                                ST1020 = true, -- exported function docs should start with name
                                ST1021 = true, -- exported type docs should start with name
                                ST1022 = true, -- exported var/const docs should start with name
                                ST1023 = true, -- redundant type in variable declaration

                                -- Quickfix QF (default: off - code simplification)
                                QF1001 = true, -- apply De Morgan's law
                                QF1005 = true, -- expand math.Pow
                                QF1006 = true, -- lift if+break to loop condition
                                QF1007 = true, -- merge conditional assignment
                                -- Style S (default: off - simplifications)

                                S1002 = true, -- omit bool constant comparison
                                S1005 = true, -- drop blank identifier
                                S1006 = true, -- use for {} for infinite loops
                                S1008 = true, -- simplify returning bool expression
                                S1011 = true, -- use single append for slice concatenation
                                S1016 = true, -- use type conversion instead of copying
                                S1021 = true, -- merge var decl and assignment
                                S1025 = true, -- don't use fmt.Sprintf unnecessarily
                                S1029 = true, -- range over string directly

                                -- Modern Go (Go 1.21+ features)
                                any = true,
                                bloop = true,
                                forvar = true,
                                mapsloop = true,
                                minmax = true,
                                rangeint = true,
                                slicescontains = true,
                                slicessort = true,
                                stditerators = true,
                                waitgroup = true,
                            },
                            usePlaceholders = true,
                            completeUnimported = true,
                            staticcheck = true,
                            directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
                            semanticTokens = true,
                            -- local = "github.com/pwnholic/lucy" ,
                            newGoFileHeader = true,
                            hoverKind = "FullDocumentation",
                            linkTarget = "pkg.go.dev",
                            linksInHover = true,
                            importShortcut = "Both",
                            symbolMatcher = "Fuzzy",
                            symbolScope = "all",
                            vulncheck = "Imports",
                            diagnosticsDelay = "1s",
                            diagnosticsTrigger = "Edit",
                            analysisProgressReporting = true,
                            matcher = "Fuzzy",
                            experimentalPostfixCompletions = true,
                            completeFunctionCalls = true,
                        },
                    },
                },
            },
        },
    },
}
