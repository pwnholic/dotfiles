return {
    "neovim/nvim-lspconfig",
    opts = {
        codelens = { enabled = false },
        inlay_hints = { enabled = false, exclude = {} },
        diagnostics = {
            float = { border = vim.g.border },
            virtual_text = { spacing = 2, source = "if_many", prefix = "" },
        },
        servers = {
            solidity_ls = {
                single_file_support = true,
            },
        },
        setup = {},
    },
}
