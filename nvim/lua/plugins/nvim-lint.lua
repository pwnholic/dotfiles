return {
    "mfussenegger/nvim-lint",
    opts = {
        events = { "BufWritePost" },
        linters_by_ft = {
            go = { "golangci_lint" },
        },
        linters = {
            golangci_lint = {
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
                cmd = "golangci-lint",
                args = {
                    "run",
                    "--out-format=json",
                    "--path-prefix=" .. vim.fn.getcwd(),
                    vim.fn.expand("%:p"),
                },
                stdin = false,
                stream = "stdout",
                parser = function(output, _)
                    if not output or output == "" then
                        return {}
                    end
                    local ok, decoded = pcall(vim.json.decode, output)
                    if not ok or not decoded.Issues then
                        return {}
                    end

                    return vim.iter(decoded.Issues)
                        :map(function(issue)
                            return {
                                lnum = (issue.Pos.Line or 1) - 1,
                                col = (issue.Pos.Column or 1) - 1,
                                end_lnum = (issue.Pos.Line or 1) - 1,
                                end_col = (issue.Pos.Column or 1) - 1,
                                severity = vim.diagnostic.severity[issue.Severity] or vim.diagnostic.severity.WARN,
                                source = issue.FromLinter,
                                message = issue.Text,
                            }
                        end)
                        :totable()
                end,
            },
        },
    },
}
