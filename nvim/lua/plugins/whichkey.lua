return {
    "folke/which-key.nvim",
    opts = {
        preset = "helix",
        show_help = false,
        win = {
            border = vim.o.winborder,
        },
        filter = function(mapping)
            return (mapping.desc and mapping.desc ~= "")
        end,
        icons = {
            mappings = false,
            breadcrumb = " ",
            separator = " ",
            group = "+",
            ellipsis = "...",
        },
    },
}
