return {
    "stevearc/conform.nvim",
    opts = {
        formatters_by_ft = {
            lua = { "stylua" },
            fish = { "fish_indent" },
            sh = { "shfmt" },
            go = { "goimports" },
            json = { "jq" },
            yaml = { "prettier" },
            markdown = { "prettier" },
        },
    },
}
