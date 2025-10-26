local indent_char = "▏"

local ivy_split = {
    preview = "main",
    layout = {
        box = "vertical",
        backdrop = false,
        width = 0,
        height = 0.4,
        position = "bottom",
        border = "none",
        title = " {title} {live} {flags}",
        title_pos = "left",
        { win = "input", height = 1, border = "bottom" },
        {
            box = "horizontal",
            { win = "list", border = "none" },
            { win = "preview", title = "{preview}", width = 0.6, border = "none" },
        },
    },
}

return {
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
        picker = {
            layouts = {
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
            sources = {
                files = { layout = ivy_split },
                grep = { layout = ivy_split },
                lsp_declarations = { layout = ivy_split },
                lsp_definitions = { layout = ivy_split },
                lsp_implementations = { layout = ivy_split },
                lsp_references = { layout = ivy_split },
                lsp_symbols = { layout = ivy_split },
                lsp_type_definitions = { layout = ivy_split },
                lsp_workspace_symbols = { layout = ivy_split },
                diagnostics = { layout = ivy_split },
                diagnostics_buffer = { layout = ivy_split },
            },
        },
    },
}
