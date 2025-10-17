return {
    "neovim/nvim-lspconfig",
    opts = {
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
            timeout_ms = nil,
        },
        servers = {},
    },
}
