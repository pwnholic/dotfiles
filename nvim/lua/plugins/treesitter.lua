return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = "all",
            sync_install = false,
            ignore_install = {},
            highlight = {
                disable = function(_, buf)
                    if vim.bo[buf].filetype ~= "bigfile" then
                        return false
                    end
                    return true
                end,
            },
        },
    },
}
