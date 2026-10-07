--- Lazy-loading triggers: `cmd` / `keys` / `ft` / `event` stubs.
---
--- Split out of `core/pack/init.lua` (the loader). A trigger is a *placeholder*
--- that loads a plugin once and then removes itself: loading always happens after
--- the placeholder is gone, so the name (command) or mapping then belongs to the
--- plugin and must not be deleted a second time.
---
--- The loader injects what it owns (`registry` and the load function) through
--- `M.setup()`; the stub state lives here, and `M.remove(id)` is what the loader
--- calls right before `:packadd` so "loaded" and "has stubs" stay mutually
--- exclusive.

local notify = require("core.notify")

--- Trigger stubs created for declared-but-unloaded plugins. Loading a plugin
--- removes them, so "loaded" and "has stubs" cannot both be true.
--- @type table<string, { autocmds: integer[], commands: string[], keys: { mode: string, lhs: string }[] }>
local stubs = {}

--- @class core.pack.triggers
--- @field setup fun(o: core.pack.triggers.ctx)
--- @field remove fun(id: string)
--- @field setup_triggers fun()
local M = {}

--- Injected by `core.pack.setup()`.
--- @class core.pack.triggers.ctx
--- @field registry lib.Registry
--- @field load fun(id: string): boolean
--- @field is_loaded fun(id: string): boolean
--- @field is_configured fun(id: string): boolean
--- @field lifecycle fun(): lib.Lifecycle

--- Injected by `core.pack.setup()`.
--- @type core.pack.triggers.ctx
local ctx = {
    registry = require("lib.registry").new({ name = "pack.triggers.unbound" }),
    load = function()
        return false
    end,
    is_loaded = function()
        return false
    end,
    is_configured = function()
        return false
    end,
    lifecycle = function()
        return require("lib.lifecycle").new({ name = "core.pack.triggers" })
    end,
}

--- Drop the stub bookkeeping (the loader calls this from `teardown`).
function M.reset()
    stubs = {}
end

--- @param o core.pack.triggers.ctx
function M.setup(o)
    ctx = o or ctx
end

--- @param id string
--- @return { autocmds: integer[], commands: string[], keys: { mode: string, lhs: string }[] }
local function stub_entry(id)
    if not stubs[id] then
        stubs[id] = { autocmds = {}, commands = {}, keys = {} }
    end
    return stubs[id]
end

