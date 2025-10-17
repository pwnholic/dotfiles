return {
    "mfussenegger/nvim-lint",
    opts = {
        events = { "BufWritePost" },
        linters_by_ft = {
            go = { "golangcilint" },
        },
        linters = {
            golangcilint = {
                condition = function(ctx)
                    local rule_file = {
                        ".golangci.yml",
                        ".golangci.yaml",
                        ".golangci.toml",
                        ".golangci.json",
                    }
                    local found = vim.fs.find(rule_file, { path = ctx.filename, upward = true })
                    return #found > 0 and found[1]
                end,
            },
        },
    },
}
