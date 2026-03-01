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
                    return #vim.fs.find({
                        ".golangci.yml",
                        ".golangci.yaml",
                        ".golangci.toml",
                        ".golangci.json",
                    }, { path = ctx.filename, upward = true }) > 0
                end,
                cmd = "golangci-lint",
                args = function()
                    return {
                        "run",
                        "--output.json.path",
                        "stdout", -- output JSON ke stdout (v2)
                        "--show-stats=false", -- tidak perlu statistik
                        "--issues-exit-code=0", -- jangan error meski ada issue
                        "--whole-files", -- tampilkan semua issue, bukan hanya diff
                        "--allow-parallel-runners", -- hindari lock jika ada instance lain
                        "--max-issues-per-linter",
                        "20", -- batasi jumlah issue per linter
                        "--max-same-issues",
                        "5", -- batasi issue duplikat
                        "--sort-order",
                        "severity", -- issue paling penting duluan
                        "--timeout",
                        "30s", -- batas waktu eksekusi
                        "--path-prefix",
                        vim.fn.getcwd(),
                        vim.fn.expand("%:p"),
                    }
                end,
                stdin = false,
                stream = "stdout",
                parser = function(output, _)
                    if not output or output == "" then
                        return {}
                    end
                    local ok, decoded = pcall(vim.json.decode, output)
                    if not ok or not decoded or not decoded.Issues then
                        return {}
                    end
                    return vim.iter(decoded.Issues)
                        :map(function(issue)
                            local pos = issue.Pos or {}
                            return {
                                lnum = (pos.Line or 1) - 1,
                                col = (pos.Column or 1) - 1,
                                end_lnum = (pos.Line or 1) - 1,
                                end_col = (pos.Column or 1) - 1,
                                severity = vim.diagnostic.severity.WARN,
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
