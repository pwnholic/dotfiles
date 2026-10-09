-- Oil: directory browser replacing netrw / snacks explorer.
--
-- Terminal integration: `<c-/>` / `<c-_>` detect an oil buffer and root the
-- terminal at the directory oil is showing (`oil.get_current_dir()` parses
-- the `oil://` buffer URL, so `-`/`_` navigation is tracked for free).
-- Outside oil buffers they fall back to the project root, like LazyVim.
--
-- Float prettiness: rounded border + winblend + directory title; the size
-- is re-read from the screen on every open (`float.override`), so splits
-- and small terminals degrade gracefully.

-- Current oil directory, or nil when the buffer is not an oil buffer.
---@param bufnr? integer
---@return string|nil
local function oil_dir(bufnr)
    local ok, oil = pcall(require, "oil")
    if not ok then
        return nil
    end
    return oil.get_current_dir(bufnr or 0)
end

-- Width-aware float padding: tight on small screens, airy on wide ones.
---@return integer
local function float_padding()
    local cols = vim.o.columns
    if cols < 100 then
        return 1
    elseif cols < 160 then
        return 2
    end
    return 4
end

-- Responsive float cap: never wider than ~100 cols, never more than 80% of
-- the editor. Oil's layout only reads `config.float.max_width` when it is
-- `> 0` (layout.lua), so a plain integer here is honoured directly.
---@return integer
local function float_max_width()
    return math.min(100, math.floor(vim.o.columns * 0.8))
end

-- Responsive float height: 80% of the editor, clamped to [15, 35] rows so
-- tiny terminals stay usable and huge monitors don't get a wall of files.
---@return integer
local function float_max_height()
    return math.max(15, math.min(35, math.floor(vim.o.lines * 0.8)))
end

-- Focus a Snacks terminal rooted at the directory oil is showing.
-- Outside oil buffers falls back to the project root (LazyVim default).
local function terminal_in_oil_dir()
    Snacks.terminal.focus(nil, { cwd = oil_dir() or LazyVim.root() })
end

