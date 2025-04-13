---@diagnostic disable: param-type-mismatch
return {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
        { "<leader>e", vim.cmd.Oil, desc = "Open File Explorer" },
        {
            "<leader>E",
            function()
                return vim.cmd.Oil({ args = { LazyVim.root() } })
            end,
            desc = "Open File Explorer (Root)",
        },
    },
    dependencies = { "echasnovski/mini.icons", opts = {} },
    init = function()
        vim.api.nvim_create_autocmd("BufEnter", {
            nested = true,
            callback = vim.schedule_wrap(function(info)
                local bufnr = info.buf
                local autocmd_id = info.id

                if
                    not vim.api.nvim_buf_is_valid(bufnr)
                    or vim.fn.bufwinid(bufnr) == -1
                    or vim.bo[bufnr].bt ~= ""
                    or vim.api.nvim_buf_get_name(bufnr) == ""
                then
                    return
                end

                local bufname = vim.api.nvim_buf_get_name(bufnr)
                local stat = vim.uv.fs_stat(bufname)
                if not stat or stat.type ~= "directory" then
                    return
                end

                pcall(require, "oil")
                pcall(vim.api.nvim_del_autocmd, autocmd_id)

                if vim.api.nvim_buf_is_valid(bufnr) then
                    vim.api.nvim_buf_call(
                        bufnr,
                        vim.schedule_wrap(function()
                            pcall(vim.cmd.edit, { bang = true, mods = { keepjumps = true } })
                        end)
                    )
                end
            end),
        })
    end,
    opts = {
        default_file_explorer = true,
        columns = { "icon", add_padding = true },
        buf_options = { buflisted = false, bufhidden = "hide" },
        win_options = {
            number = false,
            relativenumber = false,
            wrap = false,
            signcolumn = "no",
            cursorcolumn = false,
            foldcolumn = "0",
            spell = false,
            list = false,
            conceallevel = 3,
            concealcursor = "nvic",
        },
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        prompt_save_on_select_new_entry = true,
        cleanup_delay_ms = 10,
        lsp_file_methods = {
            enabled = true,
            timeout_ms = 1000,
            autosave_changes = false,
        },
        constrain_cursor = "editable",
        watch_for_changes = true,
        keymaps = {
            ["g?"] = { "actions.show_help", mode = "n" },
            ["<CR>"] = "actions.select",
            ["<A-s>"] = { "actions.select", opts = { vertical = true } },
            ["<A-h>"] = { "actions.select", opts = { horizontal = true } },
            ["<A-t>"] = { "actions.select", opts = { tab = true } },
            ["<C-p>"] = "actions.preview",
            ["<C-c>"] = { "actions.close", mode = "n" },
            ["<F5>"] = "actions.refresh",
            ["-"] = { "actions.parent", mode = "n" },
            ["_"] = { "actions.open_cwd", mode = "n" },
            ["`"] = { "actions.cd", mode = "n" },
            ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
            ["gs"] = { "actions.change_sort", mode = "n" },
            ["gx"] = "actions.open_external",
            ["g."] = { "actions.toggle_hidden", mode = "n" },
            ["g\\"] = { "actions.toggle_trash", mode = "n" },
            ["gt"] = {
                desc = "Toggle detail view",
                callback = function()
                    local config = require("oil.config")
                    if #config.columns == 1 then
                        require("oil").set_columns({
                            {
                                "type",
                                icons = {
                                    directory = "d",
                                    fifo = "p",
                                    file = "-",
                                    link = "l",
                                    socket = "s",
                                },
                                highlight = function(type_str)
                                    return setmetatable({
                                        ["-"] = "OilTypeFile",
                                        ["d"] = "OilTypeDir",
                                        ["p"] = "OilTypeFifo",
                                        ["l"] = "OilTypeLink",
                                        ["s"] = "OilTypeSocket",
                                    }, {
                                        __index = function()
                                            return "OilTypeFile"
                                        end,
                                    })[type_str]
                                end,
                            },
                            {
                                "permissions",
                                highlight = function(permission_str)
                                    local hls = {}
                                    for i = 1, #permission_str do
                                        local char = permission_str:sub(i, i)
                                        table.insert(hls, {
                                            setmetatable({
                                                ["-"] = "OilPermissionNone",
                                                ["r"] = "OilPermissionRead",
                                                ["w"] = "OilPermissionWrite",
                                                ["x"] = "OilPermissionExecute",
                                                ["s"] = "OilPermissionSetuid",
                                            }, {
                                                __index = function()
                                                    return "OilDir"
                                                end,
                                            })[char],
                                            i - 1,
                                            i,
                                        })
                                    end
                                    return hls
                                end,
                            },
                            { "size", highlight = "Number" },
                            { "mtime", highlight = "String" },
                            {
                                "icon",
                                add_padding = false,
                            },
                        })
                    else
                        require("oil").set_columns({ "icon" })
                    end
                end,
            },
        },
        use_default_keymaps = false,
        view_options = {
            is_hidden_file = function(name, bufnr)
                if not vim.api.nvim_buf_is_loaded(bufnr) then
                    return
                end
                local is_dot = name:match("^%.") ~= nil
                local is_hidden = {}
                return vim.tbl_contains(is_hidden, name) or is_dot
            end,
            ---@diagnostic disable-next-line: unused-local
            is_always_hidden = function(name, bufnr)
                if not vim.api.nvim_buf_is_loaded(bufnr) then
                    return
                end
                return false
            end,
            case_insensitive = false,
            ---@diagnostic disable-next-line: unused-local
            highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
                return nil
            end,
        },
        preview_win = {
            update_on_cursor_moved = true,
            preview_method = "fast_scratch",
            disable_preview = function(filename)
                local nopreview = { ".env", ".envrc", "secret", "secret.key" }
                if vim.tbl_contains(nopreview, filename) then
                    return true
                end
                return false
            end,
            win_options = { winblend = 0 },
        },
        confirmation = {
            max_width = { 100, 0.6 }, -- means "the lesser of 100 columns or 80% of total"
            min_width = { 40, 0.4 }, -- means "the greater of 40 columns or 40% of total"
            max_height = { 80, 0.9 }, -- means "the lesser of 80 columns or 90% of total"
            min_height = { 5, 0.1 }, -- means "the greater of 5 columns or 10% of total"
            border = vim.g.boder,
            win_options = { winblend = 0 },
        },
        progress = { border = vim.g.border },
        ssh = { border = vim.g.border },
        keymaps_help = { border = vim.g.border },
        float = { border = vim.g.border, win_options = { winblend = 0 } },
    },
    config = function(_, opts)
        local oil = require("oil")

        local function lcd(dir)
            local ok = pcall(vim.api.nvim_cmd, { cmd = "lcd", args = { dir } }, { output = false })
            if not ok then
                vim.notify("[oil.nvim] failed to cd to " .. dir, vim.log.levels.WARN)
            end
        end

        local groupid = vim.api.nvim_create_augroup("OilSetup", {})
        vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged" }, {
            group = groupid,
            pattern = "oil://*",
            callback = function(info)
                local buf = info.buf
                if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].ft ~= "oil" then
                    return
                end

                vim.api.nvim_buf_call(buf, function()
                    ---@diagnostic disable-next-line: param-type-mismatch
                    local oildir = vim.fs.normalize(oil.get_current_dir())
                    if vim.fn.isdirectory(oildir) == 0 then
                        return
                    end

                    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
                        vim.api.nvim_win_call(win, function()
                            lcd(oildir)
                        end)
                    end
                end)
            end,
        })

        -- Directory change handler for non-oil buffers
        vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileChangedShellPost" }, {
            group = groupid,
            callback = function(info)
                if info.file == "" or vim.bo[info.buf].buftype ~= "" then
                    return
                end
                if vim.api.nvim_buf_is_valid(info.buf) then
                    for _, win in ipairs(vim.fn.win_findbuf(info.buf)) do
                        if vim.api.nvim_win_is_valid(win) then
                            vim.api.nvim_win_call(win, function()
                                lcd(vim.uv.cwd() or LazyVim.root())
                            end)
                            break -- Only need to do this once per buffer
                        end
                    end
                end
            end,
        })

        -- Initialize existing oil buffers
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].ft == "oil" then
                vim.api.nvim_buf_call(buf, function()
                    local oildir = vim.fs.normalize(oil.get_current_dir())
                    if vim.fn.isdirectory(oildir) == 1 then
                        lcd(oildir)
                    end
                end)
            end
        end

        oil.setup(opts)
    end,
}
