return {
    "neovim/nvim-lspconfig",
    opts = {
        codelens = { enabled = false },
        inlay_hints = { enabled = false, exclude = {} },
        servers = {},
        setup = {
            gopls = function()
                return true
            end,
        },
    },
}
