return {
    "A7Lavinraj/fyler.nvim",
    cmd = "Fyler",
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
    init = function()
        vim.api.nvim_create_autocmd("BufEnter", {
            group = vim.api.nvim_create_augroup("fyler_on_open", { clear = true }),
            once = true,
            callback = function()
                local path = vim.fn.argv(0)
                local stat = path ~= "" and vim.uv.fs_stat(path)
                if stat and stat.type == "directory" and not package.loaded.fyler then
                    require("fyler").open({ dir = path })
                end
            end,
        })
    end,
    opts = function()
        return {
            close_on_select = true,
            confirm_simple = false,
            default_explorer = true,
            delete_to_trash = true,
            hooks = {
                on_rename = function(src, dst)
                    Snacks.rename.on_rename_file(src, dst)
                end,
            },
            mappings = {
                ["<C-q>"] = "CloseView",
                ["<CR>"] = "Select",
                ["<A-t>"] = "SelectTab",
                ["<A-v>"] = "SelectVSplit",
                ["<A-s>"] = "SelectSplit",
                ["c"] = "GotoParent",
                ["-"] = "GotoCwd",
                ["za"] = "CollapseAll",
                ["<BS>"] = "CollapseNode",
            },
            git_status = {
                enabled = true,
                symbols = {
                    Untracked = "U",
                    Added = "A",
                    Modified = "M",
                    Deleted = "D",
                    Renamed = "R",
                    Copied = "C",
                    Conflict = "X",
                    Ignored = "I",
                },
            },
            track_current_buffer = true,
            win = {
                border = vim.o.winborder,
                buf_opts = {
                    buflisted = false,
                    bufhidden = "hide",
                },
                kind = "split_left_most",
                kind_presets = {
                    split_left_most = {
                        width = "0.2rel",
                    },
                },
                win_opts = {
                    wrap = false,
                    signcolumn = "no",
                    cursorcolumn = false,
                    number = false,
                    relativenumber = false,
                    foldcolumn = "0",
                    spell = false,
                    list = false,
                    conceallevel = 3,
                    concealcursor = "nvic",
                },
            },
        }
    end,
}
