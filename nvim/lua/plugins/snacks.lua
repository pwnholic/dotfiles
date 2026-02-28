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
    keys = {
        { "<leader>e", false },
        { "<leader>E", false },
        { "<leader>fe", false },
        { "<leader>fE", false },
        {
            "<leader>fd",
            function()
                local exclude = { ".git", "node_modules", "__pycache__", ".venv", "venv", "target", "vendor" }
                local args = vim.iter(exclude)
                    :map(function(e)
                        return { "--exclude", e }
                    end)
                    :flatten()
                    :fold({ "--type", "d", "--hidden", "--color", "never" }, function(acc, v)
                        acc[#acc + 1] = v
                        return acc
                    end)

                Snacks.picker.pick({
                    source = "directories",
                    title = "",
                    finder = function(_, ctx)
                        return require("snacks.picker.source.proc").proc({
                            cmd = "fd",
                            args = args,
                            transform = function(item)
                                item.file = item.text
                                item.dir = true
                            end,
                        }, ctx)
                    end,
                    format = "file",
                    confirm = function(picker, item)
                        picker:close()
                        if item then
                            require("oil").open(item.file)
                        end
                    end,
                    layout = { preset = "ivy", preview = false },
                })
            end,
            desc = "Find directory -> Oil",
        },
    },
    opts = {
        explorer = { enabled = false },
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
