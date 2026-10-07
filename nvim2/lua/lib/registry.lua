--- Generic ordered registry.
---
--- A registry is a dumb container: it stores declarative entries, keeps
--- insertion order, guards against duplicate ids and exposes read operations
--- plus change notifications. It deliberately holds no policy -- no module is
--- allowed to reach into the internal tables.
---
--- Used by: `core.toggle` (toggles), `core.root` (strategies, strategy kinds),
--- `core.format` (formatters), `core.lsp` (command hints, LSP commands),
--- `core.tools` (tools), `core.pack` (plugin specs).
---
--- Entry contract:
---   `entry.id`      (string, required) unique identifier
---   `entry.priority`(number, optional) higher first in `list()` (default 0)
---   any other keys are free-form and owned by the consumer.
---
--- @class lib.Registry
--- @field name string
--- @field _order string[]
--- @field _items table<string, table>
--- @field _listeners fun(event: "register"|"remove", id: string, entry: table)[]
local Registry = {}
Registry.__index = Registry

--- @param opts? { name?: string }
--- @return lib.Registry
function Registry.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Registry)
    self.name = opts.name or "registry"
    self._order = {} --- @type string[]
    self._items = {} --- @type table<string, table>
    self._listeners = {} --- @type fun(event: string, id: string, entry: table)[]
    return self
end

--- Subscribe to `register`/`remove` events. Returns an unsubscribe function.
--- @param fn fun(event: 'register'|'remove', id: string, entry: table)
--- @return fun()
function Registry:on_change(fn)
    table.insert(self._listeners, fn)
    return function()
        for i, f in ipairs(self._listeners) do
            if f == fn then
                table.remove(self._listeners, i)
                break
            end
        end
    end
end

--- @param id string
--- @return boolean
function Registry:has(id)
    return self._items[id] ~= nil
end

--- @param id string
--- @return table|nil
function Registry:get(id)
    return self._items[id]
end

--- Register a single entry.
--- @param entry table must contain a non-empty string `id`
--- @param opts? { replace?: boolean, silent?: boolean }
--- @return boolean ok
--- @return string? err
function Registry:register(entry, opts)
    opts = opts or {}
    if type(entry) ~= "table" then
        return false, ("%s: entry must be a table, got %s"):format(self.name, type(entry))
    end
    local id = entry.id
    if type(id) ~= "string" or id == "" then
        return false, ("%s: entry.id must be a non-empty string"):format(self.name)
    end
    if entry.priority ~= nil and type(entry.priority) ~= "number" then
        return false, ("%s: entry %q has non-numeric priority"):format(self.name, id)
    end
    if self._items[id] and not opts.replace then
        return false, ("%s: id %q is already registered"):format(self.name, id)
    end
    if not self._items[id] then
        self._order[#self._order + 1] = id
    end
    self._items[id] = entry
    if not opts.silent then
        for _, fn in ipairs(self._listeners) do
            fn("register", id, entry)
        end
    end
    return true
end

--- Register many entries. Stops at the first failure and reports it.
--- @param entries table[]
--- @param opts? { replace?: boolean }
--- @return boolean ok
--- @return string? err
function Registry:register_all(entries, opts)
    for _, entry in ipairs(entries or {}) do
        local ok, err = self:register(entry, opts)
        if not ok then
            return false, err
        end
    end
    return true
end

--- @param id string
--- @return boolean removed
function Registry:remove(id)
    if not self._items[id] then
        return false
    end
    local entry = self._items[id]
    self._items[id] = nil
    for i, v in ipairs(self._order) do
        if v == id then
            table.remove(self._order, i)
            break
        end
    end
    for _, fn in ipairs(self._listeners) do
        fn("remove", id, entry)
    end
    return true
end

function Registry:clear()
    for id in pairs(self._items) do
        self:remove(id)
    end
end

--- Entries ordered by priority (descending), insertion order within a priority.
--- The returned table is a new list; entries themselves are not copied.
--- @return table[]
function Registry:list()
    -- `ipairs()` avoids `vim.iter()`'s list/dict scan (documented cost note).
    local order = vim.iter(ipairs(self._order))
        :map(function(index, id)
            return { index = index, id = id, entry = self._items[id] }
        end)
        :totable()
    -- Explicit stable ordering: `table.sort` is not stable, so the insertion
    -- index is part of the comparison (documented "insertion order within a
    -- priority" would otherwise be a lie).
    table.sort(order, function(a, b)
        local pa = a.entry.priority or 0
        local pb = b.entry.priority or 0
        if pa == pb then
            return a.index < b.index
        end
        return pa > pb
    end)
    return vim.iter(order)
        :map(function(item)
            return item.entry
        end)
        :totable()
end

--- Ordered ids (same order as `list()`).
--- @return string[]
function Registry:ids()
    return vim.iter(self:list())
        :map(function(entry)
            return entry.id
        end)
        :totable()
end

--- @return integer
function Registry:count()
    return #self._order
end

--- Debugging view of the registry.
--- @return table
function Registry:inspect()
    return { name = self.name, count = self:count(), ids = self:ids() }
end

return Registry
