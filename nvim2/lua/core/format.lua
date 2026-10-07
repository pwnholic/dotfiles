--- Formatting policy: gates, formatter registry and provider integration.
---
--- `core.format` owns the *policy* (when is formatting allowed), never the
--- formatting itself. A provider (registered by a plugin, e.g. Conform) does the
--- work through a tiny contract:
---
---   provider = {
---     name        = 'conform.nvim',
---     format      = fun(bufnr: integer, opts: table): boolean attempted, string? err,
---     formatters  = fun(bufnr: integer): { { name: string, available: boolean } }?,
---   }
---
--- Gate semantics (the four combinations from the specification):
---
---   global ON  + buffer ON  -> format
---   global ON  + buffer OFF -> skip
---   global OFF + buffer ON  -> skip
---   global OFF + buffer OFF -> skip
---
--- The global gate is runtime state (`vim.g.core_autoformat`), so it survives
--- `:ConfigReload`; the buffer gate is `vim.b[bufnr].core_autoformat` and is
--- genuinely buffer-local. `nil` means "inherit" for the buffer gate.
---
--- @class core.format
local M = {}

local Registry = require("lib.registry")
local defaults = require("core.defaults")
local lifecycle = require("lib.lifecycle")
local notify = require("core.notify")
local process = require("lib.process")
local report = require("lib.report")

--- @type lib.Registry formatter definitions (`{ id, cmd, args?, stdin?, notes? }`)
local formatters = Registry.new({ name = "formatters" })
--- @type table<string, string[]> filetype -> formatter ids
local filetype_map = {}
--- @type table|nil
local provider = nil
--- @type lib.Lifecycle
--- @type lib.Lifecycle?
local lc
--- @type table
local opts = {}

--- ---------------------------------------------------------------------------
--- Gates
--- ---------------------------------------------------------------------------

--- Global autoformat gate (runtime state).
--- @return boolean
function M.enabled()
    return vim.g.core_autoformat ~= false
end

--- @param value boolean
function M.set_enabled(value)
    vim.g.core_autoformat = value and true or false
end

--- Raw buffer gate (`nil` = inherit, `true`/`false` = explicit).
--- @param bufnr? integer
--- @return boolean|nil
function M.buffer_state(bufnr)
    local buf = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
    if not vim.api.nvim_buf_is_valid(buf) then
        return nil
    end
    return vim.b[buf].core_autoformat
end

--- Effective buffer gate: only an explicit `false` disables formatting.
--- @param bufnr? integer
--- @return boolean
function M.effective_buffer_enabled(bufnr)
    return M.buffer_state(bufnr) ~= false
end

--- @param bufnr? integer
--- @param value boolean
function M.set_buffer_enabled(bufnr, value)
    local buf = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end
    vim.b[buf].core_autoformat = value and true or false
end

--- Should `bufnr` be formatted? Returns the decision *and* the reason, so the
--- inspector can explain it without duplicating the rules.
--- @param bufnr? integer
--- @return boolean
--- @return string reason
function M.should_format(bufnr)
    local buf = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
    if not vim.api.nvim_buf_is_valid(buf) then
        return false, "invalid buffer"
    end
    if not M.enabled() then
        return false, "global autoformat is off (<leader>uf)"
    end
    local state = M.buffer_state(buf)
    if state == false then
        return false, "buffer autoformat is off (<leader>uF)"
    end
    local buftype = vim.bo[buf].buftype
    if buftype ~= "" then
        return false, ("buftype=%s buffers are never formatted"):format(buftype)
    end
    if vim.bo[buf].readonly then
        return false, "buffer is readonly"
    end
    if not provider then
        return false, "no formatter provider registered (is conform.nvim loaded?)"
    end
    return true, "both gates are on"
end

--- ---------------------------------------------------------------------------
--- Registries (extension points)
--- ---------------------------------------------------------------------------

--- Register a formatter definition. The provider decides how to use it; the
--- definition is primarily declarative metadata plus a command for health
--- checks and `:FormatInfo`.
--- @param spec { id: string, cmd: string, args?: string[], stdin?: boolean, notes?: string, filetypes?: string[] }
--- @return boolean ok
--- @return string? err
function M.register_formatter(spec)
    if type(spec) ~= "table" or type(spec.cmd) ~= "string" or spec.cmd == "" then
        return false, "formatter needs { id, cmd }"
    end
    local ok, err =
        formatters:register(vim.tbl_extend("force", { stdin = true }, spec), { replace = true })
    if not ok then
        return false, err
    end
    for _, ft in ipairs(spec.filetypes or {}) do
        M.set_filetype_formatters(ft, { spec.id })
    end
    return true
