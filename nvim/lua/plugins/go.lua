return {
    "ray-x/go.nvim",
    branch = "master",
    ft = { "go", "gomod" },
    opts = {
        goimports = "goimports",
        lsp_keymaps = false,
        lsp_cfg = true,
        icons = false,
        trouble = true,
        tag_transform = "snakecase",
        tag_options = "json=",
        dap_debug_keymap = false,
        null_ls = false,
        lsp_inlay_hints = { enable = false },
        diagnostic = {
            underline = true,
            update_in_insert = false,
            virtual_text = {
                spacing = 4,
                source = "if_many",
                prefix = "●",
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
        },
        go_input = vim.ui.input,
        go_select = vim.ui.select,
    },
}
