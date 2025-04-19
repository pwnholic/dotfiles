return {
    "ray-x/go.nvim",
    ft = { "go", "gomod" },
    dependencies = {
        {
            "neovim/nvim-lspconfig",
            opts = {
                setup = {
                    gopls = function(_, opts)
                        require("go").setup({
                            gopls_cmd = { vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin", "gopls") },
                            gopls_remote_auto = false,
                            lsp_cfg = opts,
                            dap_debug = false,
                            dap_debug_keymap = false,
                            textobjects = false,
                            trouble = true,
                            lsp_document_formatting = false,
                            lsp_keymaps = false,
                            icons = false,
                            tag_options = table.concat({
                                "json=omitempty",
                                "validate=required",
                                "binding=required",
                            }, ","),
                            tag_transform = "snakecase",
                            lsp_semantic_highlights = true,
                            go_input = vim.ui.input,
                            go_select = vim.ui.select,
                            lsp_on_attach = function(client, bufnr)
                                if vim.api.nvim_buf_is_valid(bufnr) then
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
                                end
                            end,
                            diagnostic = {
                                hdlr = true,
                                underline = true,
                                update_in_insert = false,
                                virtual_text = {
                                    spacing = 4,
                                    source = "if_many",
                                    prefix = "●",
                                },
                                severity_sort = true,
                                float = {
                                    border = vim.g.border,
                                },
                                signs = {
                                    text = {
                                        [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
                                        [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
                                        [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
                                        [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
                                    },
                                },
                            },
                        })
                        return true
                    end,
                },
            },
        },
    },
}
