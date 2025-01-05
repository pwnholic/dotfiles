return {
    "folke/noice.nvim",
    opts = {
        cmdline = { enabled = true, view = "cmdline", format = { input = { view = "cmdline" } } },
        notify = { enabled = true, view = "notify" },
        popupmenu = { enabled = false },
        presets = {
            bottom_search = true,
            command_palette = true,
            long_message_to_split = false,
            inc_rename = false,
            lsp_doc_border = true,
        },
        lsp = {
            hover = { opts = { border = vim.g.border } },
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
            documentation = {
                opts = { border = vim.g.border },
            },
        },
    },
}
