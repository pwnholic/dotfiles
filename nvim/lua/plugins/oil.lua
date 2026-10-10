-- Oil: directory browser replacing netrw / snacks explorer.

---@param bufnr? integer
---@return string|nil
local function oil_dir(bufnr)
    local ok, oil = pcall(require, "oil")
    if not ok then
        return nil
    end
    return oil.get_current_dir(bufnr or 0)
end

-- Entry tuple indexes (`constants.lua`).
local FIELD_TYPE = 3
local FIELD_META = 4

---@param entry oil.InternalEntry
---@return table|nil entry[4] (meta with .stat/.link)
local function entry_meta(entry)
    return entry[FIELD_META]
end

---@param entry oil.InternalEntry
---@return table|nil uv.fs_stat table, or nil when the adapter did not stat
local function entry_stat(entry)
    local meta = entry[FIELD_META]
    return meta and meta.stat
end

---@param bytes integer
---@return string
local function human_size(bytes)
    local units = { "B", "KiB", "MiB", "GiB", "TiB" }
    local v = bytes
    local u = 1
    while v >= 1024 and u < #units do
        v = v / 1024
        u = u + 1
    end
    if u == 1 then
        return string.format("%d %s", v, units[u])
    end
    return string.format("%.1f %s", v, units[u])
end

-- Permissions returns per-char `oil.HlRange` spans (relative offsets,
-- applied by `util.render_table`); groups live in `tokyonight.lua`.
local permission_hlgroups = setmetatable({
    ["-"] = "OilPermissionNone",
    r = "OilPermissionRead",
    w = "OilPermissionWrite",
    x = "OilPermissionExecute",
    s = "OilPermissionSetuid",
    S = "OilPermissionSetuid",
    t = "OilPermissionSetuid",
    T = "OilPermissionSetuid",
}, {
    __index = function()
        return "OilDir"
    end,
})

local type_hlgroups = setmetatable({
    ["-"] = "OilTypeFile",
    d = "OilTypeDir",
    p = "OilTypeFifo",
    l = "OilTypeLink",
    s = "OilTypeSocket",
}, {
    __index = function()
        return "OilTypeFile"
    end,
})

local type_icons = {
    directory = "d",
    fifo = "p",
    file = "-",
    link = "l",
    socket = "s",
}

---@param type_str string single letter produced by `type_icons`
---@return string highlight group name
local function type_highlight(type_str)
    return type_hlgroups[type_str]
end

