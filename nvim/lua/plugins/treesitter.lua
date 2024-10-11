return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = {
            ensure_installed = "all",
            sync_install = false,
            ignore_install = {},
            highlight = {
                disable = function(_, buf)
                    local max_filesize = 100 * 1024
                    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
                    if ok and stats and stats.size > max_filesize then
                        return true
                    end
                end,
            },
        },
    },
}
