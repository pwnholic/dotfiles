return {
    {
        "echasnovski/mini-git",
        version = false,
        main = "mini.git",
        cmd = "Git",
        opts = {
            job = { git_executable = "git", timeout = 30000 },
            command = { split = "auto" },
        },
    },
    {
        "akinsho/git-conflict.nvim",
        version = false,
        event = "VeryLazy",
        opts = {
            default_mappings = { ours = "c<", theirs = "c>", none = "co", both = "c.", next = "]x", prev = "[x" },
        },
    },
    {
        "lewis6991/gitsigns.nvim",
        opts = {
            signs = {
                add = { text = "▎" },
                change = { text = "▎" },
                delete = { text = "▎" },
                topdelete = { text = "▎" },
                changedelete = { text = "▎" },
                untracked = { text = "▎" },
            },
            signs_staged = {
                add = { text = "▎" },
                change = { text = "▎" },
                delete = { text = "▎" },
                topdelete = { text = "▎" },
                changedelete = { text = "▎" },
            },
            current_line_blame = true,
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
                delay = 1000,
                ignore_whitespace = false,
                virt_text_priority = 100,
            },
        },
    },
}
