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
                solidity_ls = {
                        cmd = {"wake","lsp"}
                    },
                iwes = {},
                -- golangci_lint_ls = {
                --     name = "golangci",
                --     cmd = { "golangci-lint-langserver" },
                --     root_dir = function(fname)
                --         return require("lspconfig.util").root_pattern(
                --             ".golangci.yml",
                --             ".golangci.yaml",
                --             ".golangci.toml",
                --             ".golangci.json"
                --         )(fname) and vim.fs.root(0, ".git")
                --     end,
                --     init_options = {
                --         command = {
                --             "golangci-lint",
                --             "run",
                --             "--output.text.print-issued-lines=false",
                --             "--output.json.path=stdout",
                --             "--output.text.colors=true",
                --             "--show-stats=false",
                --             "--issues-exit-code=0",
                --         },
                --     },
                -- },
            },
            setup = {
                marksman = function()
                    return true
                end,
            },
        },
    },
}
