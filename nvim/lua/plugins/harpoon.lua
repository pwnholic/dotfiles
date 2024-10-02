return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    config = function()
        local harpoon = require("harpoon")
        harpoon:setup({
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = true,
                key = function()
                    return LazyVim.root()
                end,
            },
        })
        harpoon:extend({
            -- stylua: ignore start
            UI_CREATE = function(ctx)
                vim.keymap.set("n", "<C-v>", function() harpoon.ui:select_menu_item({ vsplit = true }) end, { buffer = ctx.bufnr })
                vim.keymap.set("n", "<C-s>", function() harpoon.ui:select_menu_item({ split = true }) end, { buffer = ctx.bufnr })
                vim.keymap.set("n", "<C-t>", function() harpoon.ui:select_menu_item({ tabedit = true }) end, { buffer = ctx.bufnr })
            end,
        })
    end,
    keys = function()
        local keys = {
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
        }
        for i = 1, 9 do
            table.insert(keys, {
                "<leader>" .. i,
                function()
                    require("harpoon"):list():select(i)
                end,
                desc = "Harpoon to File " .. i,
            })
        end
        return keys
    end,
}
