return {
    "neovim/nvim-lspconfig",
    opts = {
        inlay_hints = { enabled = false, exclude = {} },
        servers = {
            gopls = {
                flags = { allow_incremental_sync = true, debounce_text_changes = 500 },
                settings = {
                    gopls = {
                        experimentalPostfixCompletions = true,
                        usePlaceholders = true,
                        completeUnimported = true,
                        staticcheck = true,
                        directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
                        semanticTokens = true,
                        matcher = "Fuzzy",
                        diagnosticsDelay = "500ms",
                        symbolMatcher = "fuzzy",
                        analyses = {
                            unreachable = true,
                            ST1003 = true,
                            undeclaredname = true,
                            fillreturns = true,
                            nonewvars = true,
                            shadow = true,
                            fieldalignment = true,
                            nilness = true,
                            unusedparams = true,
                            unusedvariable = true,
                            unusedwrite = true,
                            useany = true,
                        },
                    },
                },
                init_options = { usePlaceholders = true },
            },
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
            virtual_text = { spacing = 4, source = "if_many", prefix = "󰈸 " },
            float = {
                header = setmetatable({}, {
                    __index = function(_, k)
                        local icon, icons_hl = require("mini.icons").get("file", vim.api.nvim_buf_get_name(0))
                        return ({ string.format("Diagnostics: %s  %s", icon, vim.bo.filetype), icons_hl })[k]
                    end,
                }),
                format = function(d)
                    return string.format("[%s] : %s", d.source, d.message)
                end,
                source = "if_many",
                severity_sort = true,
                wrap = true,
                border = "single",
                max_width = math.floor(vim.o.columns / 2),
                max_height = math.floor(vim.o.lines / 3),
            },
        },
    },
}
