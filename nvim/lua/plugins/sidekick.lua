return {
    "folke/sidekick.nvim",
    opts = {
        nes = {
            enabled = true,
            debounce = 100,
            diff = { inline = "words" },
        },
        cli = {
            watch = true,
            win = {
                layout = "right",
                split = { width = 80, height = 20 },
            },
            mux = {
                backend = "tmux",
                enabled = true,
                create = "terminal",
            },
            tools = {
                opencode = {
                    cmd = { "opencode" },
                    env = { OPENCODE_THEME = "system" },
                },
                claude = { cmd = { "claude", "--dangerously-skip-permissions" } },
            },
            prompts = {
                refactor = "Refactor {this} to be more readable and maintainable",
                security = "Review {file} for security vulnerabilities",
                types = "Add proper type annotations to {this}",
                perf = "Analyze {this} for performance issues and suggest improvements",
                commit = "Suggest a conventional commit message for my changes:\n{changes}",
            },
            picker = "snacks",
        },
        copilot = {
            status = {
                enabled = true,
                level = vim.log.levels.WARN,
            },
        },
    },
}
