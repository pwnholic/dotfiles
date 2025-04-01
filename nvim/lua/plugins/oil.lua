return {
    "stevearc/oil.nvim",
    cmd = "Oil",
    lazy = false,
    keys = { { "<space>e", "<cmd>Oil<cr>", desc = "Open Oil Buffer" } },
    init = function()
        vim.api.nvim_create_autocmd("BufEnter", {
            nested = true,
            callback = vim.schedule_wrap(function(info)
                local bufnr = info.buf
                local autocmd_id = info.id

                if not vim.api.nvim_buf_is_valid(bufnr) or vim.fn.bufwinid(bufnr) == -1 or vim.bo[bufnr].bt ~= "" then
                    return
                end

                local bufname = vim.api.nvim_buf_get_name(bufnr)
                if bufname == "" then
                    return
                end

                local fs_stat = vim.uv.fs_stat(bufname)
                if fs_stat and fs_stat.type ~= "directory" then
                    return
                end

                pcall(require, "oil")
                pcall(vim.api.nvim_del_autocmd, autocmd_id)

                if not vim.api.nvim_buf_is_valid(bufnr) then
                    return
                end

                local fn_wrap = vim.schedule_wrap(function()
                    pcall(vim.cmd.edit, { bang = true, mods = { keepjumps = true } })
                end)

                vim.api.nvim_buf_call(bufnr, fn_wrap)
            end),
        })
    end,
    config = function()
        local oil = require("oil")
        local icons = LazyVim.config.icons.kinds

        local oil_columns = {
            {
                "type",
                icons = { directory = "d", fifo = "p", file = "-", link = "l", socket = "s" },
                highlight = function(type_str)
                    return setmetatable(
                        { ["-"] = "OilTypeFile", ["d"] = "OilTypeDir", ["p"] = "OilTypeFifo", ["l"] = "OilTypeLink", ["s"] = "OilTypeSocket" },
                        {
                            __index = function()
                                return "OilTypeFile"
                            end,
                        }
                    )[type_str]
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
            { "icon", default_file = icons.File, directory = icons.Folder, add_padding = false },
        }

        oil.setup({
            keymaps_help = { border = vim.g.border },
            float = { border = vim.g.border, win_options = { winblend = 0 } },
            preview = { border = vim.g.border, win_options = { winblend = 0 } },
            progress = { border = vim.g.border, win_options = { winblend = 0 } },
            buf_options = { buflisted = false, bufhidden = "hide" },
            win_options = {
                number = false,
                relativenumber = false,
                foldcolumn = "0",
                wrap = false,
            },
            preview_win = {
                update_on_cursor_moved = true,
                preview_method = "fast_scratch",
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
                        local rel_path = Path:new(vim.fs.joinpath(dir, entry.name)):make_relative(vim.uv.cwd() or os.getenv("PWD") or "")
                        vim.fn.setreg('"', rel_path)
                        vim.fn.setreg(vim.v.register, rel_path)
                        vim.notify(string.format("[oil] yanked '%s' to register '%s'", rel_path, vim.v.register))
                    end,
                },
            },
        })
    end,
}
