--- Scratch-buffer report renderer.
---
--- Used by the inspector commands (`:Root`, `:LspInfo`, `:FormatInfo`,
--- `:PackStatus`, `:Toggles`) so they are real inspection interfaces instead of
--- one-line echoes. Reports are floating, read-only, shareable between
--- invocations and can bind an action to `<CR>` on a line.
---
--- @class lib.report
local M = {}

--- @class lib.report.Spec
--- @field title string
--- @field lines string[]|fun(): string[]
--- @field filetype? string
--- @field width? number absolute columns
--- @field height? number absolute rows
--- @field keymaps? { mode?: string, lhs: string, rhs: fun(bufnr: integer), desc?: string }[]
--- @field on_line? fun(line: string, bufnr: integer)|nil called on `<CR>`; re-renders when `lines` is a function
--- @field name? string buffer identity (defaults to `core://<slug>`)

--- @param lines string[]|fun(): string[]
--- @return string[]
local function render(lines)
    if type(lines) == "function" then
        local ok, res = pcall(lines)
        if not ok then
            return { ("ERROR: %s"):format(tostring(res)) }
        end
        return res or {}
    end
    return lines or {}
end

--- Open (or refresh) a report buffer.
--- @param spec lib.report.Spec
--- @return integer bufnr
--- @return integer winid
function M.open(spec)
    local name = spec.name or ("core://" .. (spec.title:lower():gsub("%s+", "-")))
    local existing = vim.fn.bufnr(name)
    local bufnr = existing ~= -1 and existing or vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "wipe"
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_name(bufnr, name)

    local body = render(spec.lines)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, body)
    vim.bo[bufnr].modifiable = false
    if spec.filetype then
        vim.bo[bufnr].filetype = spec.filetype
    end

    local width = spec.width or math.min(120, math.max(60, math.floor(vim.o.columns * 0.8)))
    local height = spec.height or math.min(40, math.max(10, math.floor(vim.o.lines * 0.7)))
    local winid = vim.fn.bufwinid(bufnr)
    if winid == -1 then
        winid = vim.api.nvim_open_win(bufnr, true, {
            relative = "editor",
            row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
            col = math.max(0, math.floor((vim.o.columns - width) / 2)),
            width = width,
            height = height,
            style = "minimal",
            title = (" %s "):format(spec.title),
            title_pos = "center",
        })
    end
    vim.wo[winid].wrap = false
    vim.wo[winid].number = false
    vim.wo[winid].relativenumber = false
    vim.wo[winid].signcolumn = "no"
    vim.wo[winid].foldcolumn = "0"
    vim.wo[winid].cursorline = false
    vim.wo[winid].winblend = 0
    vim.wo[winid].list = false

    local function close()
        if vim.api.nvim_win_is_valid(winid) then
            pcall(vim.api.nvim_win_close, winid, true)
        end
    end

    local key_opts = { buffer = bufnr, silent = true, nowait = true, desc = "close report" }
    vim.keymap.set("n", "q", close, key_opts)
    vim.keymap.set("n", "<Esc>", close, key_opts)
    for _, km in ipairs(spec.keymaps or {}) do
        local rhs = km.rhs
        vim.keymap.set(km.mode or "n", km.lhs, function()
            rhs(bufnr)
            if type(spec.lines) == "function" then
                vim.bo[bufnr].modifiable = true
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, render(spec.lines))
                vim.bo[bufnr].modifiable = false
            end
        end, {
            buffer = bufnr,
            silent = true,
            nowait = true,
            desc = km.desc or "report action",
        })
    end
    if spec.on_line then
        vim.keymap.set("n", "<CR>", function()
            local line = vim.api.nvim_get_current_line()
            spec.on_line(line, bufnr)
            if type(spec.lines) == "function" then
                vim.bo[bufnr].modifiable = true
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, render(spec.lines))
                vim.bo[bufnr].modifiable = false
            end
        end, { buffer = bufnr, silent = true, nowait = true, desc = "run report action" })
    end

    return bufnr, winid
end

return M
