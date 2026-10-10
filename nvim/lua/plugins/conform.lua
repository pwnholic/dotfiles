return {
    {
        "stevearc/conform.nvim",
        optional = true,
        opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            -- Only gaps: go/md/json/ts/lua/sh already covered by core + extras.
            opts.formatters_by_ft.python = { "ruff_organize_imports", "ruff_format" }
            opts.formatters_by_ft.rust = { "rustfmt" }
            opts.formatters_by_ft.toml = { "taplo" }
            opts.formatters_by_ft.yaml = { "prettier" }
        end,
    },
}
