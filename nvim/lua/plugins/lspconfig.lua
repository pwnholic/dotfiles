return {
    "neovim/nvim-lspconfig",
    opts = {
        codelens = { enabled = false },
        inlay_hints = { enabled = false, exclude = {} },
        diagnostics = { float = { border = vim.g.border } },
        servers = {},
        setup = {
            gopls = function()
                return true
            end,
        },
    },
}
