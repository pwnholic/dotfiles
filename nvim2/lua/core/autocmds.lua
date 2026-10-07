--- Global behavioral autocommands + a declarative autocmd registry.
---
--- Subsystems own their own autocommands through `lib.lifecycle`; this module
--- owns the small set of *editor-wide* behaviors and provides the extension
--- point for user configuration / plugins that want declarative autocommands
--- without managing augroups themselves.
---
--- @class core.autocmds
local M = {}

local defaults = require("core.defaults")
local lifecycle = require("lib.lifecycle")
local notify = require("core.notify")

--- @type lib.Lifecycle
--- @type lib.Lifecycle?
local lc
--- @type table<string, { event: string|string[], opts: table }>
local registry = {}

--- Register a declarative autocommand (own augroup, clear-on-setup semantics).
--- @param id string unique id (used as augroup name)
--- @param event string|string[]
--- @param opts table `nvim_create_autocmd` options (`callback` or `command`)
--- @return boolean ok
--- @return string? err
function M.register(id, event, opts)
    if type(id) ~= "string" or id == "" then
        return false, "autocmd id must be a non-empty string"
    end
    if type(opts) ~= "table" or (opts.callback == nil and opts.command == nil) then
        return false, ("autocmd %q needs a callback or command"):format(id)
    end
    registry[id] = { event = event, opts = opts }
    if lc then
        -- Registry entries registered after setup are created immediately.
        lc:autocmd(
            event,
            vim.tbl_extend("force", { group_name = id, desc = opts.desc or id }, opts)
        )
    end
    return true
end

--- Fire the `User VeryLazy` event (plugins declare `event = 'VeryLazy'`).
function M.fire_very_lazy()
    vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
end

--- Setup the global autocommands described in `defaults.autocmds`.
--- @param opts? table
function M.setup(opts)
    opts = opts or defaults.get("autocmds", {})
    lc = lifecycle.new({ name = "core.autocmds" })

    if opts.last_position then
        lc:autocmd("BufReadPost", {
            group_name = "last_position",
            desc = "core: restore last cursor position",
            callback = function(args)
                local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
                local lines = vim.api.nvim_buf_line_count(args.buf)
                if mark[1] > 0 and mark[1] <= lines and vim.bo[args.buf].buftype == "" then
                    pcall(vim.api.nvim_win_set_cursor, 0, mark)
                end
            end,
        })
    end

    if opts.highlight_yank and vim.hl and vim.hl.on_yank then
        lc:autocmd("TextYankPost", {
            group_name = "highlight_yank",
            desc = "core: highlight yanked region",
            callback = function()
                vim.hl.on_yank({ timeout = 200 })
            end,
        })
    end

    if opts.checktime_on_focus then
        lc:autocmd({ "FocusGained", "TermClose", "TermLeave", "VimResume" }, {
            group_name = "checktime",
            desc = "core: reload files changed on disk",
            callback = function()
                if vim.o.buftype == "" and vim.fn.getcmdwintype() == "" then
                    vim.cmd.checktime()
                end
            end,
        })
    end

    -- Existing registry entries (registered before setup, e.g. by user config).
    for id, def in pairs(registry) do
        lc:autocmd(
            def.event,
            vim.tbl_extend("force", { group_name = id, desc = def.opts.desc or id }, def.opts)
        )
    end

    -- Fire `User VeryLazy` once the UI/startup work is done.
    lc:autocmd("VimEnter", {
        group_name = "very_lazy",
        once = true,
        desc = "core: fire User VeryLazy",
        callback = function()
            vim.schedule(M.fire_very_lazy)
        end,
    })

    -- Report files that changed on disk while we were away.
    lc:autocmd("FileChangedShellPost", {
        group_name = "file_changed_notify",
        desc = "core: notify about externally modified files",
        callback = function(args)
            notify.info(("file changed on disk: %s"):format(vim.fn.fnamemodify(args.file, ":~:.")))
        end,
    })

    -- Indentation: keep one default for every filetype. Neovim's own ftplugins
    -- run before this and some of them choose other widths (`yaml` -> 2), so the
    -- configured values are applied buffer-locally afterwards. Filetypes in
    -- `indent.tabs` (make, go, ...) keep their toolchain's hard tabs.
    local indent = defaults.get("indent", {})
    if indent.enabled ~= false and type(indent.width) == "number" then
        lc:autocmd("FileType", {
            group_name = "indent",
            desc = "core: enforce the configured indentation",
            callback = function(args)
                local ft = vim.bo[args.buf].filetype
                if vim.tbl_contains(indent.tabs or {}, ft) then
                    return
                end
                local width = indent.width
                vim.bo[args.buf].expandtab = indent.expandtab ~= false
                vim.bo[args.buf].tabstop = width
                vim.bo[args.buf].shiftwidth = width
                vim.bo[args.buf].softtabstop = width
            end,
        })
    end

    lc:activate()
end

--- Teardown every autocommand owned by this module.
function M.teardown()
    if lc then
        lc:teardown()
        lc = nil
    end
end

return M
