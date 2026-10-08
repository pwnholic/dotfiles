return {
    "saghen/blink.cmp",
    dependencies = {
        { "saghen/blink.lib" },
    },
    build = function()
        require("blink.cmp").build():pwait()
    end,
    ---@type blink.cmp.Config
    opts = {
        fuzzy = {
            sorts = { "score", "sort_text", "label" },
        },
        signature = {
            enabled = true,
        },
    },
}
