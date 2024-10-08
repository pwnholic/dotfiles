return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    config = function()
        local harpoon = require("harpoon")
        harpoon:setup({
            settings = {
                save_on_toggle = true,
                key = function()
                    return LazyVim.root()
                end,
            },
        })
        harpoon:extend({
            UI_CREATE = function(ctx)
                vim.keymap.set("n", "<C-v>", function()
                    harpoon.ui:select_menu_item({ vsplit = true })
                end, { buffer = ctx.bufnr })
                vim.keymap.set("n", "<C-s>", function()
                    harpoon.ui:select_menu_item({ split = true })
                end, { buffer = ctx.bufnr })
                vim.keymap.set("n", "<C-t>", function()
                    harpoon.ui:select_menu_item({ tabedit = true })
                end, { buffer = ctx.bufnr })
            end,
        })
    end,
    keys = function()
        return {
            {
                "<A-space>",
                function()
                    require("harpoon").ui:toggle_quick_menu(require("harpoon"):list(), { ui_width_ratio = 0.45, border = "single", title = "" })
                end,
                desc = "Harpoon List",
            },
            {
                "<leader>a",
                function()
                    vim.notify("Add to Mark", 2)
                    require("harpoon"):list():add()
                end,
                desc = "Add to Mark",
            },
            {
                "<leader>1",
                function()
                    require("harpoon"):list():select(1)
                end,
                desc = "Harpoon to File 1",
            },
            {
                "<leader>2",
                function()
                    require("harpoon"):list():select(2)
                end,
                desc = "Harpoon to File 2",
            },
            {
                "<leader>3",
                function()
                    require("harpoon"):list():select(3)
                end,
                desc = "Harpoon to File 3",
            },
            {
                "<leader>4",
                function()
                    require("harpoon"):list():select(4)
                end,
                desc = "Harpoon to File 4",
            },
            {
                "<leader>5",
                function()
                    require("harpoon"):list():select(5)
                end,
                desc = "Harpoon to File 5",
            },
            {
                "<leader>6",
                function()
                    require("harpoon"):list():select(6)
                end,
                desc = "Harpoon to File 6",
            },
            {
                "<leader>7",
                function()
                    require("harpoon"):list():select(7)
                end,
                desc = "Harpoon to File 7",
            },
            {
                "<leader>8",
                function()
                    require("harpoon"):list():select(8)
                end,
                desc = "Harpoon to File 8",
            },
            {
                "<leader>9",
                function()
                    require("harpoon"):list():select(9)
                end,
                desc = "Harpoon to File 9",
            },
        }
    end,
}
