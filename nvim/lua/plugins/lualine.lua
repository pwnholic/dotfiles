return {
    {
        "nvim-lualine/lualine.nvim",
        opts = {
            sections = {
                lualine_y = {},
                lualine_z = {},
            },
        },
    },
    {
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

            table.insert(opts.sections.lualine_z, { "progress", separator = " ", padding = { left = 1, right = 0 } })
            table.insert(opts.sections.lualine_z, { "location", padding = { left = 0, right = 1 } })

            table.insert(opts.sections.lualine_x, {
                "tabs",
                show_modified_status = false,
                tabs_color = {
                    active = "LualineTabActive",
                    inactive = "LualineTabInActive",
                },
            })

            table.insert(opts.sections.lualine_y, {
                function()
                    local lsp_name = {}
                    local bufnr = vim.api.nvim_get_current_buf() or 0
                    if not vim.api.nvim_buf_is_valid(bufnr) then
                        return
                    else
                        for _, server in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
                            table.insert(lsp_name, server.name)
                        end
                        return table.concat(lsp_name, " ")
                    end
                end,
                cond = function()
                    local bufnr = vim.api.nvim_get_current_buf() or 0
                    if not vim.api.nvim_buf_is_valid(bufnr) then
                        return false
                    end
                    return #vim.lsp.get_clients({ bufnr = bufnr }) > 0 and true
                end,
            })
        end,
    },
}
