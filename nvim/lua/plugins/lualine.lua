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

            table.insert(opts.sections.lualine_y, {
                function()
                    local client_names = {}
                    local current_buf = vim.api.nvim_get_current_buf()
                    if vim.api.nvim_buf_is_valid(0) then
                        for _, server in pairs(vim.lsp.get_clients({ bufnr = current_buf })) do
                            table.insert(client_names, server.name)
                        end
                        return string.format("%s", table.concat(client_names, " "))
                    end
                end,
                cond = function()
                    return next(vim.lsp.get_clients({ bufnr = 0 })) ~= nil
                end,
                -- color = "LualineLspClient",
            })

            table.insert(opts.sections.lualine_x, {
                function()
                    local ok, pomo = pcall(require, "pomo")
                    if not ok then
                        return ""
                    end
                    local timer = pomo.get_first_to_finish()
                    if timer == nil then
                        return ""
                    end
                    return string.format("󰣠  %s", tostring(timer))
                end,
                color = "PomoTimer",
            })
        end,
    },
}
