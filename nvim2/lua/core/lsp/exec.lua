--- `:LspExec` surface: command metadata, argument validation and execution.
---
--- Split out of `core/lsp/init.lua`. LSP exposes command *names* only (no
--- parameter metadata), so the ctx.hints registry is the single source of truth for
--- parameter documentation *and* for the required-argument guard; both are
--- enforced here, before anything runs.
---
--- Seams: the two registries are owned by `core/lsp/init.lua` and injected through
--- `M.setup()` (they are passed by reference, so reads/writes stay in sync), while
--- the client lookup helpers are reached through a lazy `require("core.lsp")` to
--- keep the two files free of a load-order dependency.

local json = require("lib.json")
local notify = require("core.notify")

--- @class core.lsp.exec
--- @field setup fun(o: { hints: lib.Registry, commands: lib.Registry })
local M = {}

--- The registry/loader half of the module (lazy: avoids a require cycle).
--- @return table
local function lsp()
    return require("core.lsp")
end

--- Injected by `core.lsp.setup()` (real registries are owned by `core/lsp/init.lua`).
--- @type { hints: lib.Registry, commands: lib.Registry }
local ctx = {
    hints = require("lib.registry").new({ name = "lsp.command_hints.unbound" }),
    commands = require("lib.registry").new({ name = "lsp.commands.unbound" }),
}

--- @param o { hints: lib.Registry, commands: lib.Registry }
function M.setup(o)
    ctx = o or ctx
end

--- @param server string
--- @param map table<string, core.lsp.CommandHint>
--- @return boolean ok
--- @return string? err
function M.register_command_hints(server, map)
    if type(server) ~= "string" or server == "" then
        return false, "server name must be a non-empty string"
    end
    if type(map) ~= "table" then
        return false, "ctx.hints must be a table of { command = hint }"
    end
    for command, hint in pairs(map) do
        local ok, err = ctx.hints:register(
            vim.tbl_extend(
                "force",
                { id = server .. "::" .. command, server = server, command = command },
                hint or {}
            ),
            { replace = true }
        )
        if not ok then
            return false, err
        end
    end
    return true
end

--- @param server string
--- @return table<string, table>
function M.command_hints(server)
    local out = {}
    for _, hint in ipairs(ctx.hints:list()) do
        if hint.server == server then
            out[hint.command] = hint
        end
    end
    return out
end

--- Look up a hint. A `"*"` server entry acts as a global default.
--- @param server string
--- @param command string
--- @return table|nil
function M.command_hint(server, command)
    return ctx.hints:get(server .. "::" .. command) or ctx.hints:get("*::" .. command)
end

