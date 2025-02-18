return {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = { { "<space>e", "<cmd>Oil<cr>", desc = "Open Oil Buffer" } },
    opts = function()
        local oil = require("oil")
        local icons = LazyVim.config.icons.kinds
        local group_id = vim.api.nvim_create_augroup("OilSyncCwd", { clear = true })

        local function lcd(dir)
            local ok = pcall(vim.cmd.lcd, { dir, mods = { silent = true, emsg_silent = true } })
            if not ok then
                vim.notify("[oil.nvim] failed to cd to " .. dir, vim.log.levels.WARN)
            end
        end

        vim.api.nvim_create_autocmd("RecordingEnter", {
            desc = "Notify when record a macro",
            group = group_id,
            pattern = "oil://*",
            callback = function(opts)
                if vim.fn.reg_recording() ~= "" and vim.bo[opts.buf].filetype == "oil" then
                    local msg = string.format("Recording on [%s]", vim.fn.reg_recording())
                    vim.notify(msg, 2, { title = "Oil" })
                end
            end,
        })

        vim.api.nvim_create_autocmd("RecordingLeave", {
            desc = "Notify when leave a macro",
            pattern = "oil://*",
            group = group_id,
            callback = function()
                vim.notify("Removing Macro Key", 2, { title = "Oil" })
            end,
        })

        local groupid = vim.api.nvim_create_augroup("OilSetup", {})
        vim.api.nvim_create_autocmd("BufEnter", {
            desc = "Ensure that oil buffers are not listed.",
            group = groupid,
            pattern = "oil://*",
            callback = function(info)
                vim.bo[info.buf].buflisted = false
            end,
        })

        ---Change cwd in oil buffer to follow the directory shown in the buffer
        ---@param buf integer? default to current buffer
        local function oil_cd(buf)
            buf = buf or vim.api.nvim_get_current_buf()
            if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].ft ~= "oil" then
                return
            end

            vim.api.nvim_buf_call(buf, function()
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
        end

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            oil_cd(buf)
        end

        vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged" }, {
            desc = "Set cwd to follow directory shown in oil buffers.",
            group = groupid,
            pattern = "oil://*",
            callback = function(info)
                oil_cd(info.buf)
            end,
        })

        vim.api.nvim_create_autocmd("BufEnter", {
            desc = "Record alternate file in dir buffers.",
            group = groupid,
            callback = function(info)
                local buf = info.buf
                local bufname = vim.api.nvim_buf_get_name(buf)
                if vim.fn.isdirectory(bufname) == 1 then
                    vim.b[buf]._alt_file = vim.fn.bufnr("#")
                end
            end,
        })

        vim.api.nvim_create_autocmd("BufEnter", {
            desc = "Set last cursor position in oil buffers when editing parent dir.",
            group = groupid,
            pattern = "oil://*",
            callback = function(info)
                local win = vim.api.nvim_get_current_win()
                if vim.b[info.buf]._oil_entered == win then
                    return
                end
                vim.b[info.buf]._oil_entered = win
                local alt_file = vim.fn.bufnr("#")
                if not vim.api.nvim_buf_is_valid(alt_file) then
                    return
                end
                local _alt_file = vim.b[alt_file]._alt_file
                if _alt_file and vim.api.nvim_buf_is_valid(_alt_file) then
                    alt_file = _alt_file
                end
                local bufname_alt = vim.api.nvim_buf_get_name(alt_file)
                local parent_url, basename = oil.get_buffer_parent_url(bufname_alt, true)
                if basename then
                    local config = require("oil.config")
                    local view = require("oil.view")
                    if
                        not config.view_options.show_hidden
                        and config.view_options.is_hidden_file(
                            basename,
                            (function()
                                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                                    if vim.api.nvim_buf_get_name(buf) == basename then
                                        return buf
                                    end
                                end
                            end)()
                        )
                    then
                        view.toggle_hidden()
                    end
                    view.set_last_cursor(parent_url, basename)
                    view.maybe_set_cursor()
                end
            end,
        })

        local oil_columns = {
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
            preview_win = {
                update_on_cursor_moved = true,
                preview_method = "fast_scratch",
                -- disable_preview = function(filename)
                --     return false
                -- end,
                win_options = {
                    wrap = false,
                },
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
                            oil.set_columns(oil_columns)
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
                        local Path = require("plenary.path")
                        local dir = oil.get_current_dir()
                        if not entry or not dir then
                            return
                        end
                        local rel_path = Path:new(vim.fs.joinpath(dir, entry.name)):make_relative(os.getenv("PWD") or vim.uv.cwd() or "")
                        vim.fn.setreg('"', rel_path)
                        vim.fn.setreg(vim.v.register, rel_path)
                        vim.notify(string.format("[oil] yanked '%s' to register '%s'", rel_path, vim.v.register))
                    end,
                },
            },
        }
    end,
}
