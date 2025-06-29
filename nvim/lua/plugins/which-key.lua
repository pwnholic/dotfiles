return {
    "folke/which-key.nvim",
    opts = {
        spec = {
            { "<leader>o", group = "obsidian" },
            { "<leader>p", group = "pomodoro" },
        },
        preset = "classic",
        filter = function(mapping)
            return mapping.desc and mapping.desc ~= ""
        end,
        win = {
            no_overlap = true,
            height = { min = 4, max = 9 },
        },
        layout = {
            width = { min = 20 },
            spacing = 3,
        },
        icons = {
            breadcrumb = " ",
            separator = "",
            group = "   ",
            ellipsis = "...",
            mappings = true,
            colors = true,
        },
    },
}
