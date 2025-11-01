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
        "nvim-mini/mini.icons",
        config = function(_, opts)
            local icons = require("mini.icons")
            icons.setup(opts)

            local get = icons.get
            icons.get = function(cat, name)
                return get(cat == "socket" and "file" or cat, name)
            end
        end,
    },
}
