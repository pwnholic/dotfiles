--- Project root detection engine.
---
--- Data-driven, ordered, cached and inspectable. The engine itself is only a
--- loop over registered strategies; every way of *finding* a root is a
--- strategy `kind`, and every concrete strategy is a registry entry. Adding a
--- new strategy (by user configuration or a plugin) never requires editing
--- this file:
---
---   require('core.root').register_strategy{ kind = 'marker', markers = { '.git' }, priority = 100 }
---   require('core.root').register_kind('taskfile', { run = function(ctx, def) ... end })
---
--- Configuration (see `vim.g.root_spec` / `defaults.root.spec`):
---
---   vim.g.root_spec = {
---     '.git',                                             -- marker shorthand
---     { kind = 'marker', markers = { 'go.mod' } },
---     { kind = 'lsp', priority = 80 },
---     function(ctx) return ctx.dir end,                    -- function shorthand
---   }
---
--- A strategy returns `(root_path, reason)`; the first one that returns a path
--- wins. `:Root` shows every strategy that was evaluated, including failures.
---
--- @class core.root
local M = {}

local Cache = require("lib.cache")
local Registry = require("lib.registry")
local defaults = require("core.defaults")
local lifecycle = require("lib.lifecycle")
local notify = require("core.notify")
local report = require("lib.report")

--- @type lib.Registry strategy kinds (mechanism)
local kinds = Registry.new({ name = "root.kinds" })
--- @type lib.Registry strategies (policy, extensible)
local strategies = Registry.new({ name = "root.strategies" })
--- @type lib.Cache buffer number -> resolution result
local cache = Cache.new({ name = "root" })
--- @type lib.Lifecycle
--- @type lib.Lifecycle?
local lc
--- @type fun(root: string|nil, previous: string|nil)[]
local listeners = {}
--- @type string|nil root of the last emitted context
local last_context_root = nil

--- ---------------------------------------------------------------------------
--- Context
--- ---------------------------------------------------------------------------

