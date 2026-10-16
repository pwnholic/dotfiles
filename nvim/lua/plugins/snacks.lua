-- Harpoon-via-picker (Primeagen-style marks, no harpoon.nvim).
-- State: per-project file list in stdpath("data")/harpoon-picker.json.
-- Menu: ivy picker with file preview; <CR> jumps, splits via <C-s>/<C-v>.
local HARPOON_MAX = 32

---@return string state file path
local function harpoon_state_path()
    return vim.fs.joinpath(vim.fn.stdpath("data"), "harpoon-picker.json")
end

---@return table<string, string[]> root -> paths
local function harpoon_read_all()
    local path = harpoon_state_path()
    if vim.fn.filereadable(path) ~= 1 then
        return {}
    end
    local ok_lines, lines = pcall(vim.fn.readfile, path)
    if not ok_lines or not lines then
        return {}
    end
    local ok_data, data = pcall(vim.json.decode, table.concat(lines, "\n"))
    if not ok_data or type(data) ~= "table" then
        return {}
    end
    return data
end

---@param data table<string, string[]>
local function harpoon_write_all(data)
    local ok, text = pcall(vim.json.encode, data)
    if not ok then
        return
    end
    pcall(vim.fn.writefile, vim.split(text, "\n"), harpoon_state_path())
end

