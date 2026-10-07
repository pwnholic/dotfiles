--- fzf-lua: fuzzy picker for files, grep, buffers, LSP, git and more.
---
--- Loaded lazily: the keymaps below and `:FzfLua` are pack triggers; loading runs
--- `config()`, which
---
---   * calls `fzf-lua.setup()` — the module's defaults (flex preview, multi-select,
---     preview scrolling keys) are the intended UI. The only override is the float
---     border: it follows `vim.opt.winborder` like every other floating window,
---   * registers fzf-lua as `vim.ui.select`, so the native selections of this
---     configuration (`:LspExec`, `:Toggles`, `vim.ui.input` flows) use the picker,
---   * creates the keymaps from `defaults.picker.keys`.
---
--- File/grep/git pickers run in the detected project root (`core.root`) when
--- `defaults.picker.use_project_root` is true, and fall back to Neovim's cwd.
--- Buffer-local pickers (resume, diagnostics, symbols, help, keymaps) never force
--- a cwd.
---
--- @class plugins.fzf_lua
local M = {}

--- @type lib.Lifecycle? owner of the picker keymaps
local lc

local SRC = "https://github.com/ibhagwan/fzf-lua"

--- Data-driven mapping between configuration keys and fzf-lua providers.
--- `mode` defaults to 'n'; `root = false` keeps the picker cwd-independent.
local PICKERS = {
    files = { provider = "files", desc = "find files" },
    grep = { provider = "live_grep", desc = "live grep" },
    grep_word = {
        provider = "grep_cword",
        desc = "grep current word",
        mode = { "n", "x" },
        root = false,
    },
    buffers = { provider = "buffers", desc = "buffers", root = false },
    resume = { provider = "resume", desc = "resume last picker", root = false },
    diagnostics = { provider = "diagnostics_document", desc = "buffer diagnostics", root = false },
    symbols = { provider = "lsp_document_symbols", desc = "document symbols", root = false },
    help = { provider = "helptags", desc = "help tags", root = false },
    keymaps = { provider = "keymaps", desc = "keymaps", root = false },
    git_commits = {
        provider = "git_commits",
        desc = "git commits",
        mode = { "n", "x" },
        root = true,
    },
    git_branches = { provider = "git_branches", desc = "git branches", root = true },
    git_status = { provider = "git_status", desc = "git status", root = true },
}

--- @param name string
--- @return table? entry
--- @return string? err
local function entry_of(name)
    local entry = PICKERS[name]
    if not entry then
        return nil,
            ("unknown picker %q (known: %s)"):format(tostring(name), table.concat(M.list(), ", "))
    end
    return entry
end

--- @param entry table
--- @return string[]
local function modes_of(entry)
    if entry.mode == nil then
        return { "n" }
    end
    return type(entry.mode) == "table" and entry.mode or { entry.mode }
end

--- Configured keymaps (only the enabled ones).
--- @return table<string, { entry: table, modes: string[] }>
function M.mapped()
    local keys = require("core.defaults").get("picker.keys", {})
    local out = {}
    for name, entry in pairs(PICKERS) do
        if keys[name] then
            out[name] = { entry = entry, modes = modes_of(entry) }
        end
    end
    return out
end

--- @return string[] picker names
function M.list()
    local names = vim.tbl_keys(PICKERS)
    table.sort(names)
    return names
end

--- Options for one picker: root-aware cwd plus nothing else (fzf-lua defaults).
--- Exposed so the cwd policy is testable without opening a picker.
--- @param name string
--- @return table opts
function M.picker_opts(name)
    local entry, err = entry_of(name)
    if not entry then
        error(err, 0)
    end

    local opts = {}
    local picker = require("core.defaults").get("picker", {})
    if entry.root ~= false and picker.use_project_root ~= false then
        local root = require("core.root").get(0)
        if root then
            opts.cwd = root
        end
    end
    return opts
end

--- Run one picker.
--- @param name string
function M.pick(name)
    local entry, err = entry_of(name)
    if not entry then
        require("core.notify").error("fzf-lua: " .. err)
        return
    end

    local FzfLua = require("fzf-lua")
    local provider = FzfLua[entry.provider]
    if type(provider) ~= "function" then
        require("core.notify").error(
            ("fzf-lua: provider %q is not available"):format(entry.provider)
        )
        return
    end
    return provider(M.picker_opts(name))
end

--- Create the configured keymaps.
--- The mappings are owned by a lifecycle object (same name = previous generation
--- is torn down first), so disabling a picker key really removes it and a reload
--- cannot leave a stale mapping behind.
function M.map_keys()
    local notify = require("core.notify")
    lc = require("lib.lifecycle").new({ name = "plugins.fzf_lua" })

    for name, mapped in pairs(M.mapped()) do
        local lhs = require("core.defaults").get("picker.keys", {})[name]
        for _, mode in ipairs(mapped.modes) do
            local ok, err = pcall(function()
                lc:keymap(mode, lhs, function()
                    M.pick(name)
                end, { desc = ("fzf-lua: %s"):format(mapped.entry.desc) })
            end)
            if not ok then
                notify.error(("fzf-lua: cannot map %s (%s): %s"):format(lhs, name, tostring(err)))
            end
        end
    end
    lc:activate()
end

--- Keymap triggers declared to `core.pack` (one entry per mode).
--- @return table[]
local function trigger_keys()
    local keys = require("core.defaults").get("picker.keys", {})
    local out = {}
    for name, entry in pairs(PICKERS) do
        local lhs = keys[name]
        if lhs then
            for _, mode in ipairs(modes_of(entry)) do
                out[#out + 1] = { lhs, mode = mode, desc = ("fzf-lua: %s"):format(entry.desc) }
            end
        end
    end
    return out
end

function M.setup()
    local picker = require("core.defaults").get("picker", {})
    if picker.enabled == false then
        return
    end

    local ok, err = require("core.pack").register({
        src = SRC,
        name = "fzf-lua",
        cmd = { "FzfLua" },
        keys = trigger_keys(),
        reloadable = true,
        config = M.configure,
    })
    if not ok then
        require("core.notify").error("fzf_lua: " .. tostring(err))
    end
end

function M.configure()
    local FzfLua = require("fzf-lua")
    -- Borders: fzf-lua ships its own `winopts.border = "rounded"`, so the global
    -- option has to be handed over explicitly (main window *and* native previewer).
    local function apply_border()
        FzfLua.setup({
            winopts = {
                border = vim.o.winborder,
                preview = { border = vim.o.winborder },
            },
        })
    end
    apply_border()
    -- Silent + idempotent: re-running the configuration on :ConfigReload is fine.
    FzfLua.register_ui_select({}, true)
    M.map_keys()

    -- Keep following the option instead of the value captured at load time: a
    -- `:set winborder=` (or a new theme/option batch) re-applies it. Owned by the
    -- module lifecycle, so a reload cannot leave a duplicate behind.
    if lc then
        lc:autocmd("OptionSet", {
            pattern = "winborder",
            desc = "fzf-lua: follow vim.opt.winborder",
            callback = apply_border,
        })
    end
end

function M.teardown()
    -- Give `vim.ui.select` back to Neovim and drop the mappings we own; the
    -- reloadable configuration re-creates them.
    pcall(require("fzf-lua").deregister_ui_select)
    if lc then
        lc:teardown()
        lc = nil
    end
end

--- Provider table (used by tests to validate the wiring without opening a UI).
--- @return table
function M.pickers()
    return vim.deepcopy(PICKERS)
end

return M