---@param perm string e.g. "rwxr-xr-x" from `permissions.mode_to_str`
---@return table oil.HlRange list, one span per character
local function permission_highlight(perm)
    local hls = {}
    for i = 1, #perm do
        hls[#hls + 1] = { permission_hlgroups[perm:sub(i, i)], i - 1, i }
    end
    return hls
end

-- Called from the spec's `config` (post-rtp, pre-setup). NOT top-level:
-- specs load before the plugin is on `package.path`, so a bare require
-- here crashes startup.
local function register_custom_columns()
    local columns = require("oil.columns")
    columns.register("size_human", {
        require_stat = true,
        render = function(entry)
            local stat = entry_stat(entry)
            if not stat then
                return columns.EMPTY
            end
            return human_size(stat.size)
        end,
        parse = function(line)
            return line:match("^(%d+%.?%d*%s*%S*)%s+(.*)$")
        end,
        get_sort_value = function(entry)
            local stat = entry_stat(entry)
            return stat and stat.size or 0
        end,
    })

    columns.register("mtime_iso", {
        require_stat = true,
        render = function(entry)
            local stat = entry_stat(entry)
            if not stat then
                return columns.EMPTY
            end
            return vim.fn.strftime("%Y-%m-%d %H:%M", stat.mtime.sec)
        end,
        parse = function(line)
            return line:match("^(%d%d%d%d%-%d%d%-%d%d%s+%d%d:%d%d)%s+(.+)$")
        end,
        get_sort_value = function(entry)
            local stat = entry_stat(entry)
            return stat and stat.mtime.sec or 0
        end,
    })

    columns.register("symlink_target", {
        render = function(entry)
            if entry[FIELD_TYPE] ~= "link" then
                return columns.EMPTY
            end
            local meta = entry_meta(entry)
            if meta and meta.link and meta.link ~= "" then
                return meta.link
            end
            return columns.EMPTY
        end,
        parse = function(line)
            return line:match("^(%S+)%s+(.*)$")
        end,
    })
end

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

---@return integer
local function float_max_width()
    return math.min(100, math.floor(vim.o.columns * 0.8))
end

---@return integer
local function float_max_height()
    return math.max(15, math.min(35, math.floor(vim.o.lines * 0.8)))
end

local function terminal_in_oil_dir()
    Snacks.terminal.focus(nil, { cwd = oil_dir() or LazyVim.root() })
end

-- Folder picker (ivy) -> Oil. `transform` returning `false` drops a row
-- (`proc` contract); confirm re-stats every pick (dir may be deleted).
local function folders_in_oil()
    Snacks.picker.pick({
        source = "oil_folders",
        title = "Folders",
        layout = { preview = "main", preset = "ivy" },
        finder = function(_, ctx)
            local files = require("snacks.picker.source.files")
            local fd = files.get_fd()
            if not fd then
                Snacks.notify.warn("`fd` is required for the folder picker")
                return function() end
            end
            local cwd = LazyVim.root()
            local proc = require("snacks.picker.source.proc").proc({
                cmd = fd,
                args = { "--type", "d", "--color", "never", "-E", ".git", "." },
                cwd = cwd,
                notify = false,
                ---@param item snacks.picker.finder.Item
                transform = function(item)
                    local rel = item.text and vim.trim(item.text)
                    if rel == nil or rel == "" then
                        return false
                    end
                    local abs = cwd .. "/" .. rel
                    if vim.fn.isdirectory(abs) ~= 1 then
                        return false
                    end
                    item.cwd = cwd
                    item.file = rel
                    item.dir = true
                end,
            }, ctx)
            ---@async
            ---@param cb async fun(item: snacks.picker.finder.Item)
            return function(cb)
                cb({ file = cwd, text = cwd, dir = true })
                proc(cb)
            end
        end,
        format = "file",
        preview = "directory",
        confirm = function(picker, item)
            local items = item and picker:selected({ fallback = true }) or {}
            picker:close()
            if #items == 0 then
                return
            end
            local oil_ok, oil = pcall(require, "oil")
            if not oil_ok then
                Snacks.notify.error("oil.nvim not available")
                return
            end
            -- Items are `finder.Item`s at runtime (finder always sets
            -- `file`/`cwd`/`dir`); the cast tells Lua LS that.
            ---@param it snacks.picker.Item
            ---@return string|nil abs normalized path, or nil with a warn
            local function resolve_dir(it)
                ---@cast it snacks.picker.finder.Item
                local dir = Snacks.picker.util.path(it) or it.file
                if dir == nil or dir == "" then
                    return nil
                end
                -- May have vanished between pick and confirm.
                if vim.fn.isdirectory(dir) ~= 1 then
                    Snacks.notify.warn("Skipped (no longer a directory): " .. dir)
                    return nil
                end
                return dir
            end
            local first = resolve_dir(items[1])
            if not first then
                return
            end
            oil.open(first)
            for i = 2, #items do
                local dir = resolve_dir(items[i])
                if dir then
                    vim.cmd.vsplit()
                    oil.open(dir)
                end
            end
        end,
    })
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
                "<leader>fd",
                folders_in_oil,
                desc = "Find folder in Oil (root)",
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
                winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual",
            },
            columns = { "icon" },
            float = {
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
            skip_confirm_for_simple_edits = true,
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
                ["<A-s>"] = { "actions.select", opts = { vertical = true }, desc = "Open in vertical split" },
                ["<A-h>"] = { "actions.select", opts = { horizontal = true }, desc = "Open in horizontal split" },
                ["<A-t>"] = { "actions.select", opts = { tab = true }, desc = "Open in new tab" },
                ["<C-p>"] = { "actions.preview", desc = "Preview entry" },
                ["<C-c>"] = { "actions.close", mode = "n", desc = "Close Oil" },
                ["q"] = { "actions.close", mode = "n", desc = "Close Oil" },
                ["<C-l>"] = { "actions.refresh", desc = "Refresh directory" },
                ["-"] = { "actions.parent", mode = "n", desc = "Go to parent directory" },
                ["_"] = { "actions.open_cwd", mode = "n", desc = "Open working directory" },
                ["`"] = { "actions.cd", mode = "n", desc = "Change working directory" },
                ["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n", desc = "Change tab directory" },
                ["gs"] = { "actions.change_sort", mode = "n", desc = "Change sort order" },
                -- No per-column hide flag: toggle by swapping the column list.
                ["gC"] = {
                    function()
                        local oil = require("oil")
                        local config = require("oil.config")
                        local cur = config.columns or {}
                        local function has(name)
                            for _, c in ipairs(cur) do
                                local n = type(c) == "table" and c[1] or c
                                if n == name then
                                    return true
                                end
                            end
                            return false
                        end
                        if has("type") then
                            oil.set_columns({ "icon" })
                        else
                            oil.set_columns({
                                { "type", icons = type_icons, highlight = type_highlight },
                                "symlink_target",
                                { "permissions", highlight = permission_highlight },
                                { "size_human", highlight = "Number" },
                                { "mtime_iso", highlight = "String" },
                                "icon",
                            })
                        end
                    end,
                    mode = "n",
                    desc = "Toggle detail columns",
                },
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
        -- Post-rtp: register columns before setup (see above).
        config = function(_, opts)
            register_custom_columns()
            require("oil").setup(opts)
        end,
    },
}
