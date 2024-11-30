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
    },
}
