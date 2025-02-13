return {
    "folke/which-key.nvim",
    opts = {
        preset = "helix",
        filter = function(mapping)
            return mapping.desc and mapping.desc ~= ""
        end,
        icons = {
            breadcrumb = "",
            separator = "",
            group = "",
            ellipsis = "...",
            mappings = true,
            colors = true,
        },
    },
}
