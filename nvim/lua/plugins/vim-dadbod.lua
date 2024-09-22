return {
    "kristijanhusak/vim-dadbod-ui",
    version = false,
    dependencies = { "tpope/vim-dadbod", lazy = true, version = false },
    cmd = "DBUI",
    init = function()
        vim.g.db_ui_use_nerd_fonts = 1
    end,
}
