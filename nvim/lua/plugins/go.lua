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
            tag_options = "json=omitempty",
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
                        legend = {
                            tokenTypes = semantic.tokenTypes,
                            tokenModifiers = semantic.tokenModifiers,
                        },
                        range = true,
                    }
                end
            end,
            lsp_keymaps = false,
            lsp_codelens = false,
            diagnostic = require("utils.lsp").diagnostics_config,
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
