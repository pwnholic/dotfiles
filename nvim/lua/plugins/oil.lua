return {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = { { "<space>e", "<cmd>Oil<cr>", desc = "Open Oil Buffer" } },
    opts = function()
        local oil = require("oil")
        local icons = LazyVim.config.icons.kinds

        local function lcd(dir)
            local ok = pcall(vim.cmd.lcd, dir)
            if not ok then
                vim.notify("[oil.nvim] failed to cd to " .. dir, vim.log.levels.WARN)
            end
        end

        local groupid = vim.api.nvim_create_augroup("OilSyncCwd", {})
        vim.api.nvim_create_autocmd("BufEnter", {
            desc = "Ensure that oil buffers are not listed.",
            group = groupid,
            pattern = "oil://*",
            callback = function(info)
                vim.bo[info.buf].buflisted = false
            end,
        })

        vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged" }, {
            desc = "Set cwd to follow directory shown in oil buffers.",
            group = groupid,
            pattern = "oil://*",
            callback = function(info)
                if vim.bo[info.buf].filetype == "oil" then
                    local cwd = vim.fs.normalize(vim.fn.getcwd(vim.fn.winnr()))
                    local oildir = vim.fs.normalize(oil.get_current_dir())
                    if cwd ~= oildir and vim.uv.fs_stat(oildir) then
                        lcd(oildir)
                    end
                end
            end,
        })

        vim.api.nvim_create_autocmd("DirChanged", {
            desc = "Let oil buffers follow cwd.",
            group = groupid,
            callback = function(info)
                if vim.bo[info.buf].filetype == "oil" then
                    vim.defer_fn(function()
                        local cwd = vim.fs.normalize(vim.fn.getcwd(vim.fn.winnr()))
                        local oildir = vim.fs.normalize(oil.get_current_dir() or "")
                        if cwd ~= oildir and vim.bo.ft == "oil" then
                            oil.open(cwd)
                        end
                    end, 100)
                end
            end,
        })

        local columns = {
            {
                "type",
                icons = { directory = "d", fifo = "p", file = "-", link = "l", socket = "s" },
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
            { "size", highlight = "Special" },
            { "mtime", highlight = "Number" },
            {
                "icon",
                default_file = icons.File,
                directory = icons.Folder,
                add_padding = true,
            },
        }

        return {
            keymaps_help = { border = vim.g.border },
            float = { border = vim.g.border, win_options = { winblend = 0 } },
            preview = { border = vim.g.border, win_options = { winblend = 0 } },
            progress = { border = vim.g.border, win_options = { winblend = 0 } },
            buf_options = { buflisted = false, bufhidden = "hide" },
            win_options = {
                number = false,
                relativenumber = false,
                signcolumn = "no",
                foldcolumn = "0",
                statuscolumn = "",
                spell = false,
                list = false,
                conceallevel = 3,
                concealcursor = "nvic",
                cursorcolumn = false,
                wrap = false,
            },
            cleanup_delay_ms = false,
            lsp_file_methods = { enabled = true, timeout_ms = 1000, autosave_changes = false },
            delete_to_trash = true,
            skip_confirm_for_simple_edits = true,
            prompt_save_on_select_new_entry = true,
            use_default_keymaps = false,
            watch_for_changes = true,
            view_options = {
                show_hidden = false,
                ---@diagnostic disable-next-line: unused-local
                is_hidden_file = function(name, bufnr)
                    local m = name:match("^%.")
                    return m ~= nil
                end,
                natural_order = "fast",
                case_insensitive = false,
                sort = { { "type", "asc" }, { "name", "asc" } },
            },
            columns = { { "icon", default_file = icons.File, directory = icons.Folder, add_padding = true } },
            keymaps = {
                ["g?"] = "actions.show_help",
                ["-"] = "actions.parent",
                ["<CR>"] = "actions.select",
                ["gh"] = "actions.toggle_hidden",
                ["gs"] = "actions.change_sort",
                ["gx"] = "actions.open_external",
                ["gY"] = "actions.copy_entry_filename",
                ["g\\"] = "actions.toggle_trash",
                ["gt"] = {
                    desc = "Toggle detail view",
                    callback = function()
                        local config = require("oil.config")
                        if #config.columns == 1 then
                            oil.set_columns(columns)
                        else
                            oil.set_columns({ "icon" })
                        end
                    end,
                },
                ["K"] = "actions.preview",
                ["go"] = {
                    mode = "n",
                    buffer = true,
                    desc = "Choose an external program to open the entry under the cursor",
                    callback = function()
                        local entry = oil.get_cursor_entry()
                        local dir = oil.get_current_dir()
                        if not entry or not dir then
                            return
                        end
                        local entry_path = vim.fs.joinpath(dir, entry.name)
                        local response
                        vim.ui.input({ prompt = "Open with: ", completion = "shellcmd" }, function(r)
                            response = r
                        end)
                        if not response then
                            return
                        end
                        print("\n")
                        vim.system({ response, entry_path })
                    end,
                },
                ["gy"] = {
                    mode = "n",
                    buffer = true,
                    desc = "Yank the filepath of the entry under the cursor to a register",
                    callback = function()
                        local entry = oil.get_cursor_entry()
                        local dir = oil.get_current_dir()
                        if not entry or not dir then
                            return
                        end
                        local entry_path = vim.fs.joinpath(dir, entry.name)
                        vim.fn.setreg('"', entry_path)
                        vim.fn.setreg(vim.v.register, entry_path)
                        vim.notify(string.format("[oil] yanked '%s' to register '%s'", entry_path, vim.v.register))
                    end,
                },
            },
        }
    end,
}
