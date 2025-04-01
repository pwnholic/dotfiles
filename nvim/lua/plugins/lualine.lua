return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
        opts.extensions = {
            "quickfix",
            "fzf",
            "lazy",
            "man",
            "mason",
            "nvim-dap-ui",
            "oil",
            "trouble",
        }
        table.insert(opts.sections.lualine_x, {
            function()
                local client_names = {}
                local current_buf = vim.api.nvim_get_current_buf()
                if vim.api.nvim_buf_is_valid(0) then
                    for _, server in pairs(vim.lsp.get_clients({ bufnr = current_buf })) do
                        table.insert(client_names, server.name)
                    end
                    return string.format("  %s", table.concat(client_names, " "))
                end
            end,
            cond = function()
                return next(vim.lsp.get_clients({ bufnr = 0 })) ~= nil
            end,
            color = "LualineLspClient",
        })
    end,
}
