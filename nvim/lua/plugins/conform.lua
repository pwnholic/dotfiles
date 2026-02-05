return {
    "stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            fish = { "fish_indent" },
            sh = { "shfmt" },
            go = { "goimports" },
            json = { "jq" },
            yaml = { "prettier" },
            markdown = { "prettier" },
            python = {
                "ruff_fix_all",
                -- "ruff_format"
            },
        },
        formatters = {
            ruff_fix_all = {
                command = "ruff",
                args = {
                    "check",
                    "--fix",
                    "--select=ALL",
                    "--force-exclude",
                    "--exit-zero",
                    "--no-cache",
                    "--stdin-filename",
                    "$FILENAME",
                    "-",
                },
                stdin = true,
                cwd = require("conform.util").root_file({
                    "pyproject.toml",
                    "ruff.toml",
                    ".ruff.toml",
                }),
            },
        },
    },
}
