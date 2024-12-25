-- local root_file = function(files)
--     return function(self, ctx)
--         return vim.fs.root(ctx.dirname, files)
--     end
-- end

return {
    "stevearc/conform.nvim",
    opts = {
        formatters_by_ft = { sql = {} },
        -- formatters = {
        --     sqlfluff = {
        --         command = "sqlfluff",
        --         args = { "fix", "--dialect", "postgres", "--templater", "jinja", "-" },
        --         stdin = true,
        --         cwd = root_file({ LazyVim.root(), vim.uv.cwd(), ".git", ".sqlfluff" }),
        --         require_cwd = true,
        --     },
        -- },
    },
}
