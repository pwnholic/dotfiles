return {
    {
        "stevearc/conform.nvim",
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.python = { "ruff_organize_imports", "ruff_format" }
            opts.formatters_by_ft.toml = { "taplo" }
            opts.formatters_by_ft.yaml = { "prettier" }
        end,
    },
}
