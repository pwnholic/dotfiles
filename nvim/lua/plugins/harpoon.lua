return {
    "ThePrimeagen/harpoon",
    config = function()
        local harpoon = require("harpoon")

        harpoon:setup({
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = false,
                key = function()
                    return LazyVim.root({ normalize = true })
                end,
            },
            default = {
                get_root_dir = function()
                    return LazyVim.root({ normalize = true })
                end,
            },
        })
        harpoon:extend({
            UI_CREATE = function(cx)
                vim.keymap.set("n", "<A-v>", function()
                    return harpoon.ui:select_menu_item({ vsplit = true })
                end, { buffer = cx.bufnr })

                vim.keymap.set("n", "<A-s>", function()
                    return harpoon.ui:select_menu_item({ split = true })
                end, { buffer = cx.bufnr })

                vim.keymap.set("n", "<A-t>", function()
                    return harpoon.ui:select_menu_item({ tabedit = true })
                end, { buffer = cx.bufnr })
            end,
        })
        return harpoon
    end,
    keys = function()
        local harpoon_window = { ui_width_ratio = 0.45, border = vim.g.border, title = "", height_in_lines = 9 }
        local keys = {
            {
                "<leader>h",
                function()
                    return require("harpoon").ui:toggle_quick_menu(require("harpoon"):list(), harpoon_window)
                end,
                desc = "Harpoon Quick Menu",
            },
            {
                "<A-space>",
                function()
                    return require("harpoon").ui:toggle_quick_menu(require("harpoon"):list(), harpoon_window)
                end,
                desc = "Harpoon Quick Menu",
            },
            {
                "<A-a>",
                function()
                    vim.notify("Add file to Harpoon list", 2, { title = "Harpoon" })
                    return require("harpoon"):list():add()
                end,
                desc = "Harpoon File",
            },
        }
        for i = 1, 9 do
            table.insert(keys, {
                "<leader>" .. i,
                function()
                    return require("harpoon"):list():select(i)
                end,
            })
        end
        return keys
    end,
}
