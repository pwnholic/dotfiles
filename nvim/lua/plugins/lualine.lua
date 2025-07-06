return {
    {
        "nvim-lualine/lualine.nvim",
        opts = {
            sections = {
                lualine_b = {
                    {
                        "branch",
                        fmt = function(branch_name)
                            local max_display_length = 20
                            if branch_name:len() <= max_display_length then
                                return branch_name
                            end
                            return string.format("%s...", branch_name:sub(1, max_display_length))
                        end,
                    },
                },
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
            table.insert(opts.sections.lualine_x, {
                function()
                    local linters = require("lint").get_running()
                    if #linters > 0 then
                        return string.format("  %s", table.concat(linters, ", "))
                    end
                end,
                cond = function()
                    return #require("lint").get_running() > 0
                end,
                color = "NvimLintRun",
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
