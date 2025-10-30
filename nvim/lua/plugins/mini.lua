return {
    {
        "nvim-mini/mini-git",
        version = false,
        cmd = "Git",
        config = function()
            require("mini.git").setup({
                job = { git_executable = "git", timeout = 30000 },
                command = { split = "auto" },
            })
        end,
    },
    {
        "lewis6991/gitsigns.nvim",
        cmd = "Gitsigns",
        opts = {
            current_line_blame = true,
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "eol",
                delay = 500,
                ignore_whitespace = false,
                virt_text_priority = 100,
                use_focus = true,
            },
        },
    },
}
