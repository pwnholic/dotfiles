return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            inlay_hints = {
                enabled = false,
                exclude = {}, -- filetypes
            },
            codelens = {
                enabled = false,
            },
            diagnostics = {
                float = {
                    border = vim.g.border,
                },
            },
            format = {
                formatting_options = {
                    tabsize = 4,
                    insertspaces = true,
                    trimtrailingwhitespace = true,
                },
                timeout_ms = 4 * 1000, -- 4 sec
            },
            servers = {
                iwes = {},
            },
            setup = {
                marksman = function()
                    return true
                end,
            },
        },
    },
}
