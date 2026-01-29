return {
    "A7Lavinraj/fyler.nvim",
    lazy = false,
    init = function()
        vim.api.nvim_create_autocmd("BufEnter", {
            group = vim.api.nvim_create_augroup("fyler_start_directory", { clear = true }),
            desc = "Start fyler with directory",
            once = true,
            callback = function()
                if package.loaded["fyler"] then
                    return
                else
                    local current_dir = vim.fn.argv(0)
                    local stats = vim.uv.fs_stat(current_dir)
                    if stats and stats.type == "directory" then
                        require("fyler").open({ dir = current_dir })
                    end
                end
            end,
        })
    end,
    keys = {
        {
            "<leader>e",
            function()
                return require("fyler").toggle({
                    dir = LazyVim.root() or vim.uv.cwd(),
                })
            end,
            desc = "Open Fyler",
        },
        {
            "<leader>E",
            function()
                local current_dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
                local stats = vim.uv.fs_stat(current_dir)
                if current_dir ~= "" and stats and stats.type == "directory" then
                    return require("fyler").toggle({ dir = current_dir })
                end
            end,
            desc = "Open Fyler (current dir)",
        },
    },
    opts = {
        hooks = {
            on_rename = function(src_path, destination_path)
                Snacks.rename.on_rename_file(src_path, destination_path)
            end,
        },
        integrations = { winpick = "snacks" },
        views = {
            finder = {
                close_on_select = true,
                confirm_simple = false,
                default_explorer = true,
                delete_to_trash = true,
                icon = {
                    directory_empty = " ",
                    directory_expanded = " ",
                    directory_collapsed = " ",
                },
                columns_order = {
                    "diagnostic",
                    "git",
                    -- "permission", "size"
                },
                columns = {
                    git = {
                        symbols = {
                            Untracked = "UTK",
                            Added = "ADD",
                            Modified = "MOD",
                            Deleted = "DEL",
                            Renamed = "REN",
                            Copied = "CPY",
                            Conflict = "CNF",
                            Ignored = "IGN",
                        },
                    },
                    diagnostic = {
                        symbols = {
                            Error = LazyVim.config.icons.diagnostics.Error,
                            Warn = LazyVim.config.icons.diagnostics.Warn,
                            Hint = LazyVim.config.icons.diagnostics.Hint,
                            Info = LazyVim.config.icons.diagnostics.Info,
                        },
                    },
                },
                mappings = {
                    ["<C-q>"] = "CloseView",
                    ["<CR>"] = "Select",
                    ["<C-t>"] = "SelectTab",
                    ["<C-k>"] = "SelectVSplit",
                    ["<C-h>"] = "SelectSplit",
                    ["-"] = "GotoParent",
                    ["~"] = "GotoCwd",
                    ["<Tab>"] = "GotoNode",
                    ["<A-BS>"] = "CollapseAll",
                    ["<BS>"] = "CollapseNode",
                },
                follow_current_file = true,
                watcher = { enabled = true },
                win = {
                    border = vim.o.winborder,
                    buf_opts = {
                        filetype = "fyler",
                        syntax = "fyler",
                        buflisted = false,
                        buftype = "acwrite",
                        expandtab = true,
                        shiftwidth = 2,
                    },
                    win_opts = {
                        concealcursor = "nvic",
                        conceallevel = 3,
                        cursorline = false,
                        number = false,
                        relativenumber = false,
                        winhighlight = "Normal:FylerNormal,NormalNC:FylerNormalNC",
                        wrap = false,
                        signcolumn = "no",
                    },
                },
            },
        },
    },
}
