local severities = {
    ERROR = vim.diagnostic.severity.ERROR,
    WARN = vim.diagnostic.severity.WARN,
    INFO = vim.diagnostic.severity.INFO,
    HINT = vim.diagnostic.severity.HINT,
}

return {
    "mfussenegger/nvim-lint",
    opts = {
        events = { "BufWritePost" },
        linters_by_ft = {
            go = { "golangcilint" },
        },
        linters = {
            golangcilint = {
                cmd = "golangci-lint",
                append_fname = false,
                args = {
                    "run",
                    "--out-format",
                    "json",
                    "--show-stats=false",
                    "--print-issued-lines=false",
                    "--print-linter-name=false",
                    function()
                        return vim.api.nvim_buf_get_name(0)
                    end,
                },
                stream = "stdout",
                ignore_exitcode = true,
                parser = function(output, bufnr, cwd)
                    if output == "" then
                        return {}
                    end
                    local decoded = vim.json.decode(output)
                    if decoded["Issues"] == nil or type(decoded["Issues"]) == "userdata" then
                        return {}
                    end
                    local diagnostics = {}
                    for _, item in ipairs(decoded["Issues"]) do
                        local curfile = vim.api.nvim_buf_get_name(bufnr)
                        local lintedfile = cwd .. "/" .. item.Pos.Filename
                        if curfile == lintedfile then
                            local sv = severities[item.Severity] or severities.WARN
                            table.insert(diagnostics, {
                                lnum = item.Pos.Line > 0 and item.Pos.Line - 1 or 0,
                                col = item.Pos.Column > 0 and item.Pos.Column - 1 or 0,
                                end_lnum = item.Pos.Line > 0 and item.Pos.Line - 1 or 0,
                                end_col = item.Pos.Column > 0 and item.Pos.Column - 1 or 0,
                                severity = sv,
                                source = item.FromLinter,
                                message = item.Text,
                            })
                        end
                    end
                    return diagnostics
                end,
            },
        },
    },
}
