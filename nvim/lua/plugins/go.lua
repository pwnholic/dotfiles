return {
    {
        "neovim/nvim-lspconfig",
        dependencies = { { "ray-x/go.nvim", ft = { "go", "gomod" } } },
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
                        diagnostic = {
                            underline = true,
                            update_in_insert = false,
                            virtual_text = {
                                spacing = 4,
                                source = "if_many",
                                prefix = "●",
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
                        },
                    })
                    return true
                end,
            },
        },
    },
}
