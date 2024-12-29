return {
    "ThePrimeagen/harpoon",
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
