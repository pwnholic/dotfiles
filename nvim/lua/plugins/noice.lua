return {
    "folke/noice.nvim",
    opts = {
        cmdline = { enabled = true, view = "cmdline", format = { input = { view = "cmdline" } } },
        notify = { enabled = true, view = "notify" },
        popupmenu = { enabled = true, backend = "nui" },
        presets = {
            bottom_search = true, -- use a classic bottom cmdline for search
            command_palette = true, -- position the cmdline and popupmenu together
            long_message_to_split = false, -- long messages will be sent to a split
            inc_rename = false,
            lsp_doc_border = true, -- add a border to hover docs and signature help
        },
        lsp = {
            hover = {
                opts = { border = vim.g.border },
            },
            signature = {
                enabled = true,
                opts = { border = vim.g.border },
            },
            documentation = {
                opts = { border = vim.g.border },
            },
        },
    },
}
