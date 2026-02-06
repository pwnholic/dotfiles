return {
    "stevearc/oil.nvim",
    lazy = false,
    cmd = "Oil",
    init = function()
        vim.api.nvim_create_autocmd("BufEnter", {
            group = vim.api.nvim_create_augroup("oil_start_directory", { clear = true }),
            desc = "Start oil with directory",
            once = true,
            callback = function()
                if package.loaded["oil"] then
                    return
                else
                    local current_dir = vim.fn.argv(0)
                    local stats = vim.uv.fs_stat(current_dir)
                    if stats and stats.type == "directory" then
                        require("oil").open(current_dir, _, _)
                    end
                end
            end,
        })
    end,
    keys = {
        {
            "<leader>e",
            function()
                return require("oil").open()
            end,
            desc = "Open Oil",
        },
        {
            "<leader>E",
            function()
                return require("oil").open(LazyVim.root())
            end,
            desc = "Open Oil (root dir)",
        },
    },
    opts = {
        win_options = {
            wrap = false,
            signcolumn = "no",
            cursorcolumn = false,
            foldcolumn = "0",
            spell = false,
            list = false,
            conceallevel = 3,
            concealcursor = "nvic",
            cursorline = false,
            number = false,
            relativenumber = false,
        },
        buf_options = {
            buflisted = false,
            bufhidden = "hide",
            buftype = "acwrite",
            expandtab = true,
            shiftwidth = 4,
        },
        columns = {
            -- "permissions",
            -- "size",
            -- "mtime",
            "icon",
        },
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        progress = {
            border = vim.o.winborder,
            minimized_border = vim.o.winborder,
        },
        confirmation = { border = vim.o.winborder },
        ssh = { border = vim.o.winborder },
        keymaps_help = { border = vim.o.winborder },
        use_default_keymaps = false,
        default_file_explorer = true,
        view_options = {
            show_hidden = true,
            is_hidden_file = function(name, bufnr)
                return vim.startswith(name, ".")
            end,
            is_always_hidden = function(name, bufnr)
                return vim.iter({
                    "__pycache__",
                    ".venv",
                    "venv",
                    ".mypy_cache",
                    ".pytest_cache",
                    "target",
                    "vendor",
                    "node_modules",
                    ".DS_Store",
                }):any(function(v)
                    return name == v
                end)
            end,
            natural_order = "fast",
            case_insensitive = true,
            sort = {
                { "type", "asc" },
                { "name", "asc" },
            },
            highlight_filename = function(entry, is_hidden, is_link_target, is_link_orphan)
                if entry.type == "directory" then
                    return "OilDir"
                end
                if is_hidden then
                    return "Comment"
                end
                return nil
            end,
        },
        keymaps = {
            ["g?"] = { "actions.show_help", mode = "n" },
            ["<CR>"] = "actions.select",
            ["<A-s>"] = { "actions.select", opts = { vertical = true } },
            ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
            ["<C-t>"] = { "actions.select", opts = { tab = true } },
            ["<C-p>"] = "actions.preview",
            ["<C-c>"] = { "actions.close", mode = "n" },
            ["<C-l>"] = "actions.refresh",
            ["-"] = { "actions.parent", mode = "n" },
            ["_"] = { "actions.open_cwd", mode = "n" },
            ["`"] = { "actions.cd", mode = "n" },
            ["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
            ["gs"] = { "actions.change_sort", mode = "n" },
            ["gx"] = "actions.open_external",
            ["g."] = { "actions.toggle_hidden", mode = "n" },
            ["g\\"] = { "actions.toggle_trash", mode = "n" },
        },
    },
}
