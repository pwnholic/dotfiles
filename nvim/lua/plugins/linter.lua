local SEVERITIES = {
    ERROR = vim.diagnostic.severity.ERROR,
    WARN = vim.diagnostic.severity.WARN,
    INFO = vim.diagnostic.severity.INFO,
    HINT = vim.diagnostic.severity.HINT,
}

local function get_args()
    local ok, version = pcall(vim.fn.system, { "golangci-lint", "version" })
    if not ok then
        return nil
    end

    local cur_buf = vim.api.nvim_buf_get_name(0)
    local base = { "run", "--issues-exit-code=0", "--show-stats=false", cur_buf }

    if version:find("version v?1%.") then
        return vim.list_extend(
            { "--out-format", "json", "--print-issued-lines=false", "--print-linter-name=false" },
            base
        )
    end

    local args = vim.iter({
        "json",
        "text",
        "tab",
        "html",
        "checkstyle",
        "code-climate",
        "junit-xml",
        "teamcity",
        "sarif",
    })
        :map(function(fmt)
            return string.format("--output.%s.path=%s", fmt, fmt == "json" and "stdout" or "")
        end)
        :totable()
    if not version:find("version v?2%.0%.") then
        table.insert(args, "--path-mode=abs")
    end
    return vim.list_extend(args, base)
end

local function parse_output(output, bufnr, cwd)
    if output == "" then
        return {}
    end

    local ok, decoded = pcall(vim.json.decode, output)
    if not ok or not decoded.Issues or type(decoded.Issues) == "userdata" then
        return {}
    end

    local current = vim.fs.normalize(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p"))

    return vim.iter(decoded.Issues)
        :filter(function(issue)
            local linted = vim.fs.normalize(vim.fn.fnamemodify(cwd .. "/" .. issue.Pos.Filename, ":p"))
            return current == issue.Pos.Filename or current == linted
        end)
        :map(function(issue)
            local line = math.max(0, (issue.Pos.Line or 1) - 1)
            local col = math.max(0, (issue.Pos.Column or 1) - 1)
            return {
                lnum = line,
                col = col,
                end_lnum = line,
                end_col = col,
                severity = SEVERITIES[issue.Severity] or SEVERITIES.WARN,
                source = issue.FromLinter,
                message = issue.Text,
            }
        end)
        :totable()
end

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
                cmd = "golangci-lint",
                append_fname = false,
                stdin = false,
                args = get_args(),
                stream = "stdout",
                parser = parse_output,
            },
        },
    },
}
