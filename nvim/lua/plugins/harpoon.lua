return {
    "ThePrimeagen/harpoon",
    config = function()
        local harpoon = require("harpoon")
        harpoon:setup()
        harpoon:extend({
            UI_CREATE = function(cx)
                vim.keymap.set("n", "<C-v>", function()
                    harpoon.ui:select_menu_item({ vsplit = true })
                end, { buffer = cx.bufnr })

                vim.keymap.set("n", "<C-s>", function()
                    harpoon.ui:select_menu_item({ split = true })
                end, { buffer = cx.bufnr })

                vim.keymap.set("n", "<C-t>", function()
                    harpoon.ui:select_menu_item({ tabedit = true })
                end, { buffer = cx.bufnr })
            end,
        })
    end,
    keys = {
        {
            "<leader>h",
            function()
                local harpoon = require("harpoon")
                harpoon.ui:toggle_quick_menu(
                    harpoon:list(),
                    { ui_width_ratio = 0.45, border = vim.g.border, title = "" }
                )
            end,
            desc = "Harpoon Quick Menu",
        },
        {
            "<A-space>",
            function()
                local harpoon = require("harpoon")
                harpoon.ui:toggle_quick_menu(
                    harpoon:list(),
                    { ui_width_ratio = 0.45, border = vim.g.border, title = "" }
                )
            end,
            desc = "Harpoon Quick Menu",
        },
        {
            "<A-a>",
            function()
                require("harpoon"):list():add()
                local msg = "Add this file to harpoon list"
                vim.notify(msg, 2, { title = "Harpoon" })
            end,
            desc = "Harpoon File",
        },
    },
}
