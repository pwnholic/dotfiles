return {
    {
        "folke/noice.nvim",
        opts = {
            cmdline = { enabled = true, view = "cmdline" },
            presets = { lsp_doc_border = vim.o.winborder ~= "" and true or false },
            lsp = {
                hover = {
                    opts = {
                        border = vim.o.winborder,
                    },
                },
                signature = {
                    opts = {
                        border = vim.o.winborder,
                    },
                },
                message = {
                    opts = {
                        border = vim.o.winborder,
                    },
                },
                documentation = {
                    opts = {
                        border = vim.o.winborder,
                    },
                },
            },
        },
    },
}
