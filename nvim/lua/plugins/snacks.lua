return {
    "folke/snacks.nvim",
    opts = {
        indent = {
            indent = {
                enabled = true,
                char = "▏",
                blank = " ",
                only_scope = false,
                only_current = false,
                hl = "SnacksIndent",
            },
            scope = {
                enabled = true,
                char = "▏",
                underline = true,
                hl = {
                    "@markup.heading.1.markdown",
                    "@markup.heading.2.markdown",
                    "@markup.heading.3.markdown",
                    "@markup.heading.4.markdown",
                    "@markup.heading.5.markdown",
                    "@markup.heading.6.markdown",
                },
            },
            filter = function(buf)
                return vim.g.snacks_indent ~= false
                    and vim.b[buf].snacks_indent ~= false
                    and vim.bo[buf].buftype == ""
                    and not vim.tbl_contains({
                        "lazy",
                        "noice",
                        "fzf",
                        "mason",
                        "markdown",
                        "oil_preview",
                        "help",
                        "dbout",
                        "bigfile",
                        "log",
                    }, vim.bo[buf].filetype)
            end,
        },
        dashboard = {
            preset = {
                header = [[
██╗    ██╗  █████╗  ███╗   ██╗ ██╗      ██████╗  █████╗  ███╗   ██╗  ██████╗  ██╗  ██╗ ███████╗ ███╗   ███╗  █████╗  ███╗   ██╗
██║    ██║ ██╔══██╗ ████╗  ██║ ██║     ██╔════╝ ██╔══██╗ ████╗  ██║ ██╔════╝  ██║ ██╔╝ ██╔════╝ ████╗ ████║ ██╔══██╗ ████╗  ██║
██║ █╗ ██║ ███████║ ██╔██╗ ██║ ██║     ██║      ███████║ ██╔██╗ ██║ ██║  ███╗ █████╔╝  █████╗   ██╔████╔██║ ███████║ ██╔██╗ ██║
██║███╗██║ ██╔══██║ ██║╚██╗██║ ██║     ██║      ██╔══██║ ██║╚██╗██║ ██║   ██║ ██╔═██╗  ██╔══╝   ██║╚██╔╝██║ ██╔══██║ ██║╚██╗██║
╚███╔███╔╝ ██║  ██║ ██║ ╚████║ ██║     ╚██████╗ ██║  ██║ ██║ ╚████║ ╚██████╔╝ ██║  ██╗ ███████╗ ██║ ╚═╝ ██║ ██║  ██║ ██║ ╚████║
 ╚══╝╚══╝  ╚═╝  ╚═╝ ╚═╝  ╚═══╝ ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═╝  ╚═══╝  ╚═════╝  ╚═╝  ╚═╝ ╚══════╝ ╚═╝     ╚═╝ ╚═╝  ╚═╝ ╚═╝  ╚═══╝
]],
            },
            formats = {
                key = function(item)
                    return { { "[ ", hl = "special" }, { item.key, hl = "key" }, { " ]", hl = "special" } }
                end,
                header = { "%s", align = "center" },
                footer = { "%s", align = "center" },
            },
            sections = {
                { section = "header", padding = 1 },
                { section = "keys", gap = 1, padding = 1 },
                { section = "startup", gap = 1, padding = 1 },
            },
        },
    },
}