--- Human-readable hint text for a command (nil when nothing is registered).
--- @param server string
--- @param command string
--- @return string? text
function M.hint_text(server, command)
    local hint = M.command_hint(server, command)
    if not hint then
        return nil
    end

    local lines = {}
    local required = {}
    for _, index in ipairs(hint.required or {}) do
        required[index] = true
    end
    for index, param in ipairs(hint.params or {}) do
        local marks = {}
        if param.required or required[index] then
            marks[#marks + 1] = "required"
        end
        if param.type then
            marks[#marks + 1] = param.type
        end
        lines[#lines + 1] = ("  arg %d: %s%s"):format(
            index,
            param.name or "?",
            #marks > 0 and ("  [" .. table.concat(marks, ", ") .. "]") or ""
        )
        if param.description then
            lines[#lines + 1] = "         " .. param.description
        end
    end
    if hint.schema ~= nil then
        lines[#lines + 1] = ("  schema: %s"):format(
            type(hint.schema) == "table" and vim.inspect(hint.schema) or tostring(hint.schema)
        )
    end
    if hint.example then
        lines[#lines + 1] = ("  example: %s"):format(hint.example)
    end
    if hint.docs then
        lines[#lines + 1] = ("  source: %s"):format(hint.docs)
    end
    if hint.description then
        table.insert(lines, 1, "  " .. hint.description)
    end
    return #lines > 0 and table.concat(lines, "\n") or nil
end

--- Explain why a command has no parameter hint (LSP has no schema metadata).
--- @param server string
--- @param command string
--- @return string
function M.no_hint_text(server, command)
    return table.concat({
        ("LSP exposes no parameter schema for %s::%s."):format(server, command),
        "  Arguments are a JSON array and are forwarded as-is.",
        '  Add a hint with require("core.lsp").register_command_hints(server, { ... });',
        '  see :h core.lsp.CommandHint / README ("LSP command ctx.hints").',
    }, "\n")
end

--- Validate arguments against a hint's declared requirements.
--- @param hint table?
--- @param args table
--- @return boolean ok
--- @return string? err
function M.validate_args(hint, args)
    if not hint then
        return true, nil
    end
    local required = {}
    for _, index in ipairs(hint.required or {}) do
        required[index] = true
    end
    for index, param in ipairs(hint.params or {}) do
        if param.required then
            required[index] = true
        end
    end
    local indices = vim.tbl_keys(required)
    table.sort(indices)
    for _, index in ipairs(indices) do
        if args[index] == nil then
            local param = (hint.params or {})[index]
            return false,
                ("missing required argument #%d (%s): expected %s"):format(
                    index,
                    param and param.name or "?",
                    hint.example or "a JSON array"
                )
        end
    end
    return true, nil
end

--- ---------------------------------------------------------------------------
--- Named command definitions (user/plugin facing)
--- ---------------------------------------------------------------------------

--- @param spec { id: string, server?: string, command: string, description?: string, args?: table, run?: fun(client: vim.lsp.Client, args: table) }
--- @return boolean ok
--- @return string? err
function M.register_command(spec)
    if type(spec) ~= "table" or type(spec.command) ~= "string" then
        return false, "command definition needs { id, command }"
    end
    return ctx.commands:register(spec, { replace = true })
end

--- ---------------------------------------------------------------------------
--- Generic command execution
--- ---------------------------------------------------------------------------

--- All ctx.commands known for a client, with their source.
--- @param client vim.lsp.Client
--- @return string[] sorted names
--- @return table<string, { source: string, description?: string }>
function M.commands_for(client)
    local found = {}
    local provider = client.server_capabilities
        and client.server_capabilities.executeCommandProvider
    for _, name in ipairs(type(provider) == "table" and provider.commands or {}) do
        found[name] = { source = "server" }
    end
    for name in pairs(client.commands or {}) do
        found[name] = { source = "client" }
    end
    for name in pairs(vim.lsp.commands or {}) do
        found[name] = { source = "global-client" }
    end
    -- Named client-side ctx.commands declare their own arguments: surface them too.
    for _, def in ipairs(ctx.commands:list()) do
        if def.server == nil or def.server == client.name then
            found[def.command] = vim.tbl_extend("force", found[def.command] or {}, {
                source = (found[def.command] or {}).source or "client-named",
                description = def.description,
                args = def.args,
            })
        end
    end
    for name, hint in pairs(M.command_hints(client.name)) do
        found[name] = vim.tbl_extend("force", found[name] or {}, {
            source = (found[name] or {}).source or "hint",
            description = hint.description,
            example = hint.example,
        })
    end
    local names = vim.iter(found)
        :map(function(name)
            return name
        end)
        :totable()
    table.sort(names)
    return names, found
end

--- @param name string
--- @return vim.lsp.Client|nil
--- @return string|nil err
function M.find_client(name)
    local matches = {}
    for _, client in ipairs(lsp().clients()) do
        if client.name == name then
            matches[#matches + 1] = client
        end
    end
    if #matches == 0 then
        local names = {}
        for _, client in ipairs(lsp().clients()) do
            names[#names + 1] = client.name
        end
        return nil,
            ("no active LSP client named %q (active: %s)"):format(
                name,
                #names > 0 and table.concat(names, ", ") or "none"
            )
    end
    return matches[1], nil
end

--- Execute a command with arguments (already validated).
--- @param spec { server?: string, client?: vim.lsp.Client, command: string, arguments?: table, bufnr?: integer }
--- @return boolean ok
--- @return string|nil err
function M.exec(spec)
    if type(spec) ~= "table" or type(spec.command) ~= "string" or spec.command == "" then
        return false, "exec needs { command }"
    end
    local client = spec.client
    if not client and spec.server then
        local err
        client, err = M.find_client(spec.server)
        if not client then
            return false, err
        end
    end
    if not client then
        local attached = lsp().buffer_clients(spec.bufnr)
        if #attached == 0 then
            return false, "no LSP client attached to the current buffer; specify a server"
        end
        if #attached > 1 then
            local names = {}
            for _, c in ipairs(attached) do
                names[#names + 1] = c.name
            end
            return false,
                ("multiple LSP clients attached (%s); specify a server"):format(
                    table.concat(names, ", ")
                )
        end
        client = attached[1]
    end

    -- Named definition with a custom runner.
    for _, def in ipairs(ctx.commands:list()) do
        if
            def.command == spec.command
            and (not def.server or def.server == client.name)
            and def.run
        then
            local ok, err = pcall(def.run, client, spec.arguments or {})
            if not ok then
                return false, tostring(err)
            end
            return true, nil
        end
    end

    local arguments = spec.arguments or {}
    local ok, err = pcall(function()
        client:exec_cmd({ command = spec.command, arguments = arguments }, { bufnr = spec.bufnr })
    end)
    if not ok then
        return false, ("%s: %s"):format(spec.command, notify.error_text(err))
    end
    return true, nil
end

--- Execute a command from a JSON string. Malformed JSON is rejected before
--- anything is executed.
--- @param spec { server?: string, command: string, json?: string, bufnr?: integer }
--- @return boolean ok
--- @return string|nil err
function M.exec_json(spec)
    --- Every failure is reported here: this function backs `:LspExec`, and a
    --- command that silently does nothing is worse than a clear message.
    --- @param err string?
    --- @return boolean ok
    --- @return string err
    local function fail(err)
        err = err or "unknown error"
        notify.error(("LspExec: %s"):format(err))
        return false, err
    end

    if type(spec.command) ~= "string" or spec.command == "" then
        return fail("missing command")
    end
    local text = spec.json
    if text == nil or vim.trim(text) == "" then
        text = "[]"
    end
    local args, err = json.decode_list(text, { source = "arguments for " .. spec.command })
    if not args then
        return fail(err)
    end

    -- Hints are the only source of parameter metadata (LSP has none), and they do
    -- not need a running client: required arguments are validated first, so the
    -- user learns the requirement even before the server is up.
    local hint_server = spec.server
    if not hint_server then
        local attached = lsp().buffer_clients(spec.bufnr)
        hint_server = #attached == 1 and attached[1].name or nil
    end
    if hint_server then
        local ok_args, args_err = M.validate_args(M.command_hint(hint_server, spec.command), args)
        if not ok_args then
            return fail(args_err)
        end
    end

    local client = nil
    if spec.server then
        client, err = M.find_client(spec.server)
        if not client then
            return fail(err)
        end
    end
    local target = client
    if not target then
        local attached = lsp().buffer_clients(spec.bufnr)
        if #attached ~= 1 then
            return fail(("specify a server: %d clients attached"):format(#attached))
        end
        target = attached[1]
    end

    local _, found = M.commands_for(target)
    if not found[spec.command] then
        notify.warn(
            ("%s does not advertise command %q; forwarding anyway (client-side or server-side command)"):format(
                target.name,
                spec.command
            )
        )
    end

    local ok, exec_err = M.exec({
        client = target,
        command = spec.command,
        arguments = args,
        bufnr = spec.bufnr,
    })
    if not ok then
        notify.error(("LSP command %s failed: %s"):format(spec.command, tostring(exec_err)))
        return false, exec_err
    end
    notify.info(("executed %s on %s"):format(spec.command, target.name))
    return true, nil
end

--- Interactive `:LspExec` flow (native `vim.ui.select` / `vim.ui.input`).
function M.exec_interactive()
    local attached = lsp().buffer_clients(0)
    if #attached == 0 then
        notify.warn("no LSP client attached to the current buffer")
        return
    end
    local function with_client(client)
        local names, found = M.commands_for(client)
        if #names == 0 then
            notify.warn(("%s advertises no executable ctx.commands"):format(client.name))
            return
        end
        vim.ui.select(names, {
            prompt = ("command for %s"):format(client.name),
            format_item = function(name)
                local description = found[name] and found[name].description
                return description and ("%s - %s"):format(name, description) or name
            end,
        }, function(choice)
            if not choice then
                return
            end
            local hint = M.command_hint(client.name, choice)
            notify.info(
                ("%s\n%s"):format(
                    choice,
                    M.hint_text(client.name, choice) or M.no_hint_text(client.name, choice)
                )
            )
            vim.ui.input({
                prompt = ("JSON arguments for %s (array): "):format(choice),
                default = (hint and hint.example) or "[]",
            }, function(input)
                if input == nil then
                    return
                end
                M.exec_json({ server = client.name, command = choice, json = input })
            end)
        end)
    end

    if #attached == 1 then
        with_client(attached[1])
        return
    end
    vim.ui.select(attached, {
        prompt = "LSP client",
        format_item = function(client)
            return ("%s (%s)"):format(client.name, client.root_dir or "no root")
        end,
    }, function(choice)
        if choice then
            with_client(choice)
        end
    end)
end

--- `:LspExec [server] <command> [json]`
--- @param args vim.api.keyset.create_user_command.command_args
function M.cmd_exec(args)
    local raw = vim.trim(args.args or "")
    if raw == "" then
        M.exec_interactive()
        return
    end
    local first, rest = raw:match("^(%S+)%s*(.*)$")
    local command, json_text = rest:match("^(%S+)%s*(.*)$")
    if not command or command == "" then
        -- `:LspExec <command> [json]` -- infer the client from the buffer.
        command, json_text = first, rest
        first = nil
    end
    local server = first
    -- `:LspExec lua_ls lua.removeSpace '[...]'` -- allow quoting the JSON.
    if json_text then
        json_text = vim.trim(json_text)
        if
            (json_text:sub(1, 1) == "'" and json_text:sub(-1) == "'")
            or (json_text:sub(1, 1) == '"' and json_text:sub(-1) == '"')
        then
            json_text = json_text:sub(2, -2)
        end
    end
    if server then
        local hint = M.command_hint(server, command)
        if hint and (hint.params or hint.schema or hint.required) then
            notify.info(("%s\n%s"):format(command, M.hint_text(server, command)))
        end
    end
    M.exec_json({ server = server, command = command, json = json_text })
end

--- ---------------------------------------------------------------------------
--- Log
--- ---------------------------------------------------------------------------

return M
