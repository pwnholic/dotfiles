return {
    {
        "nvim-lualine/lualine.nvim",
        opts = function(_, opts)
            table.insert(opts.sections.lualine_x, 1, {
                function()
                    local clients = vim.lsp.get_clients({ bufnr = 0 })
                    if #clients == 0 then
                        return ""
                    end
                    local names = {}
                    for _, client in ipairs(clients) do
                        table.insert(names, client.name)
                    end
                    return " " .. table.concat(names, ", ")
                end,
                color = function()
                    return { fg = Snacks.util.color("Function") }
                end,
            })
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        opts = function(_, opts)
            opts.sections.lualine_b = {
                {
                    "branch",
                    fmt = function(name)
                        if #name > 20 then
                            return name:sub(1, 19) .. "…"
                        end
                        return name
                    end,
                },
            }
        end,
    },
}
