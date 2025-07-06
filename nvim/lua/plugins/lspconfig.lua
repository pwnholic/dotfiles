return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            inlay_hints = {
                enabled = false,
                exclude = {}, -- filetypes
            },
            codelens = {
                enabled = false,
            },
            diagnostics = {
                signs = {
                    linehl = { [vim.diagnostic.severity.ERROR] = "ErrorMsg" },
                    numhl = { [vim.diagnostic.severity.WARN] = "WarningMsg" },
                },
                float = {
                    border = vim.g.border,
                },
            },
            format = {
                formatting_options = {
                    tabsize = 4,
                    insertspaces = true,
                    trimtrailingwhitespace = true,
                },
                timeout_ms = 4 * 1000, -- 4 sec
            },
            servers = {
                solidity_ls = {},
                iwes = {},
            },
            setup = {
                marksman = function()
                    return true
                end,
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        opts = function()
            local lspconfig = require("lspconfig")
            local lsp_setup = require("lspconfig.configs")
            if not lsp_setup.iwes then
                lsp_setup.iwes = {
                    default_config = {
                        name = "iwes",
                        cmd = { "iwes" },
                        flags = { debounce_text_changes = 500 },
                        single_file_support = true,
                        filetypes = { "markdown" },
                        root_dir = function(fname)
                            return lspconfig.util.root_pattern(".iwe", ".git")(fname)
                        end,
                    },
                }
            end
        end,
    },
}
