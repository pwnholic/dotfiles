--- LSP helpers built on the modern `vim.lsp` API of Neovim 0.12.
---
--- Responsibilities:
---   * client / config / capability inspection (`vim.lsp.get_clients()`,
---     `vim.lsp.get_configs()`, `Client:supports_method()`),
---   * server registration + enablement with executable gating,
---   * `:LspLog` (through `vim.lsp.log.get_filename()`),
---   * `:LspExec` -- a generic, JSON-validated command runner,
---   * a data-driven `command_hints` registry (core, user, plugins),
---   * capability-checked file-operation helpers (`workspace/willRenameFiles`)
---     that never make a plain rename unreliable.
---
--- Extension points:
---   require('core.lsp').register_server('lua_ls', { ... })
---   require('core.lsp').register_command_hints('rust_analyzer', { ['rust-analyzer/...'] = { ... } })
---   require('core.lsp').register_command({ id = 'mycmd', server = 'lua_ls', command = 'lua....' })
---
--- @class core.lsp
local M = {}

local Registry = require("lib.registry")
local defaults = require("core.defaults")
local fs = require("lib.fs")
local notify = require("core.notify")
local process = require("lib.process")
local report = require("lib.report")

--- @type lib.Registry command hints (`{ server, command, description, schema, example }`)
local hints = Registry.new({ name = "lsp.command_hints" })
--- @type lib.Registry registered servers (`{ id, config, enabled }`)
local servers = Registry.new({ name = "lsp.servers" })
--- @type lib.Registry named command definitions (`{ id, server?, command, description?, args?, run? }`)
local commands = Registry.new({ name = "lsp.commands" })
local exec = require("core.lsp.exec")
--- @type table
local opts = {}

--- ---------------------------------------------------------------------------
--- Clients and capabilities
--- ---------------------------------------------------------------------------

--- Active clients, optionally filtered.
--- @param filter? vim.lsp.ClientFilter
--- @return vim.lsp.Client[]
function M.clients(filter)
    local ok, clients = pcall(vim.lsp.get_clients, filter or {})
    return ok and clients or {}
end

--- Clients attached to a buffer.
--- @param bufnr? integer
--- @return vim.lsp.Client[]
function M.buffer_clients(bufnr)
    local buf = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
    return M.clients({ bufnr = buf })
end

