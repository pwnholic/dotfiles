return {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
        opts.extensions = { "oil", "mason", "trouble", "nvim-dap-ui", "fzf", "man", "quickfix" }
        table.insert(opts.sections.lualine_x, {
            function()
                local names = {}
                for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
                    table.insert(names, server.name)
                end
                return table.concat(names, " ")
            end,
            cond = function()
                return vim.lsp.get_clients({ bufnr = 0 }) ~= nil
            end,
            color = function()
                return LazyVim.ui.fg("Special")
            end,
        })
    end,
}
