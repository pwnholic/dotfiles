return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
        opts.extensions = {
            "quickfix",
            "aerial",
            "chadtree",
            "ctrlspace",
            "fern",
            "fzf",
            "lazy",
            "man",
            "mason",
            "mundo",
            "neo-tree",
            "nerdtree",
            "nvim-dap-ui",
            "nvim-tree",
            "oil",
            "overseer",
            "symbols-outline",
            "toggleterm",
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
                    return table.concat(client_names, " ")
                end
            end,
            cond = function()
                return next(vim.lsp.get_clients({ bufnr = 0 })) ~= nil
            end,
            color = "LualineLspClient",
        })
    end,
}
