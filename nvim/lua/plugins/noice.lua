return {
    "folke/noice.nvim",
    opts = {
        cmdline = { enabled = true, view = "cmdline" },
        popupmenu = { enabled = false },
        presets = {
            bottom_search = true,
            command_palette = true,
            lsp_doc_border = true,
        },
        lsp = {
            enabled = true,
            hover = { opts = { border = vim.g.border } },
            signature = { opts = { border = vim.g.border } },
            documentation = { opts = { border = vim.g.border } },
        },
    },
}