--- Forget one stub entry whose callback already removed it. Loading happens
--- after the placeholder is gone, so by then the name (command) or the mapping
--- belongs to the plugin itself and must not be deleted a second time.
--- @param id string
--- @param kind "commands"|"keys"
--- @param match string|{ mode: string, lhs: string }
local function forget_stub(id, kind, match)
    local entry = stubs[id]
    if not entry then
        return
    end
    local kept = {}
    for _, item in ipairs(entry[kind]) do
        local same
        if type(match) == "string" then
            same = item == match
        else
            same = type(item) == "table" and item.mode == match.mode and item.lhs == match.lhs
        end
        if not same then
            kept[#kept + 1] = item
        end
    end
    entry[kind] = kept
end

--- Remove every stub that belongs to `id` (autocommands that would load it,
--- placeholder commands and placeholder keymaps).
--- @param id string
function M.remove(id)
    local entry = stubs[id]
    if not entry then
        return
    end
    for _, autocmd in ipairs(entry.autocmds) do
        local owner = ctx.lifecycle()
        if owner then
            pcall(owner.del_autocmd, owner, autocmd)
        else
            pcall(vim.api.nvim_del_autocmd, autocmd)
        end
    end
    for _, name in ipairs(entry.commands) do
        pcall(vim.api.nvim_del_user_command, name)
    end
    for _, key in ipairs(entry.keys) do
        pcall(vim.keymap.del, key.mode, key.lhs)
    end
    stubs[id] = nil
end

--- ---------------------------------------------------------------------------
--- Triggers
--- ---------------------------------------------------------------------------

--- @param spec table
--- @param event string
--- @return fun(ev: table)
local function event_loader(spec, event)
    local id
    local function load_and_refire(ev)
        if id then
            pcall(vim.api.nvim_del_autocmd, id)
        end
        if not ctx.load(spec.id) then
            return
        end
        -- The plugin's own autocommands were created while loading and did not run
        -- for this occurrence (verified behaviour), so re-fire it for them.
        local refire = {
            pattern = ev.match ~= "" and ev.match or nil,
            modeline = false,
            data = ev.data,
        }
        if ev.buf and ev.buf > 0 then
            refire.buffer = ev.buf
        end
        pcall(vim.api.nvim_exec_autocmds, event, refire)
    end
    return load_and_refire
end

--- @param def table
local function setup_cmd_triggers(def)
    local util = require("lib.util")
    local owner = ctx.lifecycle()
    assert(owner ~= nil, "trigger setup requires an active lifecycle")
    for _, entry in ipairs(util.to_list(def.cmd)) do
        local name, command_opts
        if type(entry) == "table" then
            name, command_opts = entry.name or entry[1], vim.tbl_extend("force", {}, entry)
            command_opts.name = nil
            command_opts[1] = nil
        else
            name = entry
        end
        if type(name) ~= "string" or name == "" then
            notify.error(("plugin %s: invalid `cmd` entry"):format(def.id))
            return
        end
        command_opts = vim.tbl_extend("force", {
            nargs = "*",
            range = true,
            bang = true,
            bar = true,
            desc = ("%s (loads %s)"):format(name, def.id),
        }, command_opts or {})

        local bookkeeping = stub_entry(def.id)
        bookkeeping.commands[#bookkeeping.commands + 1] = name
        local command_name = name -- narrowed above; captured by the closure below
        owner:command(command_name, function(args)
            owner:del_command(command_name)
            -- The stub is gone before loading, so its bookkeeping entry is
            -- dropped here: after loading, the name belongs to the plugin.
            forget_stub(def.id, "commands", command_name)
            if not ctx.load(def.id) then
                return
            end
            local parts = {}
            if args.mods and args.mods ~= "" then
                parts[#parts + 1] = args.mods
            end
            if args.range == 2 then
                parts[#parts + 1] = ("%d,%d"):format(args.line1, args.line2)
            elseif args.range == 1 then
                parts[#parts + 1] = tostring(args.line1)
            end
            parts[#parts + 1] = name .. (args.bang and "!" or "")
            if args.args and args.args ~= "" then
                parts[#parts + 1] = args.args
            end
            local cmdline = table.concat(parts, " ")
            local ok, err = pcall(vim.cmd, cmdline)
            if not ok then
                notify.error(("replaying %q failed: %s"):format(cmdline, notify.error_text(err)))
            end
        end, command_opts)
    end
end

--- @param def table
local function setup_key_triggers(def)
    local util = require("lib.util")
    local owner = ctx.lifecycle()
    assert(owner ~= nil, "trigger setup requires an active lifecycle")
    for _, entry in ipairs(util.to_list(def.keys)) do
        local lhs, mode, desc, extra
        if type(entry) == "table" then
            lhs = entry[1] or entry.lhs
            mode = entry.mode or "n"
            desc = entry.desc
            extra = vim.tbl_extend("force", {}, entry)
            extra[1], extra.lhs, extra.mode, extra.desc = nil, nil, nil, nil
        else
            lhs, mode = entry, "n"
        end
        if type(lhs) ~= "string" or lhs == "" then
            notify.error(("plugin %s: invalid `keys` entry"):format(def.id))
            return
        end
        local bookkeeping = stub_entry(def.id)
        bookkeeping.keys[#bookkeeping.keys + 1] = { mode = mode, lhs = lhs }
        owner:keymap(
            mode,
            lhs,
            function()
                pcall(vim.keymap.del, mode, lhs)
                forget_stub(def.id, "keys", { mode = mode, lhs = lhs })
                if not ctx.load(def.id) then
                    return
                end
                -- Re-dispatch the original keys so the plugin's own mapping runs.
                local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
                vim.api.nvim_feedkeys(keys, "m", false)
            end,
            vim.tbl_extend("force", {
                desc = desc or ("%s (loads %s)"):format(lhs, def.id),
                nowait = true,
                silent = true,
            }, extra or {})
        )
    end
end

--- Create one trigger autocommand.
--- @param def table
--- @param event_name string
--- @param pattern string|nil
local function add_trigger(def, event_name, pattern)
    local owner = ctx.lifecycle()
    assert(owner ~= nil, "trigger setup requires an active lifecycle")
    local ok, id_or_err = pcall(owner.autocmd, owner, event_name, {
        group_name = "pack_triggers",
        pattern = pattern ~= nil and pattern ~= "" and pattern or nil,
        desc = ("load %s"):format(def.id),
        callback = event_loader(def, event_name),
    })
    if not ok then
        notify.error(
            ("plugin %s: cannot create %s trigger%s: %s"):format(
                def.id,
                event_name,
                pattern and (" (pattern " .. pattern .. ")") or "",
                tostring(id_or_err)
            )
        )
        return
    end
    local bookkeeping = stub_entry(def.id)
    bookkeeping.autocmds[#bookkeeping.autocmds + 1] = id_or_err
end

--- Filetype triggers: one `FileType` autocommand per declared filetype.
--- @param def table
local function setup_ft_triggers(def)
    local util = require("lib.util")
    for _, entry in ipairs(util.to_list(def.ft)) do
        local pattern = type(entry) == "table" and (entry.pattern or entry[1]) or entry
        if type(pattern) ~= "string" or pattern == "" then
            notify.error(("plugin %s: invalid `ft` entry"):format(def.id))
            return
        end
        add_trigger(def, "FileType", pattern)
    end
end

--- Event triggers. Accepted forms:
---   'BufReadPost'                      -- plain autocommand event
---   'VeryLazy'                         -- sugar for `User VeryLazy`
---   { event = 'User', pattern = 'X' }  -- event + pattern
--- @param def table
local function setup_event_triggers(def)
    local util = require("lib.util")
    for _, entry in ipairs(util.to_list(def.event)) do
        local event, pattern
        if type(entry) == "table" then
            event = entry.event or entry[1]
            pattern = entry.pattern
        else
            event = entry
        end
        if event == "VeryLazy" then
            event, pattern = "User", "VeryLazy"
        end
        if type(event) ~= "string" or event == "" then
            notify.error(("plugin %s: invalid `event` entry"):format(def.id))
            return
        end
        add_trigger(def, event, pattern)
    end
end

--- Create the stubs for every declared-but-unloaded plugin.
--- Idempotent: existing stubs are removed first, so calling it again (after
--- declaring more plugins, or after a reload) cannot duplicate triggers.
function M.setup_triggers()
    for id in pairs(stubs) do
        M.remove(id)
    end
    for _, def in ipairs(ctx.registry:list()) do
        if def.enabled and def.lazy and not ctx.is_loaded(def.id) then
            if def.cmd then
                setup_cmd_triggers(def)
            end
            if def.keys then
                setup_key_triggers(def)
            end
            if def.ft then
                setup_ft_triggers(def)
            end
            if def.event then
                setup_event_triggers(def)
            end
        end
    end
end

return M
