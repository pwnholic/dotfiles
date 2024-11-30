return {
    "stevearc/conform.nvim",
    lazy = true,
    cmd = "ConformInfo",
    opts = {
        formatters_by_ft = { sql = { "sqlfluff" } },
        formatters = {
            sqlfluff = {
                command = "sqlfluff",
                args = { "fix", "--dialect", "postgres", "--templater", "jinja", "-" },
                stdin = true,
                cwd = vim.fs.root(0, { ".git", LazyVim.root(), vim.uv.cwd() }),
                require_cwd = true,
            },
        },
    },
}
