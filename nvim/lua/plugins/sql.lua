return {
    {
        "kristijanhusak/vim-dadbod-ui",
        dependencies = {
            { "tpope/vim-dadbod", lazy = true },
            { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
        },
    },
    {
        "saghen/blink.cmp",
        opts = {
            sources = {
                per_filetype = {
                    sql = { "dadbod", "buffer" },
                    mysql = { "dadbod", "buffer" },
                    psql = { "dadbod", "buffer" },
                },
                providers = {
                    dadbod = {
                        name = "Dadbod",
                        score_offset = 1000,
                        module = "vim_dadbod_completion.blink",
                    },
                    buffer = {
                        name = "Buffer",
                        module = "blink.cmp.sources.buffer",
                        score_offset = 100,
                        opts = {
                            prefix_min_len = 4,
                            get_bufnrs = function()
                                return vim.iter(vim.api.nvim_list_wins())
                                    :map(function(win)
                                        return vim.api.nvim_win_get_buf(win)
                                    end)
                                    :filter(function(buf)
                                        return not vim.tbl_contains({ "nofile", "bigfile" }, vim.bo[buf].buftype)
                                    end)
                                    :totable()
                            end,
                        },
                    },
                },
            },
        },
    },
}
