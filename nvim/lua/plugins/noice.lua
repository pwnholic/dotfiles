return {
    "folke/noice.nvim",
    opts = {
        cmdline = { enabled = true, view = "cmdline" },
        notify = { enabled = true, view = "notify" },
        popupmenu = { enabled = false },
        presets = {
            bottom_search = true,
            command_palette = true,
            lsp_doc_border = true,
        },
        lsp = {
            signature = {
                enabled = true,
                view = "hover",
                auto_open = {
                    enabled = false,
                    trigger = false,
                    luasnip = false,
                    throttle = 50,
                },
                opts = { border = vim.g.border },
            },
        },
    },
}
