return {
    "nvim-mini/mini-git",
    version = false,
    cmd = "Git",
    config = function()
        require("mini.git").setup({
            job = {
                git_executable = "git",
                timeout = 30000,
            },
            command = {
                split = "auto",
            },
        })
    end,
}
