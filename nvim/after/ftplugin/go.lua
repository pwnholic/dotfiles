vim.opt_local.expandtab = true

require("utils.lsp").start({
    cmd = { vim.fn.stdpath("data") .. "/mason/bin/gopls", "-remote.debug=:0" },
    name = "gopls",
    filetypes = { "go", "gomod", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },
    settings = {
        gopls = {
            gofumpt = false,
            codelenses = {
                gc_details = false,
                generate = true,
                regenerate_cgo = true,
                run_govulncheck = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
                vendor = true,
            },
            hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
            },
            analyses = {
                fieldalignment = true,
                nilness = true,
                unusedparams = true,
                unusedwrite = true,
                useany = true,
            },
            usePlaceholders = true,
            completeUnimported = true,
            staticcheck = true,
            directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
            semanticTokens = true,
        },
    },
})