--- Describe the buffer context a strategy is evaluated against.
--- @param bufnr? integer
--- @return table
function M.context(bufnr)
    local buf = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
    local name = vim.api.nvim_buf_get_name(buf)
    local cwd = vim.uv.cwd() or vim.fn.getcwd()
    local dir, source = nil, "cwd"
    local scheme = name:match("^(%w[%w+.-]*)://")

    if name == "" then
        dir, source = cwd, "cwd"
    elseif scheme then
        if scheme == "oil" then
            -- `oil:///path/to/dir` -- the path is authoritative for the directory view
            local rest = name:match("^%w[%w+.-]*://(.*)$") or ""
            dir, source = rest, "oil"
        else
            -- Unknown scheme (term://, fugitive://, ...): fall back to cwd.
            dir, source = cwd, "scheme:" .. tostring(scheme)
        end
    else
        dir, source = vim.fs.dirname(name) or cwd, "file"
    end

    local real = dir and (vim.uv.fs_realpath(dir) or dir) or nil
    return {
        bufnr = buf,
        name = name,
        buftype = vim.bo[buf].buftype,
        filetype = vim.bo[buf].filetype,
        cwd = cwd,
        dir = real,
        dir_source = source,
        is_file = source == "file",
    }
end

--- ---------------------------------------------------------------------------
--- Strategy kinds
--- ---------------------------------------------------------------------------

--- Register a strategy kind (mechanism). `handler.run(ctx, def)` returns
--- `(root_path, reason, marker)` or `(nil, reason)`.
--- Strategy kind implementation (`run` returns root, reason, marker).
--- @class core.root.Kind
--- @field run fun(ctx: table, def: table): string|nil, string|nil, string|nil
--- @field doc? string

--- @param name string
--- @param handler core.root.Kind
--- @param opts? { replace?: boolean }
--- @return boolean ok
--- @return string? err
function M.register_kind(name, handler, opts)
    if type(handler) ~= "table" or type(handler.run) ~= "function" then
        return false, ("kind %q needs a { run = function }"):format(tostring(name))
    end
    -- Kinds are mechanism-level and re-declarable: re-registering an id means
    -- "override the implementation", so a repeated `setup()` (or a plugin
    -- replacing a built-in kind) cannot fail. Strategies keep the strict
    -- behaviour and take an explicit `replace` option instead.
    return kinds:register(
        { id = name, run = handler.run, doc = handler.doc },
        opts or { replace = true }
    )
end

--- @return string[]
function M.kinds()
    return kinds:ids()
end

local function register_builtin_kinds()
    local ok, err = M.register_kind("marker", {
        doc = "find the closest ancestor (or descendant) containing one of `markers`",
        run = function(ctx, def)
            local markers = def.markers or (def.marker and { def.marker }) or {}
            if #markers == 0 then
                return nil, "no markers configured"
            end
            local upward = def.find ~= "downward"
            for _, marker in ipairs(markers) do
                local paths = vim.fs.find(marker, {
                    upward = upward,
                    path = ctx.dir or ctx.cwd,
                    type = def.type,
                    stop = def.stop,
                    limit = 1,
                })
                if #paths > 0 then
                    local found = paths[1]
                    local root = vim.fs.dirname(found)
                    return root or found, ("matched %q"):format(marker), marker
                end
            end
            return nil,
                ("no %s found from %s (%s)"):format(
                    upward and "marker" or "marker",
                    ctx.dir or ctx.cwd,
                    table.concat(markers, ", ")
                )
        end,
    })
    if not ok then
        notify.error("core.root: " .. tostring(err))
    end

    M.register_kind("fn", {
        doc = "call a user function",
        run = function(ctx, def)
            if type(def.fn) ~= "function" then
                return nil, "no `fn` configured"
            end
            local res, reason, marker = def.fn(ctx)
            if type(res) == "table" then
                return res.root, res.reason or "function strategy", res.marker
            end
            return res, reason or "function strategy", marker
        end,
    })

    M.register_kind("cwd", {
        doc = "use the current working directory when the buffer is inside it",
        run = function(ctx)
            local cwd = ctx.cwd
            if not cwd or cwd == "" then
                return nil, "no cwd"
            end
            local dir = ctx.dir
            if not dir then
                return cwd, "cwd (no directory context)"
            end
            if dir == cwd or dir:sub(1, #cwd + 1) == cwd .. "/" then
                return cwd, "buffer is inside cwd"
            end
            return nil, ("buffer directory %s is outside cwd %s"):format(dir, cwd)
        end,
    })

    M.register_kind("dirname", {
        doc = "use the directory containing the buffer file (cwd for unnamed buffers)",
        run = function(ctx)
            if not ctx.dir then
                return ctx.cwd, "cwd (unnamed buffer)"
            end
            if ctx.is_file then
                return ctx.dir, "directory of the buffer file"
            end
            return ctx.dir, ("directory of %s"):format(ctx.dir_source)
        end,
    })

    M.register_kind("lsp", {
        doc = "use the root reported by an attached LSP client",
        run = function(ctx)
            local loaded, lsp = pcall(require, "core.lsp")
            if not loaded then
                return nil, "core.lsp is unavailable"
            end
            local clients = lsp.buffer_clients(ctx.bufnr)
            for _, client in ipairs(clients) do
                local root = client.root_dir
                if type(root) == "string" and root ~= "" then
                    return root, ("LSP client %s"):format(client.name or client.id)
                end
                local folders = client.workspace_folders
                local uri = folders and folders[1] and folders[1].uri
                if uri then
                    return vim.uri_to_fname(uri),
                        ("LSP workspace folder of %s"):format(client.name or client.id)
                end
            end
            return nil, ("no attached LSP client provides a root (%d attached)"):format(#clients)
        end,
    })
end

--- ---------------------------------------------------------------------------
--- Strategies
--- ---------------------------------------------------------------------------

--- @param entry any
--- @param index integer
--- @return table|nil def
--- @return string|nil err
local function normalize(entry, index)
    if type(entry) == "string" then
        return { id = "marker:" .. entry, kind = "marker", markers = { entry }, priority = 50 }
    end
    if type(entry) == "function" then
        return { id = ("fn:%d"):format(index), kind = "fn", fn = entry, priority = 50 }
    end
    if type(entry) ~= "table" then
        return nil,
            ("strategy %d: expected string, function or table, got %s"):format(index, type(entry))
    end
    local def = vim.deepcopy(entry)
    if not def.kind then
        if def.markers or def.marker then
            def.kind = "marker"
        elseif def.fn then
            def.kind = "fn"
        else
            return nil, ("strategy %d: missing `kind`"):format(index)
        end
    end
    def.id = def.id or ("strategy:%d"):format(index)
    return def
end

--- Register a strategy (policy). See `normalize()` for accepted shapes.
--- @param def table|string|function
--- @param opts? { replace?: boolean, priority?: number }
--- @return boolean ok
--- @return string? err
function M.register_strategy(def, opts)
    opts = opts or {}
    local normalized, err = normalize(def, 0)
    if not normalized then
        return false, err
    end
    if opts.priority then
        normalized.priority = opts.priority
    end
    if not kinds:has(normalized.kind) then
        return false, ("unknown strategy kind %q"):format(tostring(normalized.kind))
    end
    return strategies:register(normalized, { replace = opts.replace })
end

--- @return table[]
function M.list_strategies()
    return strategies:list()
end

--- ---------------------------------------------------------------------------
--- Resolution
--- ---------------------------------------------------------------------------

--- Resolve a buffer's root without using the cache.
--- @param bufnr? integer
--- @return table result `{ root, strategy, reason, marker, evaluated, ctx }`
function M.resolve(bufnr)
    local ctx = M.context(bufnr)
    local result = {
        ctx = ctx,
        root = nil,
        strategy = nil,
        reason = nil,
        marker = nil,
        evaluated = {},
        resolved_at = vim.uv.hrtime(),
    }

    for _, def in ipairs(strategies:list()) do
        local handler = kinds:get(def.kind)
        if not handler then
            result.evaluated[#result.evaluated + 1] =
                { id = def.id, kind = def.kind, ok = false, reason = "unknown kind" }
        else
            local ok, root, reason, marker = pcall(handler.run, ctx, def)
            if not ok then
                result.evaluated[#result.evaluated + 1] = {
                    id = def.id,
                    kind = def.kind,
                    ok = false,
                    reason = "error: " .. tostring(root),
                }
            elseif type(root) == "string" and root ~= "" then
                local normalized = vim.fs.normalize(root)
                result.evaluated[#result.evaluated + 1] = {
                    id = def.id,
                    kind = def.kind,
                    ok = true,
                    root = normalized,
                    reason = reason,
                    marker = marker,
                }
                result.root = normalized
                result.strategy = def.id
                result.reason = reason
                result.marker = marker
                break
            else
                result.evaluated[#result.evaluated + 1] = {
                    id = def.id,
                    kind = def.kind,
                    ok = false,
                    reason = reason or "no match",
                }
            end
        end
    end

    return result
end

--- Cached resolution detail for a buffer.
--- @param bufnr? integer
--- @return table
function M.detail(bufnr)
    local buf = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
    if not vim.api.nvim_buf_is_valid(buf) then
        return M.resolve(buf)
    end
    if not defaults.get("root.cache", true) then
        return M.resolve(buf)
    end
    local hit = cache:get(buf)
    if hit then
        hit.cache = { hit = true, age_ms = cache:age(buf) }
        return hit
    end
    local result = M.resolve(buf)
    result.cache = { hit = false }
    cache:set(buf, result)
    return result
end

--- Resolved project root for a buffer (cached).
--- @param bufnr? integer
--- @return string|nil root
function M.get(bufnr)
    local detail = M.detail(bufnr)
    return detail.root
end

--- Invalidate one buffer (or all buffers when `bufnr` is nil).
--- @param bufnr? integer
--- @return integer invalidated
function M.invalidate(bufnr)
    if bufnr == nil then
        return cache:clear()
    end
    local buf = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr
    return cache:invalidate(buf) and 1 or 0
end

--- Clear the whole cache and re-emit the context root.
function M.clear()
    local n = cache:clear()
    notify.info(("root cache cleared (%d entries)"):format(n))
    M.emit_context()
end

--- @return table
function M.cache_stats()
    return cache:stats()
end

--- ---------------------------------------------------------------------------
--- Context change listeners (terminal cwd sync, ...)
--- ---------------------------------------------------------------------------

--- Subscribe to "the project context of the current buffer changed".
--- @param fn fun(root: string|nil, previous: string|nil)
--- @return fun() unsubscribe
function M.on_context_change(fn)
    listeners[#listeners + 1] = fn
    return function()
        for i, f in ipairs(listeners) do
            if f == fn then
                table.remove(listeners, i)
                break
            end
        end
    end
end

--- Current project context: the resolved root of the current buffer, or cwd.
--- @return string
function M.context_root()
    local detail = M.detail(vim.api.nvim_get_current_buf())
    return detail.root or (vim.uv.cwd() or vim.fn.getcwd())
end

--- Recompute the current context and notify listeners when it changed.
function M.emit_context()
    local root = M.context_root()
    if root == last_context_root then
        return
    end
    local previous = last_context_root
    last_context_root = root
    for _, fn in ipairs(listeners) do
        local ok, err = pcall(fn, root, previous)
        if not ok then
            notify.once(
                "root.listener",
                ("root context listener failed: %s"):format(tostring(err)),
                "ERROR"
            )
        end
    end
end

--- ---------------------------------------------------------------------------
--- Setup / teardown
--- ---------------------------------------------------------------------------

--- Setup the engine.
--- @param opts? { spec?: table, cache?: boolean }
function M.setup(opts)
    opts = opts or defaults.get("root", {})

    -- A repeated setup() replaces this generation: drop stale listeners so the
    -- terminal context sync (or any other subscriber) cannot be registered twice.
    listeners = {}
    register_builtin_kinds()

    -- Strategy source of truth: `vim.g.root_spec` wins, then configuration.
    local spec = vim.g.root_spec
    if spec ~= nil and type(spec) ~= "table" then
        notify.warn("vim.g.root_spec must be a table; ignoring")
        spec = nil
    end
    spec = spec or opts.spec or defaults.get("root.default_spec", {})

    strategies:clear()
    local problems = {}
    for _, entry in ipairs(spec or {}) do
        local ok, err = M.register_strategy(entry)
        if not ok then
            problems[#problems + 1] = tostring(err)
        end
    end
    if #strategies:list() == 0 then
        problems[#problems + 1] = "no usable root strategy registered"
    end
    for _, problem in ipairs(problems) do
        notify.error("core.root: " .. problem)
    end

    lc = lifecycle.new({ name = "core.root" })
    lc:on_teardown(function()
        listeners = {}
        last_context_root = nil
    end)

    -- Cache invalidation: any change that can alter a root decision.
    local invalidate_all = function()
        cache:clear()
        M.emit_context()
    end
    local invalidate_buf = function(args)
        M.invalidate(args.buf)
        M.emit_context()
    end

    lc:autocmd("BufFilePost", { group_name = "root_invalidate", callback = invalidate_buf })
    lc:autocmd("BufWritePost", { group_name = "root_invalidate", callback = invalidate_all })
    lc:autocmd({ "BufDelete", "BufWipeout" }, {
        group_name = "root_cache_drop",
        callback = function(args)
            M.invalidate(args.buf)
        end,
    })
    lc:autocmd("DirChanged", {
        group_name = "root_context",
        callback = function()
            M.emit_context()
        end,
    })
    lc:autocmd({ "LspAttach", "LspDetach" }, {
        group_name = "root_context",
        desc = "core: LSP can change the resolved root",
        callback = function()
            cache:clear()
            M.emit_context()
        end,
    })
    lc:autocmd("BufEnter", {
        group_name = "root_context",
        desc = "core: project context may have changed",
        callback = function()
            M.emit_context()
        end,
    })
    lc:autocmd("User", {
        pattern = "ConfigReload",
        group_name = "root_context",
        callback = function()
            cache:clear()
            last_context_root = nil
            M.emit_context()
        end,
    })

    vim.schedule(function()
        last_context_root = nil
        M.emit_context()
    end)
    lc:activate()
end

--- Teardown autocommands and listeners (cache is kept: it is derived data).
function M.teardown()
    if lc then
        lc:teardown()
        lc = nil
    end
    listeners = {}
    last_context_root = nil
end

--- ---------------------------------------------------------------------------
--- Inspector
--- ---------------------------------------------------------------------------

--- @param bufnr? integer
--- @return string[]
function M.report_lines(bufnr)
    local detail = M.detail(bufnr)
    local ctx = detail.ctx
    local lines = {}
    local function add(s)
        lines[#lines + 1] = s
    end

    add(("Project root     %s"):format(detail.root or "<none>"))
    add(("Strategy         %s"):format(detail.strategy or "<none matched>"))
    add(("Reason           %s"):format(detail.reason or "-"))
    add(("Matched marker   %s"):format(detail.marker or "-"))
    if detail.cache then
        add(
            ("Cache            %s"):format(
                detail.cache.hit and ("hit (%s ms old)"):format(detail.cache.age_ms or 0)
                    or "miss (computed now)"
            )
        )
    end
    local stats = M.cache_stats()
    add(
        ("Cache stats      %d entries, %d hits, %d misses"):format(
            stats.size,
            stats.hits,
            stats.misses
        )
    )
    add("")
    add(("Buffer           %d (%s)"):format(ctx.bufnr, ctx.name ~= "" and ctx.name or "<unnamed>"))
    add(("Directory        %s  [%s]"):format(ctx.dir or "<none>", ctx.dir_source))
    add(("Cwd              %s"):format(ctx.cwd))
    add(("Buftype          %s"):format(ctx.buftype == "" and "<empty>" or ctx.buftype))
    add("")
    add("Strategies (in priority order):")
    for _, item in ipairs(detail.evaluated) do
        add(
            ("  %s %-14s %-9s %s"):format(
                item.ok and "[ok]" or "[--]",
                item.id,
                item.kind,
                item.ok and ("-> " .. tostring(item.root) .. "  (" .. tostring(item.reason) .. ")")
                    or tostring(item.reason)
            )
        )
    end
    local evaluated_ids = vim.iter(detail.evaluated)
        :map(function(item)
            return item.id
        end)
        :totable()
    local remaining = vim.iter(strategies:list())
        :map(function(def)
            return def.id
        end)
        :filter(function(id)
            return not vim.tbl_contains(evaluated_ids, id)
        end)
        :totable()
    if #remaining > 0 then
        add(("  (not evaluated: %s)"):format(table.concat(remaining, ", ")))
    end
    add("")
    add(("Registered kinds %s"):format(table.concat(M.kinds(), ", ")))
    add("Press q to close, R to re-resolve.")
    return lines
end

--- `:Root [bufnr]`
--- @param args vim.api.keyset.create_user_command.command_args
function M.cmd(args)
    local target = nil
    local first = args.fargs and args.fargs[1]
    if first and first ~= "" then
        target = tonumber(first)
        if not target then
            notify.error((":Root: expected a buffer number, got %q"):format(first))
            return
        end
        if not vim.api.nvim_buf_is_valid(target) then
            notify.error((":Root: buffer %d does not exist"):format(target))
            return
        end
    end
    M.invalidate(target)
    report.open({
        title = "Root inspection",
        filetype = "markdown",
        name = "core://root",
        lines = function()
            return M.report_lines(target)
        end,
        keymaps = {
            {
                lhs = "R",
                desc = "re-resolve root",
                rhs = function()
                    M.invalidate(target)
                    notify.info(("root: %s"):format(tostring(M.get(target))))
                end,
            },
            {
                lhs = "c",
                desc = "clear cache",
                rhs = function()
                    cache:clear()
                    notify.info("root cache cleared")
                end,
            },
        },
    })
end

return M
