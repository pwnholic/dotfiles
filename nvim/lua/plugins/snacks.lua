return {
    "folke/snacks.nvim",
    keys = {
        { "<leader>e", false },
        { "<leader>E", false },
    },
    opts = {
        explorer = { enabled = false },
        image = { enabled = true },
        picker = { enabled = false },
        indent = {
            indent = { char = "▏" },
            scope = { enabled = true, char = "▏" },
        },
        dashboard = {
            preset = {
                header = "██████╗  ██╗ ███████╗ ███╗   ███╗ ██╗ ██╗      ██╗       █████╗  ██╗  ██╗\n"
                    .. "██╔══██╗ ██║ ██╔════╝ ████╗ ████║ ██║ ██║      ██║      ██╔══██╗ ██║  ██║\n"
                    .. "██████╔╝ ██║ ███████╗ ██╔████╔██║ ██║ ██║      ██║      ███████║ ███████║\n"
                    .. "██╔══██╗ ██║ ╚════██║ ██║╚██╔╝██║ ██║ ██║      ██║      ██╔══██║ ██╔══██║\n"
                    .. "██████╔╝ ██║ ███████║ ██║ ╚═╝ ██║ ██║ ███████╗ ███████╗ ██║  ██║ ██║  ██║\n"
                    .. "╚═════╝  ╚═╝ ╚══════╝ ╚═╝     ╚═╝ ╚═╝ ╚══════╝ ╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝",
                keys = {
                    { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
                    {
                        icon = " ",
                        key = "g",
                        desc = "Find Text",
                        action = ":lua Snacks.dashboard.pick('live_grep')",
                    },
                    {
                        icon = " ",
                        key = "r",
                        desc = "Recent Files",
                        action = ":lua Snacks.dashboard.pick('oldfiles')",
                    },
                    {
                        icon = " ",
                        key = "c",
                        desc = "Config",
                        action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
                    },
                    { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                },
            },
        },
    },
}
