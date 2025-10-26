return {
    "folke/sidekick.nvim",
    opts = {
        nes = {
            enabled = function(buf)
                return vim.g.sidekick_nes ~= false and vim.b.sidekick_nes ~= false
            end,
            debounce = 150,
            trigger = {
                events = { "ModeChanged i:n", "TextChanged", "User SidekickNesDone" },
            },
            clear = {
                events = { "TextChangedI", "InsertEnter" },
                esc = true, -- clear next edit suggestions when pressing <Esc>
            },
            diff = { inline = "words" },
        },
        cli = { watch = true },
        picker = "snacks",
    },
}
