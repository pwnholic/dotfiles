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
    {
        "nvim-lualine/lualine.nvim",
        optional = true,
        opts = function(_, opts)
            opts.sections = opts.sections or {}
            opts.sections.lualine_c = opts.sections.lualine_c or {}
            local function get_harpoon_info()
                local ok, harpoon = pcall(require, "harpoon")
                if not ok then
                    return 0, nil
                end
                local list = harpoon:list()
                local total = list:length()
                if total == 0 then
                    return 0, nil
                end

                local bufpath = vim.api.nvim_buf_get_name(0)
                if bufpath == "" then
                    return total, nil
                end

                local active = nil
                for i = 1, total do
                    local item = list:get(i)
                    if item then
                        local item_path = vim.fn.fnamemodify(item.value, ":p")
                        if item_path == bufpath then
                            active = i
                            break
                        end
                    end
                end
                return total, active
            end

            table.insert(opts.sections.lualine_c, 1, {
                function()
                    local total, active = get_harpoon_info()
                    if total == 0 then
                        return ""
                    end
                    if active then
                        return "󰀱 " .. active .. "/" .. total
                    end
                    return "󰀱 " .. total
                end,
                color = function()
                    local _, active = get_harpoon_info()
                    if active then
                        return { fg = "#f5a97f" }
                    end
                end,
                cond = function()
                    local ok, harpoon = pcall(require, "harpoon")
                    return ok and harpoon:list():length() > 0
                end,
            })
        end,
    },
}
