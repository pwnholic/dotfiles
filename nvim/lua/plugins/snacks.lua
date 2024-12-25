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
            animate = {
                enabled = true,
                style = "out",
                easing = "linear",
                duration = { step = 20, total = 500 },
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
                    and vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative ~= ""
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
██████╗  ███████╗ ███╗   ███╗  ██████╗  ██╗  ██╗    ██████╗  ███████╗ ██╗   ██╗
██╔══██╗ ██╔════╝ ████╗ ████║ ██╔═══██╗ ██║ ██╔╝    ██╔══██╗ ██╔════╝ ██║   ██║
██████╔╝ █████╗   ██╔████╔██║ ██║   ██║ █████╔╝     ██║  ██║ █████╗   ██║   ██║
██╔══██╗ ██╔══╝   ██║╚██╔╝██║ ██║   ██║ ██╔═██╗     ██║  ██║ ██╔══╝   ╚██╗ ██╔╝
██║  ██║ ███████╗ ██║ ╚═╝ ██║ ╚██████╔╝ ██║  ██╗    ██████╔╝ ███████╗  ╚████╔╝ 
╚═╝  ╚═╝ ╚══════╝ ╚═╝     ╚═╝  ╚═════╝  ╚═╝  ╚═╝    ╚═════╝  ╚══════╝   ╚═══╝  
 ]],
            },
        },
    },
}
