return {
    "neovim/nvim-lspconfig",
    opts = {
        codelens = { enabled = false },
        inlay_hints = { enabled = false, exclude = {} },
        servers = {
            -- sqls = {
            --     cmd = { "sqls" },
            --     root_dir = require("lspconfig.util").root_pattern("config.yaml", LazyVim.root()),
            --     single_file_support = true,
            --     settings = {
            --         sqls = {
            --             connections = {
            --                 {
            --                     driver = "postgresql",
            --                     dataSourceName = "host=127.0.0.1 port=5432 user=lilwiggy password=justpassword dbname=test_db sslmode=disable",
            --                 },
            --             },
            --         },
            --     },
            -- },
        },
        setup = {
            gopls = function()
                return true
            end,
        },
    },
}
