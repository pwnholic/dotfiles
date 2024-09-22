return {
    "ray-x/go.nvim",
    branch = "master",
    ft = { "go", "gomod", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },
    opts = function()
        return {
            disable_defaults = false,
            go = "go",
            goimports = "gopls",
            gofmt = "gopls",
            fillstruct = "fillstruct",
            max_line_len = 0,
            tag_transform = "snakecase",
            tag_options = "json",
            verbose = false,
            lsp_cfg = {
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
                            fieldalignment = true,
                            nilness = true,
                            unusedparams = true,
                            unusedwrite = true,
                            useany = true,
                        },
                        usePlaceholders = true,
                        completeUnimported = true,
                        staticcheck = true,
                        directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
                        semanticTokens = true,
                    },
                },
            },
            lsp_gofumpt = false,
            lsp_on_attach = function(client, _)
                if not client.server_capabilities.semanticTokensProvider then
                    local semantic = client.config.capabilities.textDocument.semanticTokens
                    client.server_capabilities.semanticTokensProvider = {
                        full = true,
                        legend = { tokenTypes = semantic.tokenTypes, tokenModifiers = semantic.tokenModifiers },
                        range = true,
                    }
                end
            end,
            lsp_keymaps = false,
            lsp_codelens = false,
            diagnostic = {
                underline = true,
                update_in_insert = false,
                severity_sort = true,
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = require("utils.icons").diagnostics.ERROR,
                        [vim.diagnostic.severity.WARN] = require("utils.icons").diagnostics.WARN,
                        [vim.diagnostic.severity.INFO] = require("utils.icons").diagnostics.HINT,
                        [vim.diagnostic.severity.HINT] = require("utils.icons").diagnostics.INFO,
                    },
                    numhl = {
                        [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
                        [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
                        [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
                        [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
                    },
                },
                virtual_text = {
                    spacing = 4,
                    source = "if_many",
                    prefix = "",
                    format = function(d)
                        local dicons = {}
                        for key, value in pairs(require("utils.icons").diagnostics) do
                            dicons[key:upper()] = value
                        end
                        return string.format(" %s %s [%s] ", dicons[vim.diagnostic.severity[d.severity]], d.message, not vim.tbl_contains({ "lazy" }, vim.o.ft) and d.source or "")
                    end,
                },
                float = {
                    header = setmetatable({}, {
                        __index = function(_, k)
                            local icon, icons_hl = require("mini.icons").get("file", vim.api.nvim_buf_get_name(0))
                            local arr = {
                                function()
                                    return string.format("Diagnostics: %s  %s", icon, vim.bo.filetype)
                                end,
                                function()
                                    return icons_hl
                                end,
                            }
                            return arr[k]()
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
            go_input = vim.ui.input,
            go_select = vim.ui.select,
            lsp_document_formatting = false,
            lsp_inlay_hints = { enable = false },
            sign_priority = 5,
            textobjects = false,
            trouble = true,
            test_efm = false,
            luasnip = true,
            iferr_vertical_shift = 4,
        }
    end,
}
