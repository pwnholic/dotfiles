return {
    "neovim/nvim-lspconfig",
    opts = {
        codelens = { enabled = false },
        inlay_hints = { enabled = false, exclude = {} },
        diagnostics = {
            float = { border = vim.g.border },
            virtual_text = { spacing = 4, source = "if_many", prefix = " " },
        },
        servers = {},
        setup = {
            gopls = function()
                return true
            end,
        },
    },
}