--- Does any client attached to the buffer support `method`?
--- @param bufnr? integer
--- @param method string
--- @return boolean supported
--- @return string[] client_names
function M.supports(bufnr, method)
    local names = {}
    for _, client in ipairs(M.buffer_clients(bufnr)) do
        if client:supports_method(method) then
            names[#names + 1] = client.name
        end
    end
    return #names > 0, names
end

--- Compact, printable description of a client.
--- @param client vim.lsp.Client
--- @return table
function M.client_info(client)
    local buffers = vim.iter(client.attached_buffers or {})
        :map(function(bufnr)
            return bufnr
        end)
        :totable()
    local caps = {
        formatting = client:supports_method("textDocument/formatting"),
        rename = client:supports_method("textDocument/rename"),
        code_action = client:supports_method("textDocument/codeAction"),
        inlay_hint = client:supports_method("textDocument/inlayHint"),
        completion = client:supports_method("textDocument/completion"),
        will_rename_files = client:supports_method("workspace/willRenameFiles"),
    }
    local advertised = {}
    local provider = client.server_capabilities
        and client.server_capabilities.executeCommandProvider
    for _, name in ipairs(type(provider) == "table" and provider.commands or {}) do
        advertised[#advertised + 1] = name
    end
    return {
        id = client.id,
        name = client.name,
        root_dir = client.root_dir,
        bufnr = client.bufnr,
        pid = client.rpc and client.rpc.pid,
        attached_buffers = buffers,
        capabilities = caps,
        command_count = #advertised,
        commands = advertised,
    }
end

--- Registered LSP configs (`vim.lsp.get_configs()`, 0.12+).
--- @param filter? { enabled?: boolean, filetype?: string }
--- @return vim.lsp.Config[]
function M.configs(filter)
    local ok, configs = pcall(vim.lsp.get_configs, filter or {})
    return ok and configs or {}
end

--- ---------------------------------------------------------------------------
--- Server registration / enablement
--- ---------------------------------------------------------------------------

--- The command a server config would spawn (nil when it is computed dynamically).
--- @param cfg table
--- @return string|nil
local function config_cmd(cfg)
    local cmd = cfg and cfg.cmd
    if type(cmd) == "table" then
        return cmd[1]
    end
    if type(cmd) == "string" then
        return cmd
    end
    return nil
end

--- Register a server configuration (does not start anything).
--- @param name string
--- @param cfg table `vim.lsp.Config`
--- @return boolean ok
--- @return string? err
function M.register_server(name, cfg)
    if type(name) ~= "string" or name == "" then
        return false, "server name must be a non-empty string"
    end
    if type(cfg) ~= "table" then
        return false, ("server %q: config must be a table"):format(name)
    end
    local ok, err = pcall(vim.lsp.config, name, cfg)
    if not ok then
        return false, ("server %q: %s"):format(name, tostring(err))
    end
    return servers:register({ id = name, config = cfg, enabled = false }, { replace = true })
end

--- @class core.lsp.NativeConfig
--- @field path string
--- @field after boolean

--- Configuration names Neovim resolves from `lsp/` / `after/lsp/` in 'runtimepath'
--- (`:help lsp-config-merge`). `after/lsp/` wins for the same name.
--- @return table<string, core.lsp.NativeConfig>
function M.native_configs()
    local out = {}
    for _, glob in ipairs({ "lsp/*.lua", "after/lsp/*.lua" }) do
        local is_after = glob:sub(1, 5) == "after"
        for _, path in ipairs(vim.api.nvim_get_runtime_file(glob, true)) do
            local name = vim.fn.fnamemodify(path, ":t:r")
            if out[name] == nil or is_after then
                out[name] = { path = path, after = is_after }
            end
        end
    end
    return out
end

--- Every server that should be considered: the registry first (a registry config
--- has the highest merge priority, so it shadows a native config with the same
--- name), then the native `lsp/` configs.
--- @class core.lsp.ServerEntry
--- @field id string
--- @field config table
--- @field source string

--- @return core.lsp.ServerEntry[]
local function all_servers()
    local out = {}
    for _, server in ipairs(servers:list()) do
        out[#out + 1] = { id = server.id, config = server.config, source = "registry" }
    end
    for name, info in pairs(M.native_configs()) do
        if not servers:has(name) then
            local ok, cfg = pcall(vim.lsp.config, name)
            out[#out + 1] = {
                id = name,
                config = ok and cfg or {},
                source = info.after and "after/lsp" or "lsp",
            }
        end
    end
    table.sort(out, function(a, b)
        return a.id < b.id
    end)
    return out
end

function M.server_info()
    local out = vim.iter(all_servers())
        :map(function(server)
            local cmd = config_cmd(server.config)
            local path = cmd and process.executable(cmd) or nil
            return {
                name = server.id,
                source = server.source,
                cmd = cmd,
                cmd_dynamic = cmd == nil,
                path = path,
                available = cmd == nil or path ~= nil,
                enabled = vim.lsp.is_enabled(server.id) and true or false,
                filetypes = server.config.filetypes or {},
                root_markers = server.config.root_markers,
            }
        end)
        :totable()
    table.sort(out, function(a, b)
        return a.name < b.name
    end)
    return out
end

--- Enable the registered servers whose executable exists.
--- Servers with a dynamic `cmd` are enabled as-is (they are responsible for
--- their own availability).
--- @return string[] enabled
--- @return table<string, string> skipped `{ name = reason }`
function M.enable_servers()
    if opts.enable == false then
        return {}, {}
    end
    local enabled, skipped = {}, {}
    for _, server in ipairs(all_servers()) do
        local cmd = config_cmd(server.config)
        -- A dynamic command (nil) is the server's own responsibility.
        if cmd == nil or process.executable(cmd) then
            vim.lsp.enable(server.id)
            enabled[#enabled + 1] = server.id
        else
            skipped[server.id] = ("executable %q not found"):format(cmd)
            if opts.notify_missing then
                notify.once(
                    ("lsp.missing.%s"):format(server.id),
                    ("LSP server %s skipped: %s"):format(server.id, cmd),
                    "WARN"
                )
            else
                notify.debug(
                    ("LSP server %s skipped: executable %q not found"):format(server.id, cmd)
                )
            end
        end
    end
    return enabled, skipped
end

--- ---------------------------------------------------------------------------
--- Mason bin path
--- ---------------------------------------------------------------------------

--- Prepend `<data>/mason/bin` to `PATH` when Mason is installed.
--- Mason is optional: nothing happens when the directory is absent.
--- @return boolean changed
function M.setup_mason_path()
    if opts.use_mason_bin == false then
        return false
    end
    local bin = fs.data_path("mason", "bin")
    if not fs.is_dir(bin) then
        return false
    end
    local path = vim.env.PATH or ""
    if path:find(vim.pesc(bin), 1, true) then
        return false
    end
    vim.env.PATH = bin .. ":" .. path
    return true
end

--- @return string|nil mason_bin
function M.mason_bin()
    local bin = fs.data_path("mason", "bin")
    return fs.is_dir(bin) and bin or nil
end

--- ---------------------------------------------------------------------------
--- Command hints (data-driven registry)
--- ---------------------------------------------------------------------------

--- Register hints for a server.
--- Hint for one command. Only `description` is needed; `params` makes the hint
--- a *guard*, because LSP itself exposes command names without any parameter
--- metadata (no schema, no required/optional information).
--- @class core.lsp.CommandHint
--- @field description? string
--- @field params? { name: string, type?: string, required?: boolean, description?: string }[] positional arguments
--- @field required? integer[] shorthand for required positional indices
--- @field schema? any free-form schema shown to the user
--- @field example? string JSON example used as the input default
--- @field docs? string where the information comes from (URL, `:help` tag, ...)

--- @return string
function M.log_path()
    local ok, path = pcall(vim.lsp.log.get_filename)
    return ok and path or fs.state_path("lsp.log")
end

--- `:LspLog` -- open the official Neovim LSP log (tail).
function M.open_log()
    local path = M.log_path()
    if not fs.is_file(path) then
        notify.info(("LSP log is empty (no LSP activity yet): %s"):format(path))
        return
    end
    local stat = vim.uv.fs_stat(path)
    if stat and stat.size == 0 then
        notify.info(("LSP log is empty: %s"):format(path))
        return
    end
    vim.cmd.edit({ args = { vim.fn.fnameescape(path) }, magic = { file = false } })
    vim.wo.wrap = false
    vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0), 0 })
    vim.cmd.normal({ args = { "G" }, bang = true })
    notify.info(("LSP log: %s (last line shown)"):format(path))
end

--- ---------------------------------------------------------------------------
--- File operations (Oil rename awareness)
--- ---------------------------------------------------------------------------

--- @class core.lsp.file_operations
M.file_operations = {}

--- Clients attached to a buffer (or all clients) that support file renames.
--- @param bufnr? integer
--- @return vim.lsp.Client[]
function M.file_operations.clients(bufnr)
    local list = bufnr and M.buffer_clients(bufnr) or M.clients()
    local out = {}
    for _, client in ipairs(list) do
        if client:supports_method("workspace/willRenameFiles") then
            out[#out + 1] = client
        end
    end
    return out
end

--- Notify supporting clients that files are about to be renamed and apply the
--- resulting workspace edits. Never raises: a failing LSP request must not make
--- a rename unreliable.
--- @param old_path string
--- @param new_path string
--- @param o? { timeout_ms?: integer }
--- @return boolean handled
--- @return string|nil err
function M.file_operations.will_rename(old_path, new_path, o)
    local timeout_ms = (o and o.timeout_ms) or 500
    local clients = M.file_operations.clients()
    if #clients == 0 then
        return false, "no client supports workspace/willRenameFiles"
    end
    local params = {
        files = { { oldUri = vim.uri_from_fname(old_path), newUri = vim.uri_from_fname(new_path) } },
    }
    local pending = 0
    for _, client in ipairs(clients) do
        pending = pending + 1
        local ok, err = pcall(function()
            client:request("workspace/willRenameFiles", params, function(req_err, result)
                pending = pending - 1
                if req_err then
                    notify.once(
                        ("lsp.willRename.%s"):format(client.name),
                        ("%s: willRenameFiles failed: %s"):format(
                            client.name,
                            notify.error_text(req_err)
                        ),
                        "WARN"
                    )
                    return
                end
                if result and next(result) then
                    local ok_edit, edit_err =
                        pcall(vim.lsp.util.apply_workspace_edit, result, client.offset_encoding)
                    if not ok_edit then
                        notify.once(
                            ("lsp.willRename.apply.%s"):format(client.name),
                            ("%s: cannot apply rename edits: %s"):format(
                                client.name,
                                tostring(edit_err)
                            ),
                            "WARN"
                        )
                    end
                end
            end, client.bufnr)
        end)
        if not ok then
            pending = pending - 1
            notify.once(
                ("lsp.willRename.request.%s"):format(client.name),
                ("%s: willRenameFiles request error: %s"):format(client.name, tostring(err)),
                "WARN"
            )
        end
    end

    -- Wait (bounded) so edits are applied before the filesystem operation. The
    -- wait is skipped inside fast events where blocking is not allowed.
    if pending > 0 and not vim.in_fast_event() then
        pcall(vim.wait, timeout_ms, function()
            return pending == 0
        end)
    end
    return true, nil
end

--- Tell supporting clients that files were renamed.
--- @param old_path string
--- @param new_path string
function M.file_operations.did_rename(old_path, new_path)
    local params = {
        files = { { oldUri = vim.uri_from_fname(old_path), newUri = vim.uri_from_fname(new_path) } },
    }
    for _, client in ipairs(M.clients()) do
        if client:supports_method("workspace/didRenameFiles") then
            pcall(client.notify, client, "workspace/didRenameFiles", params)
        end
    end
end

--- Capability-checked rename used for programmatic/plugin flows:
--- `workspace/willRenameFiles` (when supported) -> filesystem+neovim rename ->
--- `workspace/didRenameFiles` (when supported). Any LSP failure is reported but
--- never blocks the rename itself.
--- @param old_path string
--- @param new_path string
--- @param o? { overwrite?: boolean, ignoreIfExists?: boolean, notify?: boolean, timeout_ms?: integer }
--- @return boolean ok
--- @return string|nil err
function M.file_operations.rename(old_path, new_path, o)
    o = o or {}
    local handled, reason =
        M.file_operations.will_rename(old_path, new_path, { timeout_ms = o.timeout_ms })
    if not handled then
        notify.debug(("file operations: %s"):format(tostring(reason)))
    end
    local ok, err = pcall(vim.lsp.util.rename, old_path, new_path, {
        overwrite = o.overwrite,
        ignoreIfExists = o.ignoreIfExists,
    })
    if not ok then
        return false, tostring(err)
    end
    M.file_operations.did_rename(old_path, new_path)
    if o.notify ~= false then
        notify.info(
            ("renamed %s -> %s%s"):format(
                vim.fn.fnamemodify(old_path, ":t"),
                vim.fn.fnamemodify(new_path, ":t"),
                handled and " (LSP edits applied)" or ""
            )
        )
    end
    return true, nil
end

--- ---------------------------------------------------------------------------
--- Inspector
--- ---------------------------------------------------------------------------

--- @return string[]
function M.info_lines()
    local lines = {}
    local clients = M.clients()
    lines[#lines + 1] = ("active clients     %d"):format(#clients)
    lines[#lines + 1] = ("mason bin          %s"):format(M.mason_bin() or "<not installed>")
    lines[#lines + 1] = ""
    for _, client in ipairs(clients) do
        local info = M.client_info(client)
        lines[#lines + 1] = ("%s (id %d, pid %s)"):format(
            info.name,
            info.id,
            tostring(info.pid or "?")
        )
        lines[#lines + 1] = ("  root            %s"):format(info.root_dir or "<none>")
        lines[#lines + 1] = ("  buffers         %s"):format(#info.attached_buffers)
        local caps = vim.iter(info.capabilities)
            :filter(function(_, ok)
                return ok
            end)
            :map(function(cap)
                return cap
            end)
            :totable()
        table.sort(caps)
        lines[#lines + 1] = ("  capabilities    %s"):format(
            #caps > 0 and table.concat(caps, ", ") or "none"
        )
        lines[#lines + 1] = ("  commands        %d"):format(info.command_count)
        local names, found = M.commands_for(client)
        local hinted = 0
        for _, entry in pairs(found) do
            if entry.description then
                hinted = hinted + 1
            end
        end
        lines[#lines + 1] = ("  command hints   %d/%d documented"):format(hinted, #names)
        if hinted < #names then
            lines[#lines + 1] =
                "                  (LSP has no parameter schemas; add hints via core.lsp.register_command_hints)"
        end
    end
    if #clients == 0 then
        lines[#lines + 1] = "(no clients -- open a file whose server is configured and installed)"
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("configured configs  %d"):format(#M.configs())
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("%-18s %-8s %-8s %s"):format("SERVER", "ENABLED", "BINARY", "CMD")
    for _, server in ipairs(M.server_info()) do
        lines[#lines + 1] = ("%-18s %-8s %-8s %s"):format(
            server.name,
            server.enabled and "yes" or "no",
            server.available and "found" or "MISSING",
            server.cmd or "<dynamic>"
        )
    end
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("log file            %s"):format(M.log_path())
    return lines
end

--- `:LspInfo`
function M.cmd_info()
    report.open({
        title = "LSP",
        name = "core://lsp",
        lines = function()
            return M.info_lines()
        end,
    })
end

--- ---------------------------------------------------------------------------
--- `:LspExec` (implementation: `lua/core/lsp/exec.lua`)
--- ---------------------------------------------------------------------------

--- @param server string
--- @param map table<string, core.lsp.CommandHint>
function M.register_command_hints(server, map)
    return exec.register_command_hints(server, map)
end

--- @param server string
--- @return table<string, table>
function M.command_hints(server)
    return exec.command_hints(server)
end

--- @param server string
--- @param command string
--- @return table|nil
function M.command_hint(server, command)
    return exec.command_hint(server, command)
end

--- @param server string
--- @param command string
--- @return string? text
function M.hint_text(server, command)
    return exec.hint_text(server, command)
end

--- @param server string
--- @param command string
--- @return string
function M.no_hint_text(server, command)
    return exec.no_hint_text(server, command)
end

--- @param hint table?
--- @param args table
--- @return boolean ok
--- @return string? err
function M.validate_args(hint, args)
    return exec.validate_args(hint, args)
end

--- @param spec table
function M.register_command(spec)
    return exec.register_command(spec)
end

--- @param client table
--- @return string[] names
--- @return table<string, table> found
function M.commands_for(client)
    return exec.commands_for(client)
end

--- @param name string
--- @return table|nil
function M.find_client(name)
    return exec.find_client(name)
end

--- @param spec table
--- @return boolean ok
--- @return string|nil err
function M.exec(spec)
    return exec.exec(spec)
end

--- @param spec table
--- @return boolean ok
--- @return string|nil err
function M.exec_json(spec)
    return exec.exec_json(spec)
end

function M.exec_interactive()
    return exec.exec_interactive()
end

--- @param args vim.api.keyset.create_user_command.command_args
function M.cmd_exec(args)
    return exec.cmd_exec(args)
end

--- ---------------------------------------------------------------------------
--- Setup
--- ---------------------------------------------------------------------------

--- Icons per severity for the sign column, the statusline, the virtual text and
--- the float. Values come from `defaults.diagnostics.signs` (Nerd Font glyphs by
--- default); the documented `E`/`W`/`I`/`H` letters are the fallback.
--- @return table<integer, string> by_severity bare glyphs (sign column)
--- @return table<string, string> by_name values as written (trailing space kept)
function M.diagnostic_icons()
    local o = defaults.get("diagnostics", {})
    local settings = o.signs or {}
    local severity = vim.diagnostic.severity
    local fallback = { ERROR = "E", WARN = "W", INFO = "I", HINT = "H" }

    --- Configured value for one level, or nil when icons are off / not configured.
    --- @param name string upper-case level name
    --- @return string? value
    local function configured(name)
        if o.icons == false then
            return nil
        end
        local value = settings[name:lower()]
        if type(value) ~= "string" or vim.trim(value) == "" then
            return nil
        end
        return value
    end

    --- Sign column: bare glyph (a trailing space would widen the column).
    --- @param name string
    --- @return string
    local function sign(name)
        local value = configured(name)
        if value then
            return vim.trim(value)
        end
        return fallback[name]
    end

    --- Statusline / virtual text: as written, so the trailing space separates.
    --- @param name string
    --- @return string
    local function decorated(name)
        return configured(name) or fallback[name]
    end

    local by_name = {
        ERROR = decorated("ERROR"),
        WARN = decorated("WARN"),
        INFO = decorated("INFO"),
        HINT = decorated("HINT"),
    }
    local by_severity = {
        [severity.ERROR] = sign("ERROR"),
        [severity.WARN] = sign("WARN"),
        [severity.INFO] = sign("INFO"),
        [severity.HINT] = sign("HINT"),
    }
    return by_severity, by_name
end

--- Apply the diagnostics configuration (all fields are documented in
--- `:help vim.diagnostic.Opts`).
--- @param o table
function M.setup_diagnostics(o)
    local by_severity = M.diagnostic_icons()
    local severity = vim.diagnostic.severity

    --- Highlight group for one severity (documented `Diagnostic*` groups).
    --- @param sev integer
    --- @return string
    local function hl_of(sev)
        local map = {
            [severity.ERROR] = "DiagnosticError",
            [severity.WARN] = "DiagnosticWarn",
            [severity.INFO] = "DiagnosticInfo",
            [severity.HINT] = "DiagnosticHint",
        }
        return map[sev] or "DiagnosticInfo"
    end

    --- `prefix`/`header` accept `(text, hl_group)`: icon in its severity colour.
    --- @param diag table `vim.Diagnostic`
    --- @return string text
    --- @return string hl
    local function icon_of(diag)
        return by_severity[diag.severity] or "●", hl_of(diag.severity)
    end

    local icons = o.icons ~= false

    -- Every optional handler is built with an explicit branch: `cond and X or Y`
    -- silently ignores `false`/`nil` for X, which made `virtual_text = false` and
    -- `float = false` impossible to express.
    local signs = { text = {} }
    if icons then
        signs = { text = by_severity, priority = 20 }
    end

    --- @type boolean|table
    local virtual_text = false
    if o.virtual_text ~= false then
        virtual_text = {
            spacing = 4,
            --- Show the source only when more than one namespace reports.
            source = "if_many",
            prefix = icons and icon_of or "■",
        }
    end

    --- @type boolean|table
    local float = false
    if o.float ~= false then
        float = {
            border = vim.o.winborder,
            source = true,
            --- Title bar of the float: icon + label, overridable with `o.header`.
            header = icons
                    and {
                        " " .. (by_severity[severity.ERROR] or "") .. " diagnostics ",
                        "DiagnosticInfo",
                    }
                or "diagnostics",
            prefix = icons and icon_of or "",
            --- All diagnostics on the line, not just under the cursor.
            scope = "line",
            focusable = false,
            style = "minimal",
            severity_sort = true,
        }
    end

    -- `virtual_lines` (documented example) replaces the inline text with one line
    -- per diagnostic, only for the current line.
    --- @type boolean|table
    local virtual_lines = false
    if o.virtual_lines == true then
        virtual_lines = { current_line = true }
        virtual_text = false
    end

    vim.diagnostic.config({
        severity_sort = o.severity_sort ~= false,
        update_in_insert = o.update_in_insert == true,
        underline = true,
        signs = signs,
        virtual_text = virtual_text,
        virtual_lines = virtual_lines,
        float = float,
        --- `vim.diagnostic.jump()` (and `]d`/`[d`): wrap around and echo the message
        --- in its severity colour, so jumping tells you what you landed on.
        jump = {
            wrap = true,
            on_jump = function(diag)
                if not diag then
                    return
                end
                local text, hl = by_severity[diag.severity] or "", hl_of(diag.severity)
                vim.api.nvim_echo({ { ("%s %s"):format(text, diag.message), hl } }, false, {})
            end,
        },
    })
end

function M.setup(o)
    opts = o or defaults.get("lsp", {})
    M.setup_diagnostics(opts.diagnostics or defaults.get("diagnostics", {}))
    -- The `:LspExec` half owns the hint/command registries' behaviour; they are
    -- passed by reference so both halves see the same data.
    exec.setup({ hints = hints, commands = commands })
    M.setup_mason_path()
end

--- Enable the servers that were registered through `register_server()`.
--- Called by the plugin/LSP configuration after declaring servers.
return M
