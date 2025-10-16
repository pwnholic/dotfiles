local indent_char = "▏"

return {
    {
        "folke/snacks.nvim",
        opts = {
            dashboard = {
                enabled = true,
                preset = {
                    header = table.concat({
                        " ██████╗   █████╗   ██████╗  ██████╗  ██████╗      ██████╗  ███████╗ ██╗   ██╗",
                        "██╔════╝  ██╔══██╗ ██╔════╝ ██╔═══██╗ ██╔══██╗     ██╔══██╗ ██╔════╝ ██║   ██║",
                        "██║  ███╗ ███████║ ██║      ██║   ██║ ██████╔╝     ██║  ██║ █████╗   ██║   ██║",
                        "██║   ██║ ██╔══██║ ██║      ██║   ██║ ██╔══██╗     ██║  ██║ ██╔══╝   ╚██╗ ██╔╝",
                        "╚██████╔╝ ██║  ██║ ╚██████╗ ╚██████╔╝ ██║  ██║     ██████╔╝ ███████╗  ╚████╔╝ ",
                        " ╚═════╝  ╚═╝  ╚═╝  ╚═════╝  ╚═════╝  ╚═╝  ╚═╝     ╚═════╝  ╚══════╝   ╚═══╝  ",
                    }, "\n"),
                },
            },
            indent = {
                indent = { char = indent_char },
                scope = { char = indent_char },
            },
            input = {
                win = { style = { border = vim.o.winborder } },
            },
            picker = {
                layouts = {
                    default = {
                        layout = {
                            box = "horizontal",
                            width = 0.9,
                            min_width = math.floor(vim.o.columns * 0.9), -- di kurangi 10 persen
                            height = 0.9,
                            {
                                box = "vertical",
                                border = vim.o.winborder,
                                title = "{title} {live} {flags}",
                                { win = "input", height = 1, border = "bottom" },
                                { win = "list", border = "none" },
                            },
                            { win = "preview", title = "{preview}", border = vim.o.winborder, width = 0.5 },
                        },
                    },
                    select = {
                        hidden = { "preview" },
                        layout = {
                            backdrop = false,
                            width = 0.5,
                            min_width = 80,
                            height = 0.4,
                            min_height = 3,
                            box = "vertical",
                            border = vim.o.winborder,
                            title = "{title}",
                            title_pos = "center",
                            { win = "input", height = 1, border = "bottom" },
                            { win = "list", border = "none" },
                            { win = "preview", title = "{preview}", height = 0.4, border = "top" },
                        },
                    },
                    vertical = {
                        layout = {
                            backdrop = false,
                            width = 0.5,
                            min_width = 80,
                            height = 0.8,
                            min_height = 30,
                            box = "vertical",
                            border = vim.o.winborder,
                            title = "{title} {live} {flags}",
                            title_pos = "center",
                            { win = "input", height = 1, border = "bottom" },
                            { win = "list", border = "none" },
                            { win = "preview", title = "{preview}", height = 0.4, border = "top" },
                        },
                    },
                    sidebar = {
                        preview = "main",
                        layout = {
                            backdrop = false,
                            width = 55,
                            min_width = 55,
                            height = 0,
                            position = "left",
                            border = "none",
                            box = "vertical",
                            {
                                win = "input",
                                height = 1,
                                border = vim.o.winborder,
                                title = "{title} {live} {flags}",
                                title_pos = "center",
                            },
                            { win = "list", border = "none" },
                            { win = "preview", title = "{preview}", height = 0.4, border = "top" },
                        },
                    },
                },
            },
        },
    },
}
