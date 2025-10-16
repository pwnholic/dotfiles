return {
    "folke/sidekick.nvim",
    opts = {
        jump = { jumplist = true },
        signs = { enabled = true, icon = " " },
        nes = {
            enabled = function(buf)
                local is_valid = vim.api.nvim_buf_is_valid(buf)
                return vim.g.sidekick_nes ~= false and vim.b.sidekick_nes ~= false and is_valid
            end,
            debounce = 120,
            trigger = {
                events = { "InsertLeave", "TextChanged", "User SidekickNesDone" },
            },
            clear = {
                events = { "TextChangedI", "InsertEnter" },
                esc = true,
            },
            diff = { inline = "words" },
        },
        cli = {
            watch = true,
            win = {
                layout = "right",
                split = {
                    width = 80, -- lebar terminal
                    height = 20, -- tinggi jika layout bukan vertical
                },
                wo = { number = false, relativenumber = false },
                bo = { bufhidden = "hide" },
                keys = {
                    hide_n = { "q", "hide", mode = "n", desc = "close OpenCode terminal" },
                    hide_ctrl_dot = { "<C-.>", "hide", mode = "nt", desc = "hide the window" },
                    stopinsert = { "<C-q>", "stopinsert", mode = "t", desc = "exit insert" },
                    prompt = { "<C-p>", "prompt", mode = "t", desc = "insert context or question" },
                    nav_left = { "<C-h>", "nav_left", expr = true },
                    nav_down = { "<C-j>", "nav_down", expr = true },
                    nav_up = { "<C-k>", "nav_up", expr = true },
                    nav_right = { "<C-l>", "nav_right", expr = true },
                },
            },
            tools = {
                opencode = {
                    cmd = { "opencode" },
                    env = {
                        OPENCODE_THEME = "system",
                        EDITOR = "nvim",
                    },
                },
            },
        },
    },
}
