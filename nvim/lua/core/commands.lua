--- User command registry and the built-in command set.
---
--- Commands are registered through `lib.lifecycle`, so `:ConfigReload` removes
--- and re-creates exactly the commands this configuration owns. Built-in
--- Neovim commands are never replaced: `M.register` detects them and refuses
--- unless the caller explicitly overrides.
---
--- @class core.commands
local M = {}

local lifecycle = require("lib.lifecycle")
local notify = require("core.notify")

--- @type lib.Lifecycle
--- @type lib.Lifecycle?
local lc
--- @type table<string, { rhs: string|function, opts: table, owner: string }>
local registry = {}

--- Is `name` a built-in Neovim command?
---
--- `exists(':Name')` reports user commands as well (it does *not* return 1 for
--- them in 0.12), so the authoritative test is: not visible through
--- `nvim_get_commands()` but resolvable through `exists()`.
--- @param name string
--- @return boolean
function M.is_builtin(name)
    if vim.api.nvim_get_commands({})[name] ~= nil then
        return false
    end
    return vim.fn.exists(":" .. name) ~= 0
end

--- Register a user command.
--- @param name string
--- @param rhs string|function
--- @param opts? table `nvim_create_user_command` options (plus `owner`/`override`, which are ours)
--- @return boolean ok
--- @return string? err
function M.register(name, rhs, opts)
    opts = opts or {}
    if M.is_builtin(name) and not opts.override then
        return false, ("%q is a built-in Neovim command; refusing to override it"):format(name)
    end
    if
        vim.api.nvim_get_commands({})[name] ~= nil
        and registry[name] == nil
        and not opts.override
    then
        return false,
            ("%q is already defined by another plugin or configuration; pass override = true to replace it"):format(
                name
            )
    end
    local api_opts = vim.deepcopy(opts)
    api_opts.owner, api_opts.override = nil, nil
    local entry = {
        rhs = rhs,
        opts = vim.tbl_extend("force", { force = true }, api_opts),
        owner = opts.owner or "core",
    }
    registry[name] = entry
    if lc then
        lc:command(name, rhs, entry.opts)
    end
    return true
end

--- @return table[]
function M.inspect()
    local entries = vim.iter(registry)
        :map(function(name, entry)
            return {
                name = name,
                owner = entry.owner,
                args = entry.opts.nargs or 0,
                desc = entry.opts.desc or "",
            }
        end)
        :totable()
    table.sort(entries, function(a, b)
        return a.name < b.name
    end)
    return entries
end

--- Register the complete built-in command set.
---
--- Each command delegates to the module that implements it, which keeps this
--- file small and makes the command surface easy to inspect.
--- @return string[] problems
function M.setup()
    lc = lifecycle.new({ name = "core.commands" })
    local problems = {}

    local function add(name, rhs, opts)
        local ok, err =
            M.register(name, rhs, vim.tbl_extend("force", { owner = "core" }, opts or {}))
        if not ok then
            problems[#problems + 1] = tostring(err)
        end
    end

    -- Project root ------------------------------------------------------------
    add("Root", function(args)
        require("core.root").cmd(args)
    end, { nargs = "?", complete = "buffer", desc = "Inspect the resolved project root" })
    add("RootClear", function()
        require("core.root").clear()
    end, { desc = "Clear the root cache" })

    -- Formatting --------------------------------------------------------------
    add("Format", function(args)
        require("core.format").cmd(args)
    end, { nargs = 0, range = true, desc = "Format buffer, selection or [count] line" })
    add("FormatInfo", function()
        require("core.format").cmd_info()
    end, { desc = "Show autoformat gates and formatter provider state" })

    -- LSP ---------------------------------------------------------------------
    add("LspLog", function()
        require("core.lsp").open_log()
    end, { desc = "Open the Neovim LSP log" })
    add("LspInfo", function()
        require("core.lsp").cmd_info()
    end, { desc = "Inspect active LSP clients and configs" })
    add("LspExec", function(args)
        require("core.lsp").cmd_exec(args)
    end, { nargs = "*", complete = "file", desc = "Run an LSP command with JSON arguments" })

    -- Terminal ----------------------------------------------------------------
    add("Terminal", function(args)
        require("core.terminal").cmd(args)
    end, {
        nargs = "?",
        complete = function()
            return { "1", "2", "3", "next", "close" }
        end,
        desc = "Toggle a terminal slot",
    })
    add("Lazygit", function(args)
        require("core.terminal").cmd_lazygit(args)
    end, {
        nargs = "?",
        complete = function()
            return { "root", "cwd" }
        end,
        desc = "Open lazygit at the project root or cwd",
    })

    -- Toggles -----------------------------------------------------------------
    add("Toggles", function(args)
        require("core.toggle").cmd(args)
    end, {
        nargs = "?",
        complete = function()
            return require("core.toggle").ids()
        end,
        desc = "Inspect or flip toggles",
    })

    -- Plugin management -------------------------------------------------------
    add("PackInstall", function(args)
        require("core.pack").cmd_install(args)
    end, {
        nargs = "*",
        complete = function()
            return require("core.pack").ids()
        end,
        desc = "Install declared plugins without loading them",
    })
    add("PackUpdate", function(args)
        require("core.pack").cmd_update(args)
    end, {
        nargs = "*",
        complete = function()
            return require("core.pack").ids()
        end,
        desc = "Review and apply plugin updates (native vim.pack)",
    })
    add("PackCheck", function()
        require("core.pack").cmd_check()
    end, { desc = "Check for plugin updates without changing state" })
    add("PackStatus", function()
        require("core.pack").cmd_status()
    end, { desc = "Inspect declared plugins and vim.pack state" })

    -- Reload ------------------------------------------------------------------
    add("ConfigReload", function()
        require("core.reload").cmd_reload()
    end, { desc = "Reload the configuration (soft, duplicate-free)" })
    add("ConfigWatch", function(args)
        require("core.reload").cmd_watch(args)
    end, {
        nargs = "?",
        complete = function()
            return { "on", "off", "status" }
        end,
        desc = "Control the configuration file watcher",
    })

    for _, problem in ipairs(problems) do
        notify.error("core.commands: " .. problem)
    end
    lc:activate()
    return problems
end

--- Teardown every command created by this module.
function M.teardown()
    if lc then
        lc:teardown()
        lc = nil
    end
end

return M