end

--- @return table[]
function M.list_formatters()
    return formatters:list()
end

--- Map a filetype to formatter ids (used by the provider integration).
--- @param ft string
--- @param ids string[]
--- @param o? { replace?: boolean }
function M.set_filetype_formatters(ft, ids, o)
    local existing = (o and o.replace) and {} or (filetype_map[ft] or {})
    vim.list_extend(
        existing,
        vim.iter(ids)
            :filter(function(id)
                return not vim.tbl_contains(existing, id)
            end)
            :totable()
    )
    filetype_map[ft] = existing
end

--- @param ft string
--- @return string[]
function M.formatters_for_filetype(ft)
    return vim.deepcopy(filetype_map[ft] or {})
end

--- @return table<string, string[]>
function M.filetype_map()
    return vim.deepcopy(filetype_map)
end

--- Formatting provider implemented by a plugin (e.g. conform.nvim).
--- @class core.format.Provider
--- @field name string
--- @field format fun(bufnr: integer, o: table): boolean, string|nil
--- @field formatters? fun(bufnr: integer): table[]|nil

--- Register the formatting provider (plugins call this).
--- @param p core.format.Provider
--- @return boolean ok
--- @return string? err
function M.set_provider(p)
    if type(p) ~= "table" or type(p.format) ~= "function" then
        return false, "provider needs { name, format = function }"
    end
    provider = p
    notify.debug(("format provider: %s"):format(p.name))
    return true
end

--- @return string|nil
function M.provider_name()
    return provider and provider.name or nil
end

--- ---------------------------------------------------------------------------
--- Formatting
--- ---------------------------------------------------------------------------

--- Format a buffer through the provider.
--- @param bufnr? integer
--- @param o? { reason?: string, range?: {start: integer[], end: integer[]}, notify?: boolean }
--- @return boolean ok
--- @return string reason
function M.format(bufnr, o)
    o = o or {}
    local buf = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
    if not provider then
        if o.notify ~= false then
            notify.once(
                "format.no_provider",
                "no formatter provider registered (is conform.nvim loaded?)",
                "WARN"
            )
        end
        return false, "no provider"
    end
    local ok, attempted, err = pcall(provider.format, buf, {
        timeout_ms = opts.timeout_ms or 1500,
        range = o.range,
        reason = o.reason or "manual",
    })
    if not ok then
        notify.once(
            "format.error:" .. tostring(buf),
            ("formatting failed: %s"):format(notify.error_text(attempted)),
            "ERROR"
        )
        return false, tostring(attempted)
    end
    if err then
        notify.once("format.err:" .. tostring(buf), ("formatting failed: %s"):format(err), "ERROR")
        return false, err
    end
    if attempted == false and o.notify ~= false and (o.reason or "manual") ~= "save" then
        notify.info("no formatter configured for this buffer")
        return false, "no formatter for buffer"
    end
    return true, "formatted"
end

--- `:Format` -- manual formatting of the current buffer.
---
--- Range handling follows `:command-range` semantics and Conform's range
--- contract (`{ start = {row, col}, end = {row, col} }`, 1-based rows, 0-based
--- columns, inclusive end row):
---
---   `:Format`        whole buffer
---   `:'<,'>Format`   selected lines (visual mode)
---   `:5Format`       line 5 (a count is the line, exactly like `:5delete`)
---   `:1,9Format`     lines 1-9
---
--- @param args vim.api.keyset.create_user_command.command_args
function M.cmd(args)
    local range, label
    if args.range == 2 then
        -- `end` is a Lua keyword, so the table keys are quoted for Conform's contract.
        range = { start = { args.line1, 0 }, ["end"] = { args.line2, 0 } }
        label = ("lines %d-%d"):format(args.line1, args.line2)
    elseif args.range == 1 then
        range = { start = { args.line1, 0 }, ["end"] = { args.line1, 0 } }
        label = ("line %d"):format(args.line1)
    else
        label = "buffer"
    end

    -- `M.format()` reports its own failures (throttled), so only success is
    -- reported here -- and it names the actual scope that was formatted.
    local ok = M.format(0, { reason = "manual", range = range })
    if ok then
        notify.info(("%s: formatted %s"):format(M.provider_name() or "format", label))
    end
