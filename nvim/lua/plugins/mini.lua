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
        "nvim-mini/mini.files",
        version = false,
        config = function()
            require("mini.files").setup({
                options = {
                    permanent_delete = false,
                    use_as_default_explorer = false,
                },
                windows = {
                    max_number = math.huge,
                    preview = false,
                    width_focus = 45,
                    width_nofocus = 20,
                    width_preview = 0,
                },
            })
        end,
    },
}
