return {
    {
        "echasnovski/mini.hipatterns",
        opts = {
            highlighters = {
                json = { pattern = [[json%s*:%s*]], group = "MiniHipatternsJson" },
                gorm = { pattern = [[gorm%s*:%s*]], group = "MiniHipatternsGorm" },
                validate = { pattern = [[validate%s*:%s*]], group = "MiniHipatternsValidate" },
                binding = { pattern = [[binding%s*:%s*]], group = "MiniHipatternsBinding" },
            },
        },
    },
    {
        "echasnovski/mini-git",
        main = "mini.git",
        cmd = "Git",
        version = false,
        config = function()
            require("mini.git").setup({
                job = { git_executable = "/usr/bin/git", timeout = 40000 },
                command = { split = "auto" },
            })
            vim.api.nvim_create_autocmd("BufEnter", {
                pattern = { "minigit://*", "git" },
                callback = function(args)
                    vim.bo[args.buf].filetype = "minigit"
                    vim.bo[args.buf].buftype = "nofile"
                end,
            })
        end,
    },
}
