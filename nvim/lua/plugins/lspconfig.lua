return {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
        local vt = vim.diagnostic.handlers.virtual_text
        local show_handler = assert(vt.show)
        local hide_handler = vt.hide
        vim.diagnostic.handlers.virtual_text = {
            show = function(ns, bufnr, diagnostics, dopts)
                table.sort(diagnostics, function(a, b)
                    return a.severity < b.severity
                end)
                return show_handler(ns, bufnr, diagnostics, dopts)
            end,
            hide = hide_handler,
        }

        opts.inlay_hints = { enabled = false, exclude = { "vue" } }
        opts.codelens = { enabled = true }
        opts.diagnostics = {
            underline = true,
            update_in_insert = false,
            virtual_text = {
                spacing = 4,
                source = "if_many",
                prefix = "icons",
            },
            severity_sort = true,
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
                    [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
                    [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
                    [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
                },
            },
            float = {
                source = "if_many",
                prefix = function(diag)
                    local level = vim.diagnostic.severity[diag.severity]
                    local hl = "Diagnostic" .. level
                    return string.format(" [%s] ", level), hl
                end,
            },
        }
    end,
}
