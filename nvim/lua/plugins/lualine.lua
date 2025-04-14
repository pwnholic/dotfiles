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
                "lsp_status",
                icon = false,
                symbols = { separator = " ", done = "" },
                ignore_lsp = { "null-ls" },
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