---@return string[] paths for the current project root (dead entries dropped)
local function harpoon_list()
    local all = harpoon_read_all()
    local list = all[LazyVim.root()]
    if type(list) ~= "table" then
        return {}
    end
    local kept = {}
    for _, p in ipairs(list) do
        if type(p) == "string" and vim.fn.filereadable(p) == 1 then
            kept[#kept + 1] = p
        end
    end
    return kept
end

---@param list string[]
local function harpoon_save(list)
    local all = harpoon_read_all()
    all[LazyVim.root()] = list
    harpoon_write_all(all)
end

---@param path string
---@param silent? boolean
---@return integer? slot index
local function harpoon_add_path(path, silent)
    if path == "" or vim.fn.filereadable(path) ~= 1 then
        if not silent then
            Snacks.notify.warn("Not a readable file, skipped", { title = "Harpoon" })
        end
        return nil
    end
    local list = harpoon_list()
    local idx = vim.iter(ipairs(list)):find(function(_, p)
        return p == path
    end)
    if idx then
        if not silent then
            Snacks.notify.info(
                ("Already [%d/%d] %s"):format(idx, #list, vim.fn.fnamemodify(path, ":~")),
                { title = "Harpoon" }
            )
        end
        return idx
    end
    if #list >= HARPOON_MAX then
        Snacks.notify.warn(("Harpoon full (%d), delete one first"):format(HARPOON_MAX), { title = "Harpoon" })
        return nil
    end
    list[#list + 1] = path
    harpoon_save(list)
    if not silent then
        Snacks.notify.info(("[%d/%d] %s"):format(#list, #list, vim.fn.fnamemodify(path, ":~")), { title = "Harpoon" })
    end
    return #list
end

local function harpoon_add_current()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].buftype ~= "" then
        Snacks.notify.warn("Not a file buffer, skipped", { title = "Harpoon" })
        return
    end
    harpoon_add_path(vim.api.nvim_buf_get_name(buf))
end

---@param i integer 1-based slot
local function harpoon_select(i)
    local list = harpoon_list()
    local path = list[i]
    if not path then
        Snacks.notify.warn(("Slot %d is empty (%d marks)"):format(i, #list), { title = "Harpoon" })
        return
    end
    vim.cmd.edit(vim.fn.fnameescape(path))
end

---@param delta integer +1 next, -1 prev (wraps)
local function harpoon_nav(delta)
    local list = harpoon_list()
    if #list == 0 then
        Snacks.notify.warn("Harpoon list is empty", { title = "Harpoon" })
        return
    end
    local cur = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
    local idx = vim.iter(ipairs(list)):find(function(_, p)
        return p == cur
    end)
    if not idx then
        idx = delta > 0 and 1 or #list
    else
        idx = (idx - 1 + delta) % #list + 1
    end
    vim.cmd.edit(vim.fn.fnameescape(list[idx]))
end

---@param picker snacks.Picker
local function harpoon_delete(picker)
    local items = picker:selected({ fallback = true })
    if #items == 0 then
        return
    end
    local drop = {}
    for _, it in ipairs(items) do
        if it.file then
            drop[it.file] = true
        end
    end
    local list, kept = harpoon_list(), {}
    for _, p in ipairs(list) do
        if not drop[p] then
            kept[#kept + 1] = p
        end
    end
    if #kept == #list then
        return
    end
    harpoon_save(kept)
    Snacks.notify.info(("Deleted %d, %d left"):format(#list - #kept, #kept), { title = "Harpoon" })
    picker:refresh()
end

-- Reorder without closing: cursor follows the moved item via set_target
-- (kept across refresh; same contract as the list `target` doc).
---@param delta integer -1 up, +1 down
---@return fun(picker: snacks.Picker)
local function harpoon_move(delta)
    return function(picker)
        local cur = picker:current()
        if not cur or not cur.file then
            return
        end
        local list = harpoon_list()
        local idx = vim.iter(ipairs(list)):find(function(_, p)
            return p == cur.file
        end)
        if not idx then
            return
        end
        local j = idx + delta
        if j < 1 or j > #list then
            return
        end
        list[idx], list[j] = list[j], list[idx]
        harpoon_save(list)
        picker.list:set_target(j)
        picker:refresh()
    end
end

---@param picker snacks.Picker
local function harpoon_yank(picker)
    local cur = picker:current()
    if cur and cur.file then
        vim.fn.setreg('"', cur.file)
        vim.fn.setreg("+", cur.file)
        Snacks.notify.info(vim.fn.fnamemodify(cur.file, ":~"), { title = "Harpoon yanked" })
    end
end

-- `a` inside the menu pins the file behind the picker (`picker.main`),
-- not the picker buffer itself.
---@param picker snacks.Picker
local function harpoon_add_here(picker)
    local buf = vim.api.nvim_win_get_buf(picker.main)
    local name = vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) or ""
    if harpoon_add_path(name, true) then
        picker:refresh()
    end
end

---@param picker snacks.Picker
local function harpoon_clear(picker)
    local list = harpoon_list()
    if #list == 0 then
        return
    end
    if vim.fn.confirm(("Clear all %d harpoon marks?"):format(#list), "&Yes\n&No", 2) == 1 then
        harpoon_save({})
        picker:refresh()
    end
end

local function harpoon_menu()
    local root = LazyVim.root()
    Snacks.picker.pick({
        source = "harpoon",
        title = "Harpoon",
        cwd = root,
        layout = { preview = "main", preset = "ivy" },
        sort = { fields = { "idx" } },
        format = "file",
        show_empty = true,
        finder = function()
            local items = {}
            for i, path in ipairs(harpoon_list()) do
                items[#items + 1] = { file = path, text = path, label = ("%d."):format(i) }
            end
            return items
        end,
        actions = {
            harpoon_delete = harpoon_delete,
            harpoon_move_up = harpoon_move(-1),
            harpoon_move_down = harpoon_move(1),
            harpoon_yank = harpoon_yank,
            harpoon_add_here = harpoon_add_here,
            harpoon_clear = harpoon_clear,
        },
        win = {
            input = {
                keys = {
                    ["<c-x>"] = { "harpoon_delete", mode = { "n", "i" } },
                    ["<A-j>"] = { "harpoon_move_down", mode = { "n", "i" } },
                    ["<A-k>"] = { "harpoon_move_up", mode = { "n", "i" } },
                    ["<c-s>"] = { "edit_split", mode = { "n", "i" } },
                    ["<c-v>"] = { "edit_vsplit", mode = { "n", "i" } },
                },
            },
            list = {
                keys = {
                    ["dd"] = "harpoon_delete",
                    ["J"] = "harpoon_move_down",
                    ["K"] = "harpoon_move_up",
                    ["<A-j>"] = "harpoon_move_down",
                    ["<A-k>"] = "harpoon_move_up",
                    ["D"] = "harpoon_clear",
                    ["Y"] = "harpoon_yank",
                    ["a"] = "harpoon_add_here",
                    ["<c-s>"] = "edit_split",
                    ["<c-v>"] = "edit_vsplit",
                },
            },
        },
    })
end

-- Prev/next live outside the `<leader>h` prefix: `hp`/`hn` under it would
-- force a `timeoutlen` wait on every quick-menu open. `[h`/`]h` is taken
-- by gitsigns (buffer-local, wins in tracked files), so leader brackets.
local harpoon_keys = {
    { "<leader>H", harpoon_add_current, desc = "Harpoon File" },
    { "<leader>h", harpoon_menu, desc = "Harpoon Quick Menu" },
    {
        "<leader>[",
        function()
            harpoon_nav(-1)
        end,
        desc = "Harpoon Prev",
    },
    {
        "<leader>]",
        function()
            harpoon_nav(1)
        end,
        desc = "Harpoon Next",
    },
}
for i = 1, 9 do
    harpoon_keys[#harpoon_keys + 1] = {
        "<leader>" .. i,
        function()
            harpoon_select(i)
        end,
        desc = ("Jump to File %d"):format(i),
    }
end

local headers = {
    {
        "███████╗████████╗ █████╗ ██╗   ██╗    ███████╗ ██████╗  ██████╗██╗   ██╗███████╗███████╗██████╗",
        "██╔════╝╚══██╔══╝██╔══██╗╚██╗ ██╔╝    ██╔════╝██╔═══██╗██╔════╝██║   ██║██╔════╝██╔════╝██╔══██",
        "███████╗   ██║   ███████║ ╚████╔╝     █████╗  ██║   ██║██║     ██║   ██║███████╗█████╗  ██║  ██",
        "╚════██║   ██║   ██╔══██║  ╚██╔╝      ██╔══╝  ██║   ██║██║     ██║   ██║╚════██║██╔══╝  ██║  ██",
        "███████║   ██║   ██║  ██║   ██║       ██║     ╚██████╔╝╚██████╗╚██████╔╝███████║███████╗██████╔",
        "╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝       ╚═╝      ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚═════╝",
    },
    {
        "██████╗ ██╗███████╗███╗   ███╗██╗██╗     ██╗      █████╗ ██╗  ██",
        "██╔══██╗██║██╔════╝████╗ ████║██║██║     ██║     ██╔══██╗██║  ██",
        "██████╔╝██║███████╗██╔████╔██║██║██║     ██║     ███████║███████",
        "██╔══██╗██║╚════██║██║╚██╔╝██║██║██║     ██║     ██╔══██║██╔══██",
        "██████╔╝██║███████║██║ ╚═╝ ██║██║███████╗███████╗██║  ██║██║  ██",
        "╚═════╝ ╚═╝╚══════╝╚═╝     ╚═╝╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═",
    },
    {
        "██╗     ██╗   ██╗██╗  ██╗    ███╗   ███╗███████╗███╗   ██╗████████╗██╗███████",
        "██║     ██║   ██║╚██╗██╔╝    ████╗ ████║██╔════╝████╗  ██║╚══██╔══╝██║██╔════",
        "██║     ██║   ██║ ╚███╔╝     ██╔████╔██║█████╗  ██╔██╗ ██║   ██║   ██║███████",
        "██║     ██║   ██║ ██╔██╗     ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   ██║╚════██",
        "███████╗╚██████╔╝██╔╝ ██╗    ██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   ██║███████",
        "╚══════╝ ╚═════╝ ╚═╝  ╚═╝    ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚══════",
    },
    {
        "██████╗ ███████╗███╗   ███╗ ██████╗ ██╗  ██╗    ██████╗ ███████╗██╗   ██",
        "██╔══██╗██╔════╝████╗ ████║██╔═══██╗██║ ██╔╝    ██╔══██╗██╔════╝██║   ██",
        "██████╔╝█████╗  ██╔████╔██║██║   ██║█████╔╝     ██║  ██║█████╗  ██║   ██",
        "██╔══██╗██╔══╝  ██║╚██╔╝██║██║   ██║██╔═██╗     ██║  ██║██╔══╝  ╚██╗ ██╔",
        "██║  ██║███████╗██║ ╚═╝ ██║╚██████╔╝██║  ██╗    ██████╔╝███████╗ ╚████╔╝",
        "╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝    ╚═════╝ ╚══════╝  ╚═══╝",
    },
    {
        "███████╗██╗      ██████╗ ██████╗     ███████╗███╗   ██╗     ██╗ ██████╗ ██╗   ██╗███████╗██████╗",
        "██╔════╝██║     ██╔═══██╗██╔══██╗    ██╔════╝████╗  ██║     ██║██╔═══██╗╚██╗ ██╔╝██╔════╝██╔══██",
        "███████╗██║     ██║   ██║██████╔╝    █████╗  ██╔██╗ ██║     ██║██║   ██║ ╚████╔╝ █████╗  ██████╔",
        "╚════██║██║     ██║   ██║██╔═══╝     ██╔══╝  ██║╚██╗██║██   ██║██║   ██║  ╚██╔╝  ██╔══╝  ██╔══██",
        "███████║███████╗╚██████╔╝██║         ███████╗██║ ╚████║╚█████╔╝╚██████╔╝   ██║   ███████╗██║  ██",
        "╚══════╝╚══════╝ ╚═════╝ ╚═╝         ╚══════╝╚═╝  ╚═══╝ ╚════╝  ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═",
    },
    {
        "███╗   ██╗ ██████╗ ███████╗██╗   ██╗██╗███╗   ███╗       ██████╗██╗  ██╗ █████╗ ███╗   ██",
        "████╗  ██║██╔═══██╗██╔════╝██║   ██║██║████╗ ████║      ██╔════╝██║  ██║██╔══██╗████╗  ██",
        "██╔██╗ ██║██║   ██║█████╗  ██║   ██║██║██╔████╔██║█████╗██║     ███████║███████║██╔██╗ ██",
        "██║╚██╗██║██║   ██║██╔══╝  ╚██╗ ██╔╝██║██║╚██╔╝██║╚════╝██║     ██╔══██║██╔══██║██║╚██╗██",
        "██║ ╚████║╚██████╔╝███████╗ ╚████╔╝ ██║██║ ╚═╝ ██║      ╚██████╗██║  ██║██║  ██║██║ ╚████",
        "╚═╝  ╚═══╝ ╚═════╝ ╚══════╝  ╚═══╝  ╚═╝╚═╝     ╚═╝       ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══",
    },
}

return {
    {
        "folke/snacks.nvim",
        keys = harpoon_keys,
        opts = function(_, opts)
            opts.picker = opts.picker or {}
            -- Ivy titles centered (upstream ivy preset uses left).
            -- No tbl_extend needed: lazy.nvim deep-merges specs itself
            -- (`M._values` -> `Util.merge`, force behavior), and this fn
            -- receives the merged base as `opts`.
            opts.picker.layouts = opts.picker.layouts or {}
            -- Ivy titles centered (upstream ivy preset uses left).
            for _, name in ipairs({ "ivy", "ivy_split" }) do
                opts.picker.layouts[name] = opts.picker.layouts[name] or {}
                opts.picker.layouts[name].layout = opts.picker.layouts[name].layout or {}
                opts.picker.layouts[name].layout.title_pos = "center"
            end
            -- Sources merge key-wise by lazy.nvim; direct assign keeps base keys.
            opts.picker.sources = opts.picker.sources or {}
            -- `fd` only respects .gitignore inside a git repo; scratch
            -- dirs like learning-eino are not repos, so apply ignore files
            -- regardless of git presence. Extra args append after base args
            -- (get_cmd does `vim.list_extend(args, opts.args or {})`).
            -- `rg` (grep source) already honors .gitignore without a repo,
            -- so it needs no flag.
            local fd_no_git = { "--no-require-git" }
            for _, name in ipairs({ "files" }) do
                opts.picker.sources[name] = { layout = { preview = "main", preset = "ivy" }, args = fd_no_git }
            end
            for _, name in ipairs({
                "git_files",
                "git_grep",
                "grep",
                "grep_word",
                "grep_buffers",
                "lines",
                "lsp_definitions",
                "lsp_declarations",
                "lsp_references",
                "lsp_implementations",
                "lsp_type_definitions",
                "lsp_incoming_calls",
                "lsp_outgoing_calls",
                "lsp_symbols",
                "lsp_workspace_symbols",
                "diagnostics",
                "diagnostics_buffer",
            }) do
                opts.picker.sources[name] = { layout = { preview = "main", preset = "ivy" } }
            end
            -- Indent keeps base `enabled = true`; only chars overridden.
            opts.indent = opts.indent or {}
            opts.indent.indent = { char = "▏" }
            opts.indent.scope = { char = "▏", underline = false }
            -- Dashboard: assign preset fields directly to keep base `pick` fn.
            opts.dashboard = opts.dashboard or {}
            opts.dashboard.preset = opts.dashboard.preset or {}
            -- Content width matches header (50 cols): header fills the slot
            -- edge-to-edge, so centering is a single outer offset instead of
            -- outer + inner padding stacking two floor() roundings.
            opts.dashboard.preset.keys = {
                {
                    icon = " ",
                    key = "f",
                    desc = "Find File",
                    action = ":lua Snacks.dashboard.pick('files')",
                },
                { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                {
                    icon = " ",
                    key = "g",
                    desc = "Find Text",
                    action = ":lua Snacks.dashboard.pick('live_grep')",
                },
                {
                    icon = " ",
                    key = "r",
                    desc = "Recent Files",
                    action = ":lua Snacks.dashboard.pick('oldfiles')",
                },
                { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                { icon = " ", key = "q", desc = "Quit", action = ":qa" },
            }

            -- Random banner per startup: pick one raw header, then pair
            -- each of its 6 lines with SnacksDashboardHeader1..6.
            -- `D:block` splits rows on `\n`, so every line (except the
            -- last) needs the trailing newline or rows merge into one.
            -- LuaJIT seeds `math.random` identically every launch, so
            -- reseed from time+pid or all 4 headers still rotate to the
            -- same one on every startup.
            math.randomseed(vim.uv.hrtime() + vim.fn.getpid())
            local picked = headers[math.random(#headers)]
            opts.dashboard.preset.header = vim.iter(picked)
                :enumerate()
                :map(function(i, line)
                    local text = line
                    if i < 6 then
                        text = line .. "\n"
                    end
                    return { text, hl = "SnacksDashboardHeader" .. i }
                end)
                :totable()
            -- Content width follows the widest picked header (display
            -- cols), clamped to the window so narrow splits don't clip:
            -- header fills the slot edge-to-edge, so centering is a single
            -- outer offset instead of outer + inner padding stacking two
            -- floor() roundings.
            local picked_width = vim.iter(picked):fold(0, function(acc, line)
                return math.max(acc, vim.api.nvim_strwidth(line))
            end)
            opts.dashboard.width = math.min(picked_width, math.max(20, vim.api.nvim_win_get_width(0) - 4))
        end,
    },
}
