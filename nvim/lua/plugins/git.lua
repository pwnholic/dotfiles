return {
    {
        "echasnovski/mini-git",
        main = "mini.git",
        cmd = "Git",
        config = function()
            require("mini.git").setup({
                job = { git_executable = "/usr/bin/git", timeout = 40000 },
                command = { split = "auto" },
            })

            vim.api.nvim_create_autocmd("BufEnter", {
                pattern = "minigit://*",
                callback = function()
                    vim.opt_local.spell = false
                    vim.opt_local.number = false
                    vim.opt_local.relativenumber = false
                    vim.opt_local.signcolumn = "no"
                    vim.opt_local.foldcolumn = "0"
                    vim.opt_local.winbar = ""
                end,
            })
        end,
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
