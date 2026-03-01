return {
    "stevearc/oil.nvim",
    lazy = false,
    keys = {
        {
            "<leader>e",
            function()
                require("oil").open()
            end,
            desc = "Oil: open",
        },
        {
            "<leader>E",
            function()
                require("oil").open(vim.fn.getcwd())
            end,
            desc = "Oil: open cwd",
        },
        { "-", "<cmd>Oil<cr>", desc = "Oil: parent directory" },
    },
    opts = {
        default_file_explorer = true,
        columns = { "icon" },
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        watch_for_changes = true,
        constrain_cursor = "name",
        win_options = {
            wrap = false,
            signcolumn = "no",
            cursorcolumn = false,
            foldcolumn = "0",
            spell = false,
            list = false,
            conceallevel = 3,
            concealcursor = "nvic",
            cursorline = true,
            number = false,
            relativenumber = false,
        },
        buf_options = {
            buflisted = false,
            bufhidden = "hide",
        },
        use_default_keymaps = false,
        keymaps = {
            ["g?"] = { "actions.show_help", mode = "n" },
            ["<CR>"] = "actions.select",
            ["<A-s>"] = { "actions.select", opts = { vertical = true } },
            ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
            ["<C-t>"] = { "actions.select", opts = { tab = true } },
            ["<C-p>"] = "actions.preview",
            ["<C-c>"] = { "actions.close", mode = "n" },
            ["q"] = { "actions.close", mode = "n" },
            ["<C-l>"] = "actions.refresh",
            ["-"] = { "actions.parent", mode = "n" },
            ["<BS>"] = { "actions.parent", mode = "n" },
            ["_"] = { "actions.open_cwd", mode = "n" },
            ["`"] = { "actions.cd", mode = "n" },
            ["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
            ["gs"] = { "actions.change_sort", mode = "n" },
            ["gx"] = "actions.open_external",
            ["g."] = { "actions.toggle_hidden", mode = "n" },
            ["g\\"] = { "actions.toggle_trash", mode = "n" },
            ["gy"] = { "actions.copy_entry_path", mode = "n" },
        },
        view_options = {
            show_hidden = false,
            is_hidden_file = function(name)
                return name:sub(1, 1) == "."
            end,
            is_always_hidden = function(name)
                local hidden = {
                    ["__pycache__"] = true,
                    [".venv"] = true,
                    ["venv"] = true,
                    [".mypy_cache"] = true,
                    [".pytest_cache"] = true,
                    ["target"] = true,
                    ["vendor"] = true,
                    ["node_modules"] = true,
                    [".DS_Store"] = true,
                    [".git"] = true,
                    [".ruff_cache"] = true,
                }
                return hidden[name] == true
            end,
            natural_order = "fast",
            case_insensitive = true,
            sort = {
                { "type", "asc" },
                { "name", "asc" },
            },
            highlight_filename = function(entry, is_hidden)
                if entry.type == "directory" then
                    return "@boolean"
                end
                if is_hidden then
                    return "Comment"
                end
                return nil
            end,
        },
        progress = { border = vim.o.winborder },
        confirmation = { border = vim.o.winborder },
        ssh = { border = vim.o.winborder },
        keymaps_help = { border = vim.o.winborder },
    },
    config = function(_, opts)
        require("oil").setup(opts)

        local oil = require("oil")
        local prev_dir ---@type string?

        local augroup = vim.api.nvim_create_augroup("oil_custom", { clear = true })

        -- Sync oil buffer ke directory file aktif
        vim.api.nvim_create_autocmd("BufEnter", {
            group = augroup,
            desc = "Sync oil buffer to current file directory",
            callback = function(ev)
                if vim.bo[ev.buf].filetype == "oil" then
                    return
                end

                local bt = vim.bo[ev.buf].buftype
                if bt ~= "" then
                    return
                end

                local bufname = vim.api.nvim_buf_get_name(ev.buf)
                if bufname == "" then
                    return
                end
                if bufname:match("^%w+://") then
                    return
                end

                local dir = vim.fs.dirname(bufname)
                if not dir then
                    return
                end

                local stat = vim.uv.fs_stat(dir)
                if not stat or stat.type ~= "directory" then
                    return
                end

                if dir == prev_dir then
                    return
                end
                prev_dir = dir

                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    if not vim.api.nvim_win_is_valid(win) then
                        goto continue
                    end
                    local buf = vim.api.nvim_win_get_buf(win)
                    if not vim.api.nvim_buf_is_valid(buf) then
                        goto continue
                    end
                    if vim.bo[buf].filetype ~= "oil" then
                        goto continue
                    end
                    local win_config = vim.api.nvim_win_get_config(win)
                    if win_config.relative ~= "" then
                        goto continue
                    end

                    local ok, err = pcall(vim.api.nvim_win_call, win, function()
                        oil.open(dir)
                    end)
                    if not ok then
                        vim.notify(string.format("[oil-sync] Failed to navigate: %s", err), vim.log.levels.WARN)
                    end
                    ::continue::
                end
            end,
        })

        -- Set lcd di oil window supaya terminal mengikuti directory oil
        vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
            group = augroup,
            desc = "Set lcd to oil current directory",
            callback = function(ev)
                if vim.bo[ev.buf].filetype ~= "oil" then
                    return
                end
                local dir = oil.get_current_dir(ev.buf)
                if not dir then
                    return
                end
                local win = vim.api.nvim_get_current_win()
                if not vim.api.nvim_win_is_valid(win) then
                    return
                end
                pcall(vim.cmd.lcd, dir)
            end,
        })

        -- Reset lcd saat masuk buffer biasa (non-oil)
        vim.api.nvim_create_autocmd("BufEnter", {
            group = augroup,
            desc = "Reset lcd when leaving oil buffer",
            callback = function(ev)
                if vim.bo[ev.buf].filetype == "oil" then
                    return
                end
                if vim.bo[ev.buf].buftype ~= "" then
                    return
                end
                pcall(vim.cmd, "lcd " .. vim.fn.fnameescape(vim.fn.getcwd(-1)))
            end,
        })
    end,
}
