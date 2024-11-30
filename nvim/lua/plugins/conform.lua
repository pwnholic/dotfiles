return {
    "stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            sql = { "sqlfluff" },
        },
        formatters = {
            sqlfluff = {
                command = "sqlfluff",
                args = { "fix", "--dialect", "postgres", "--templater", "jinja", "-" },
                stdin = true,
                cwd = require("conform.util").root_file({ ".git", LazyVim.root(), vim.uv.cwd() }),
                require_cwd = true,
            },
        },
    },
}
