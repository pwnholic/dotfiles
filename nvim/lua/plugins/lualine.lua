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
                local names = {}
                for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
                    table.insert(names, server.name)
                end
                return table.concat(names, " ")
            end,
            cond = function()
                return next(vim.lsp.get_clients({ bufnr = 0 })) ~= nil
            end,
            color = "LualineLspClient",
        })
    end,
}
