return {
    "folke/sidekick.nvim",
    opts = {
        cli = {
            tools = {
                claude = { cmd = { "claude", "--dangerously-skip-permissions" } },
            },
        },
    },
}
