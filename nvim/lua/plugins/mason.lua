return {
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = {
                -- existing: formatters / LSP
                "prettier",
                "ruff",
                "rust-analyzer",
                -- linters (auto-installed when the binary is missing)
                "selene",
                "golangci-lint",
                "shellcheck",
                "oxlint",

                "delve",
            }
        end,
    },
}