return {
    {
        "folke/snacks.nvim",
        opts = { explorer = { enabled = false } },
        keys = {
            { "<leader>e", false },
            { "<leader>E", false },
            { "<leader>fe", false },
            { "<leader>fE", false },
            { "<c-/>", false },
            { "<c-_>", false },
        },
    },
    {
        "stevearc/oil.nvim",
        lazy = false,
        keys = {
            {
                "<leader>e",
                function()
                    require("oil").open()
                end,
                desc = "Explorer (project root)",
            },
            {
                "<leader>E",
                function()
                    require("oil").open(LazyVim.root())
                end,
                desc = "Explorer (cwd)",
            },
            {
                "<c-/>",
                terminal_in_oil_dir,
                desc = "Terminal (oil dir or root)",
                mode = { "n", "t" },
            },
            {
                "<c-_>",
                terminal_in_oil_dir,
                desc = "which_key_ignore",
                mode = { "n", "t" },
            },
        },

        ---@module "oil"
        ---@type oil.SetupOpts
        opts = {
            default_file_explorer = true,
            buf_options = {
                buflisted = false,
                bufhidden = "hide",
            },
            win_options = {
                number = false,
                relativenumber = false,
                wrap = false,
                signcolumn = "no",
                cursorcolumn = false,
                cursorline = true,
                foldcolumn = "0",
                spell = false,
                list = false,
                conceallevel = 3,
                concealcursor = "nvic",
                -- Dim the file list against the editor so the float
                -- reads as a panel, not a bare rectangle. The groups
                -- exist on stock Neovim, so no theme support needed.
                winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual",
            },
            columns = { "icon" },
            float = {
                border = "rounded",
                win_options = { winblend = 10 },
                -- Title shows the browsed directory, truncated to fit.
                get_win_title = function(winid)
                    local dir = oil_dir(vim.api.nvim_win_get_buf(winid)) or vim.fn.getcwd(winid)
                    local home = vim.fn.expand("~")
                    if dir:sub(1, #home) == home then
                        dir = "~" .. dir:sub(#home + 1)
                    end
                    local max = math.max(20, math.floor(vim.o.columns * 0.4))
                    if #dir > max then
                        dir = "…" .. dir:sub(-max + 1)
                    end
                    return "  " .. dir .. "  "
                end,
                preview_split = "auto",
                override = function(conf)
                    -- Re-read the screen size on every open, so resizing
                    -- the terminal between opens degrades gracefully.
                    local pad = float_padding()
                    conf.width = vim.o.columns - 2 * pad
                    if conf.border ~= "none" then
                        conf.width = conf.width - 2
                    end
                    conf.width = math.min(conf.width, float_max_width())
                    conf.height = vim.o.lines - vim.o.cmdheight - 2 * pad
                    conf.height = math.min(conf.height, float_max_height())
                    conf.row = math.max(0, math.floor((vim.o.lines - conf.height) / 2))
                    conf.col = math.max(0, math.floor((vim.o.columns - conf.width) / 2) - 1)
                    return conf
                end,
            },
            preview_win = {
                update_on_cursor_moved = true,
                preview_method = "fast_scratch",
                win_options = {
                    signcolumn = "no",
                    number = false,
                },
            },
            confirmation = {
                max_width = 0.9,
                min_width = { 40, 0.4 },
                max_height = 0.9,
                min_height = { 5, 0.1 },
                border = vim.o.winborder,
                win_options = { winblend = 10 },
            },
            progress = {
                max_width = 0.9,
                min_width = { 40, 0.4 },
                max_height = { 10, 0.9 },
                min_height = { 5, 0.1 },
                border = vim.o.winborder,
                minimized_border = "none",
                win_options = { winblend = 10 },
            },
            ssh = { border = vim.o.winborder },
            keymaps_help = { border = vim.o.winborder },
            delete_to_trash = true,
            skip_confirm_for_simple_edits = false,
            prompt_save_on_select_new_entry = true,
            cleanup_delay_ms = 2000,
            lsp_file_methods = {
                enabled = true,
                timeout_ms = 1000,
                autosave_changes = false,
            },
            constrain_cursor = "editable",
            watch_for_changes = false,
            keymaps = {
                ["g?"] = { "actions.show_help", mode = "n", desc = "Show Oil keymaps" },
                ["<CR>"] = { "actions.select", desc = "Open file or directory" },
                ["<C-s>"] = { "actions.select", opts = { vertical = true }, desc = "Open in vertical split" },
                ["<C-h>"] = { "actions.select", opts = { horizontal = true }, desc = "Open in horizontal split" },
                ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open in new tab" },
                ["<C-p>"] = { "actions.preview", desc = "Preview entry" },
                ["<C-c>"] = { "actions.close", mode = "n", desc = "Close Oil" },
                ["q"] = { "actions.close", mode = "n", desc = "Close Oil" },
                ["<C-l>"] = { "actions.refresh", desc = "Refresh directory" },
                ["-"] = { "actions.parent", mode = "n", desc = "Go to parent directory" },
                ["_"] = { "actions.open_cwd", mode = "n", desc = "Open working directory" },
                ["`"] = { "actions.cd", mode = "n", desc = "Change working directory" },
                ["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n", desc = "Change tab directory" },
                ["gs"] = { "actions.change_sort", mode = "n", desc = "Change sort order" },
                ["gx"] = { "actions.open_external", desc = "Open with external application" },
                ["g."] = { "actions.toggle_hidden", mode = "n", desc = "Toggle hidden files" },
                ["g\\"] = { "actions.toggle_trash", mode = "n", desc = "Toggle Trash" },
                ["gy"] = { "actions.yank_entry", desc = "Yank entry path" },
            },
            use_default_keymaps = false,
            view_options = {
                show_hidden = false,
                natural_order = "fast",
                case_insensitive = false,
                sort = {
                    { "type", "asc" },
                    { "name", "asc" },
                },
            },
        },
    },
}