end

--- ---------------------------------------------------------------------------
--- Inspector
--- ---------------------------------------------------------------------------
--- Inspector
--- ---------------------------------------------------------------------------
function M.info_lines()
    local buf = vim.api.nvim_get_current_buf()
    local decision, reason = M.should_format(buf)
    local lines = {
        ("buffer            %d (%s)"):format(buf, vim.api.nvim_buf_get_name(buf):gsub(".*/", "")),
        ("filetype          %s"):format(
            vim.bo[buf].filetype ~= "" and vim.bo[buf].filetype or "<none>"
        ),
        ("global gate       %s"):format(M.enabled() and "ON" or "OFF"),
        ("buffer gate       %s"):format(
            tostring(M.buffer_state(buf)) .. (M.buffer_state(buf) == nil and " (inherit)" or "")
        ),
        ("would format      %s (%s)"):format(decision and "yes" or "no", reason),
        ("provider          %s"):format(M.provider_name() or "<none>"),
        "",
    }

    local ft = vim.bo[buf].filetype
    lines[#lines + 1] = ("registered formatters for %s: %s"):format(
        ft ~= "" and ft or "<no filetype>",
        #M.formatters_for_filetype(ft) > 0 and table.concat(M.formatters_for_filetype(ft), ", ")
            or "(none)"
    )
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("%-20s %-10s %s"):format("FORMATTER", "AVAILABLE", "COMMAND")
    vim.list_extend(
        lines,
        vim.iter(formatters:list())
            :map(function(spec)
                local path = process.executable(spec.cmd)
                return ("%-20s %-10s %s"):format(
                    spec.id,
                    path and "yes" or "NO",
                    spec.cmd .. (spec.notes and ("  (" .. spec.notes .. ")") or "")
                )
            end)
            :totable()
    )

    if provider and provider.formatters then
        local ok, list = pcall(provider.formatters, buf)
        if ok and type(list) == "table" and #list > 0 then
            lines[#lines + 1] = ""
            lines[#lines + 1] = "provider formatters for this buffer:"
            for _, item in ipairs(list) do
                lines[#lines + 1] = ("  %-20s %s"):format(
                    item.name or "?",
                    item.available and "available" or "missing"
                )
            end
        end
    end
    return lines
end

--- `:FormatInfo`
function M.cmd_info()
    report.open({
        title = "Formatting",
        name = "core://format",
        lines = function()
            return M.info_lines()
        end,
    })
end

--- ---------------------------------------------------------------------------
--- Setup
--- ---------------------------------------------------------------------------

--- @param o? table
function M.setup(o)
    opts = o or defaults.get("format", {})
    -- setup() starts a new generation: the provider is registered afterwards by
    -- the plugin configuration that owns it.
    provider = nil
    lc = lifecycle.new({ name = "core.format" })

    -- Formatter metadata is core data: the registry is complete from startup, so
    -- health, `:FormatInfo` and the provider integration all read one source of
    -- truth regardless of whether a provider plugin has been loaded yet.
    formatters:clear()
    filetype_map = {}
    for _, spec in ipairs(opts.formatters or {}) do
        local ok, err = M.register_formatter(vim.deepcopy(spec))
        if not ok then
            notify.warn("core.format: " .. tostring(err))
        end
    end
    for ft, ids in pairs(opts.filetypes or {}) do
        M.set_filetype_formatters(ft, ids, { replace = true })
    end

    -- Runtime state wins over the configured default (see precedence docs), so
    -- the gate is only initialized when it has never been set.
    if vim.g.core_autoformat == nil then
        M.set_enabled(opts.autoformat ~= false)
    end

    if opts.on_save ~= false then
        lc:autocmd("BufWritePre", {
            group_name = "format_on_save",
            desc = "core: format on save (gated)",
            callback = function(args)
                local should, _ = M.should_format(args.buf)
                if should then
                    M.format(args.buf, { reason = "save", notify = true })
                end
            end,
        })
    end

    lc:activate()
end

function M.teardown()
    provider = nil
    if lc then
        lc:teardown()
        lc = nil
    end
end

return M
