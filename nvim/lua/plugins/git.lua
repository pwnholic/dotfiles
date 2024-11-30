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
        "lewis6991/gitsigns.nvim",
        opts = {
            current_line_blame = true,
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "eol",
                delay = 1000,
                ignore_whitespace = false,
                virt_text_priority = 100,
                use_focus = true,
            },
        },
    },
}
