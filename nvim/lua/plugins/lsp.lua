return {
    "neovim/nvim-lspconfig",
    opts = {
        diagnostics = {
            virtual_text = {
                prefix = "icons",
            },
        },
        inlay_hints = {
            enabled = false,
            exclude = {},
        },
        codelens = {
            enabled = true,
        },
        folds = {
            enabled = true,
        },
        format = {
            formatting_options = nil,
            timeout_ms = 5000,
        },
        servers = {},
    },
}
