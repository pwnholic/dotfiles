return {
    "lukas-reineke/indent-blankline.nvim",
    opts = {
        indent = { char = "▏", tab_char = "▏", smart_indent_cap = true },
        debounce = 200,
        scope = {
            show_exact_scope = false,
            priority = 500,
            show_start = true,
            show_end = true,
            highlight = {
                "@markup.heading.1.markdown",
                "@markup.heading.2.markdown",
                "@markup.heading.3.markdown",
                "@markup.heading.4.markdown",
                "@markup.heading.5.markdown",
                "@markup.heading.6.markdown",
            },
        },
    },
}
