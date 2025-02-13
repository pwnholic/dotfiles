local harpoon_window = { ui_width_ratio = 0.45, border = vim.g.border, title = "", height_in_lines = 9 }

return {
    "ThePrimeagen/harpoon",
    config = function()
        local harpoon = require("harpoon")
        harpoon:setup({
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = false,
                key = function()
                    return os.getenv("PWD") or vim.uv.cwd() or ""
                end,
            },
            default = {
                get_root_dir = function()
                    return os.getenv("PWD") or vim.uv.cwd() or ""
                end,
                create_list_item = function(config, path)
                    local Path = require("plenary.path")

                    if vim.tbl_contains({ "oil", "trouble" }, vim.o.filetype) then
                        vim.notify(string.format("could not add this %s buffer to harpoon", vim.o.filetype), 3, { title = "harpoon" })
                        return {}
                    end

                    local current_buffer = vim.api.nvim_get_current_buf()
                    local current_window = vim.api.nvim_get_current_win()
                    local cursor_position = { 1, 0 }

                    if vim.api.nvim_buf_is_valid(current_buffer) then
                        path = Path:new(vim.api.nvim_buf_get_name(current_buffer)):make_relative(config.get_root_dir())
                    else
                        vim.notify("this buffer could not append to harpoon list", 2, { title = "harpoon" })
                        return {}
                    end

                    if vim.api.nvim_win_is_valid(current_window) then
                        cursor_position = vim.api.nvim_win_get_cursor(current_window)
                    else
                        vim.notify("this window could not append to harpoon list", 2, { title = "harpoon" })
                        return {}
                    end

                    vim.notify("Add this file to harpoon list", 2, { title = "Harpoon" })
                    return {
                        value = path or vim.fn.fnamemodify(":p:.", vim.fs.normalize(vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)))),
                        context = { row = cursor_position[1] or 0, col = cursor_position[2] or 0 },
                    }
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
        local harpoon = require("harpoon")
        local keys = {
            {
                "<leader>h",
                function()
                    return harpoon.ui:toggle_quick_menu(harpoon:list(), harpoon_window)
                end,
                desc = "Harpoon Quick Menu",
            },
            {
                "<A-space>",
                function()
                    return harpoon.ui:toggle_quick_menu(harpoon:list(), harpoon_window)
                end,
                desc = "Harpoon Quick Menu",
            },
            {
                "<A-a>",
                function()
                    return harpoon:list():add()
                end,
                desc = "Harpoon File",
            },
        }
        for i = 1, 9 do
            table.insert(keys, {
                "<leader>" .. i,
                function()
                    vim.notify(string.format("Jump to file %d", i), 2, { title = "Harpoon" })
                    return harpoon:list():select(i)
                end,
            })
        end
        return keys
    end,
}
