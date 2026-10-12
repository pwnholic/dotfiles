return {
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = { "prettier", "ruff", "rust-analyzer" }
        end,
    },
}
