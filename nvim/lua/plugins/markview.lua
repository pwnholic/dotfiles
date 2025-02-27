return {
    "OXY2DEV/markview.nvim",
    ft = "markdown",
    opts = {
        yaml = { enable = true },
        markdown = {
            tables = {
                enable = true,
                parts = {
                    top = { "╭", "─", "╮", "┬" },
                    header = { "│", "│", "│" },
                    separator = { "├", "─", "┤", "┼" },
                    row = { "│", "│", "│" },
                    bottom = { "╰", "─", "╯", "┴" },
                    overlap = { "┝", "━", "┥", "┿" },
                    align_left = "╼",
                    align_right = "╾",
                    align_center = { "╴", "╶" },
                },
            },
        },
    },
}
