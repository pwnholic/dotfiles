--- `:checkhealth config`
---
--- Uses the official Neovim health API (`vim.health`). Every check resolves
--- real state: executables, paths, parsers, `vim.pack` state. Optional tools
--- that are missing are reported as WARN (or INFO when the integration is
--- genuinely optional), never as ERROR.
---
--- Implementation note: `:checkhealth config` resolves
--- `lua/**/config/health.lua`; `lua/config/health.lua` forwards here so the
--- implementation can stay in `core`.
---
--- @class core.health
local M = {}

local health = vim.health
local defaults = require("core.defaults")
local fs = require("lib.fs")
local json = require("lib.json")
local process = require("lib.process")

--- @param path string|nil
--- @return string
local function where(path)
    return path and (" (%s)"):format(path) or ""
end

--- ---------------------------------------------------------------------------
--- Runtime / core subsystems
--- ---------------------------------------------------------------------------

function M.check_runtime()
    health.start("core: runtime")

    if vim.fn.has("nvim-0.12") == 1 then
        health.ok(
            ("Neovim %s >= 0.12"):format(
                vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch
            )
        )
    else
        health.error("Neovim 0.12+ is required by this configuration")
    end

    if type(vim.pack) == "table" and type(vim.pack.add) == "function" then
        health.ok("vim.pack available (native plugin management)")
    else
        health.error("vim.pack is not available; plugin management is disabled")
    end

    health.info("config: " .. fs.config_path())
    health.info("state:  " .. fs.state_path())
    health.info("data:   " .. fs.data_path())

    local ok, core = pcall(require, "core")
    if not ok then
        health.error(("core module cannot be loaded: %s"):format(tostring(core)))
        return
    end
    local errors = core.errors or {}
    if #errors == 0 then
        health.ok(
            ("core subsystems initialized (%d setup passes)"):format(
                (core.state or {}).setup_count or 1
            )
        )
    else
        for _, entry in ipairs(errors) do
            health.error(("%s failed to initialize: %s"):format(entry.module, entry.error))
        end
    end

    local notify = require("core.notify")
    health.info(("notifier backend: %s"):format(notify.backend_name()))
    local history = notify.history()
    local notable = vim.iter(history)
        :filter(function(entry)
            return entry.level >= vim.log.levels.WARN
        end)
        :totable()
    if #notable > 0 then
        health.warn(
            ("%d warning/error notification(s) this session, latest: %s"):format(
                #notable,
                notable[#notable].msg
            )
        )
    end
    if notify.backend_name() == "vim.notify" then
        health.info(
            "mini.notify is not loaded yet; the native notifier is used (expected before plugins load)"
        )
    end

    local reload = require("core.reload")
    local watch = reload.watch_state()
    if watch.enabled then
        health.ok(
            ("config watcher: %d director%s watched"):format(
                watch.watched,
                watch.watched == 1 and "y" or "ies"
            )
        )
    else
        health.warn("config watcher is disabled (:ConfigWatch on)")
    end
    if watch.auto_reload then
        health.info("auto_reload is enabled: :ConfigReload runs on change")
    end
    if watch.auto_restart then
        health.warn("auto_restart is enabled: plugin updates will restart Neovim automatically")
    end

    local format = require("core.format")
    health.info(
        ("formatting: global gate %s, provider %s"):format(
            format.enabled() and "ON" or "OFF",
            format.provider_name() or "<none loaded>"
        )
    )
    local root = require("core.root")
    health.info(
        ("project root: %s (strategies: %s)"):format(
            root.context_root(),
            vim.iter(root.list_strategies())
                :map(function(def)
                    return def.id
                end)
                :join(", ")
        )
    )
    local wanted = defaults.get("options.colorscheme")
    local active = vim.g.colors_name
    if wanted == nil then
        -- The theme plugin records the scheme in `options.colorscheme` when it
        -- loads, so before that there is nothing to compare against.
        health.info(("colorscheme: %s"):format(active or "default"))
    elseif active == wanted then
        health.ok(("colorscheme: %s"):format(active))
    elseif wanted then
        health.warn(
            ("colorscheme %s is configured but %s is active (plugin not installed? try :PackInstall)"):format(
                wanted,
                tostring(active or "none")
            )
        )
    end
end

--- ---------------------------------------------------------------------------
--- Tools
--- ---------------------------------------------------------------------------

function M.check_tools()
    health.start("core: tools")
    local tools = require("core.tools")
    local results = tools.check_all()
    for _, result in ipairs(results) do
        local purpose = result.purpose ~= "" and (" - " .. result.purpose) or ""
        if result.available then
            health.ok(
                ("%s%s%s"):format(
                    result.cmd,
                    where(result.path),
                    result.version and (" [" .. result.version .. "]") or ""
                )
            )
        elseif result.required then
            health.error(("%s not found%s%s"):format(result.cmd, purpose, " (required)"))
        else
            health.warn(("%s not found%s%s"):format(result.cmd, purpose, " (optional)"))
        end
    end
end

--- ---------------------------------------------------------------------------
--- Formatters
--- ---------------------------------------------------------------------------

function M.check_formatters()
    health.start("core: formatters")
    local format = require("core.format")

    if format.provider_name() then
        health.ok(("provider: %s"):format(format.provider_name()))
    else
        local declared = #format.list_formatters()
        if declared > 0 then
            health.info(
                ("provider not loaded yet (lazy, ex. conform.nvim); %d formatter(s) declared by core"):format(
                    declared
                )
            )
        else
            health.warn("no formatting provider and no formatters declared")
        end
    end

    local registered = format.list_formatters()
    if #registered == 0 then
        health.info("no formatters registered by the core registry")
    end
    for _, spec in ipairs(registered) do
        local path = process.executable(spec.cmd)
        if path then
            local version = process.version(spec.cmd)
            health.ok(
                ("%s -> %s%s"):format(spec.id, spec.cmd, version and (" [" .. version .. "]") or "")
            )
        else
            health.warn(
                ("%s: executable %q not found; buffers using it will not be formatted"):format(
                    spec.id,
                    spec.cmd
                )
            )
        end
    end

    local map = format.filetype_map()
    local fts = vim.tbl_keys(map)
    table.sort(fts)
    if #fts > 0 then
        local parts = vim.iter(fts)
            :map(function(ft)
                return ("%s=%s"):format(ft, table.concat(map[ft], ","))
            end)
            :join(" ")
        health.info("filetype -> formatters: " .. parts)
    end
end

--- ---------------------------------------------------------------------------
--- LSP
--- ---------------------------------------------------------------------------

function M.check_lsp()
    health.start("core: LSP")

    local lsp = require("core.lsp")
    local mason_bin = lsp.mason_bin()
    local mason_root = fs.data_path("mason")
    if mason_bin then
        local packages = fs.list(fs.joinpath(mason_root, "packages"), { dirs_only = true })
        health.ok(("mason: %d package(s) installed (%s)"):format(#packages, mason_bin))
        if #packages > 0 then
            health.info("  installed: " .. table.concat(packages, ", "))
        end
        health.info("  install more with <leader>cM (missing servers) or <leader>cm (mason UI)")
    else
        health.info("mason is not installed; LSP binaries are resolved from PATH only")
    end

    local servers = lsp.server_info()
    if #servers == 0 then
        health.info("no LSP servers are registered (see lua/plugins/lsp.lua)")
    end
    for _, server in ipairs(servers) do
        if server.cmd == nil and server.source ~= "registry" then
            -- Native `lsp/<name>.lua` config: the name exists in the runtimepath and
            -- Neovim merges the file (including `cmd`) when a client starts, so the
            -- command cannot be reported before that.
            health.info(
                ("%s: configured in %s; the command is resolved when a client starts"):format(
                    server.name,
                    server.source
                )
            )
        elseif server.cmd == nil then
            health.info(
                ("%s: command is computed at runtime; availability is the server's responsibility"):format(
                    server.name
                )
            )
        else
            local path = process.executable(server.cmd)
            if path then
                health.ok(("%s -> %s (%s)"):format(server.name, server.cmd, path))
            elseif server.enabled then
                health.error(
                    ("%s: %q not found in PATH%s; the server is enabled but cannot start"):format(
                        server.name,
                        server.cmd,
                        mason_bin and (" (check " .. mason_bin .. ")") or ""
                    )
                )
            else
                health.warn(
                    ("%s: %q not found in PATH%s (server skipped)"):format(
                        server.name,
                        server.cmd,
                        mason_bin and (" (check " .. mason_bin .. ")") or ""
                    )
                )
            end
        end
    end

    local clients = lsp.clients()
    health.info(
        ("active clients: %d%s"):format(#clients, #clients > 0 and (" (" .. vim.iter(clients)
            :map(function(c)
                return c.name
            end)
            :join(", ") .. ")") or "")
    )
    for _, client in ipairs(clients) do
        if client:supports_method("workspace/willRenameFiles") then
            health.info(
                ("%s supports workspace/willRenameFiles (oil file operations are applied)"):format(
                    client.name
                )
            )
        end
    end

    if fs.is_file(lsp.log_path()) then
        health.info("log: " .. lsp.log_path())
    else
        health.info("log: " .. lsp.log_path() .. " (no LSP activity yet)")
    end
end

--- ---------------------------------------------------------------------------
--- Treesitter
--- ---------------------------------------------------------------------------

function M.check_treesitter()
    health.start("core: Treesitter parsers")

    local ok_ts = vim.treesitter.language.add("query") ~= nil
    if not ok_ts then
        health.warn(
            'the bundled "query" parser is not available; Treesitter queries cannot be inspected'
        )
    end

    -- "installed" (on disk) and "loaded" are different states: `nvim-treesitter`
    -- is only added to 'runtimepath' when its trigger fires, so the actionable
    -- hint depends on the pack state, not on 'runtimepath'.
    local has_plugin = require("core.pack").is_installed("nvim-treesitter")

    local languages = require("core.defaults").get("health.treesitter_languages", {})
    local missing, available = {}, {}
    for _, lang in ipairs(languages) do
        -- `language.add()` returns `nil, err` for a missing parser (it does not
        -- raise), so the return value -- not `pcall` -- carries the answer.
        local ok_lang = vim.treesitter.language.add(lang)
        if ok_lang then
            available[#available + 1] = lang
        else
            missing[#missing + 1] = lang
        end
    end

    if #available > 0 then
        health.ok(("installed parsers (%d): %s"):format(#available, table.concat(available, ", ")))
    end
    if #missing > 0 then
        if has_plugin then
            health.warn(
                ("missing parsers (%d): %s -- install with :TSInstall %s"):format(
                    #missing,
                    table.concat(missing, ", "),
                    table.concat(missing, " ")
                )
            )
        else
            health.warn(
                ("missing parsers (%d): %s -- nvim-treesitter is not installed yet (:PackInstall nvim-treesitter)"):format(
                    #missing,
                    table.concat(missing, ", ")
                )
            )
        end
    end
    if #languages == 0 then
        health.info("no parser languages configured (defaults.health.treesitter_languages)")
    end
end

--- ---------------------------------------------------------------------------
--- vim.pack state
--- ---------------------------------------------------------------------------

function M.check_pack()
    health.start("core: plugins (vim.pack)")

    local pack = require("core.pack")
    local lockfile = fs.config_path("nvim-pack-lock.json")

    if not process.have("git") then
        health.error("git is required by vim.pack and was not found in PATH")
        return
    end
    health.ok("git: " .. tostring(process.executable("git")))

    -- Filesystem view only: a health check must not call `vim.pack.get()`,
    -- because that can install plugins listed in the lockfile (native behaviour).
    local pack_dir = fs.data_path("site", "pack", "core", "opt")
    local installed = fs.list(pack_dir, { dirs_only = true })
    local by_name = {}
    vim.iter(installed):each(function(name)
        by_name[name] = true
    end)

    health.info(("managed on disk: %d plugin(s)"):format(#installed))
    if fs.is_file(lockfile) then
        local data, err = json.read(lockfile)
        if err then
            health.error(("lockfile %s is not valid JSON: %s"):format(lockfile, err))
        else
            local lock_names = vim.iter(data.plugins or {})
                :map(function(name)
                    return name
                end)
                :totable()
            table.sort(lock_names)
            health.ok(("lockfile: %s (%d entries)"):format(lockfile, #lock_names))
            for _, name in ipairs(lock_names) do
                if not by_name[name] then
                    health.warn(
                        ("lockfile lists %q but it is not on disk; run :PackInstall"):format(name)
                    )
                end
            end
        end
    else
        health.info("no lockfile yet at " .. lockfile .. " (created on the first vim.pack call)")
    end

    local declared = pack.list()
    local missing_specs = vim.iter(declared)
        :map(function(def)
            if by_name[def.id] then
                return nil
            end
            return def.id
        end)
        :totable()
    if #missing_specs > 0 then
        health.warn(
            ("declared but not installed (%d): %s -- run :PackInstall %s"):format(
                #missing_specs,
                table.concat(missing_specs, ", "),
                table.concat(missing_specs, " ")
            )
        )
    elseif #declared > 0 then
        health.ok(("all %d declared plugin(s) are on disk"):format(#declared))
    end
    local unloaded = vim.iter(declared)
        :map(function(def)
            if pack.is_loaded(def.id) then
                return nil
            end
            return def.id
        end)
        :totable()
    if #unloaded > 0 then
        health.info(("not loaded yet (lazy, expected): %s"):format(table.concat(unloaded, ", ")))
    end

    local state = pack.inspect().update_state or {}
    if state.last_check then
        local updates = state.last_result and state.last_result.updates or {}
        local names = vim.iter(updates)
            :map(function(item)
                return item.name
            end)
            :totable()
        if #names > 0 then
            health.warn(
                ("update check (%s): %d update(s) available: %s -- review with :PackUpdate"):format(
                    os.date("%Y-%m-%d %H:%M", state.last_check),
                    #names,
                    table.concat(names, ", ")
                )
            )
        else
            health.ok(
                ("update check (%s): no updates available"):format(
                    os.date("%Y-%m-%d %H:%M", state.last_check)
                )
            )
        end
    else
        health.info("no plugin update check has run yet (:PackCheck)")
    end
end

--- Source path of a loaded module.
---
--- Neovim does not resolve configuration modules through `package.path` (it
--- searches the runtimepath), so the *loaded* module is the source of truth: the
--- path comes from the source of one of its functions.
--- @param name string
--- @return string? path
local function module_source(name)
    local loaded = package.loaded[name]
    if type(loaded) ~= "table" then
        return nil
    end
    local name_path = name:gsub("%.", "/")
    for _, value in pairs(loaded) do
        if type(value) == "function" then
            local info = debug.getinfo(value, "S")
            local source = info and info.source or ""
            if source:sub(1, 1) == "@" then
                local path = source:sub(2)
                if path:find("lua/" .. name_path, 1, true) then
                    return vim.uv.fs_realpath(path) or path
                end
            end
        end
    end
    return nil
end

--- Split modules live in a directory with `init.lua` as the entry point. The flat
--- form (`lua/core/x.lua`) is never kept next to it: Lua searches `?.lua` before
--- `?/init.lua`, so a leftover flat file silently wins and the directory turns
--- into dead code. Both facts are verified here.
function M.check_module_paths()
    health.start("core: module resolution")
    local config = fs.config_path()
    --- @type table<string, string>
    local split = {
        ["core.pack"] = "core/pack/init.lua",
        ["core.lsp"] = "core/lsp/init.lua",
    }
    for name, relative in pairs(split) do
        local want = fs.joinpath(config, "lua", relative)
        local resolved = module_source(name)
        if resolved == nil then
            health.info(("%s is not loaded yet (checked when it is)"):format(name))
        elseif resolved == want or resolved:sub(-#relative - 4) == "lua/" .. relative then
            health.ok(("%s -> lua/%s"):format(name, relative))
        else
            health.warn(
                ("%s loaded from %s, expected lua/%s (shadowed flat file?)"):format(
                    name,
                    vim.fn.fnamemodify(resolved, ":~"),
                    relative
                )
            )
        end
        -- `gsub` returns two values: assigning to one local keeps only the path
        -- (passing it straight into `joinpath` would append the replacement count).
        local flat = relative:gsub("/init%.lua$", ".lua")
        local shadow = fs.joinpath(config, flat)
        if vim.uv.fs_stat(shadow) then
            health.warn(
                ("flat file shadows the module directory: %s (delete it)"):format(
                    vim.fn.fnamemodify(shadow, ":~")
                )
            )
        else
            health.ok(("no flat shadow for %s"):format((relative:gsub("/init%.lua$", ""))))
        end
    end
end

--- Entry point used by `:checkhealth config`.
function M.check()
    M.check_runtime()
    M.check_module_paths()
    M.check_tools()
    M.check_formatters()
    M.check_lsp()
    M.check_treesitter()
    M.check_pack()
end

return M
