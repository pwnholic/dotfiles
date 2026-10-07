--- Generic keyed cache with optional TTL.
---
--- Mechanisms only: keys are opaque, values are opaque. Consumers own the
--- meaning of a key and the invalidation policy. Caches are intentionally
--- *inspectable* so a stale value can always be explained.
---
--- @class lib.Cache
--- @field name string
--- @field ttl number?
--- @field max number?
--- @field _data table<any, { value: any, stored: integer, hits: integer }>
--- @field _hits integer
--- @field _misses integer
--- @field _evictions integer
local Cache = {}
Cache.__index = Cache

--- @param opts? { name?: string, ttl?: number, max?: number }
--- @return lib.Cache
function Cache.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Cache)
    self.name = opts.name or "cache"
    self.ttl = opts.ttl -- milliseconds; nil = never expires
    self.max = opts.max
    self._data = {} --- @type table<any, { value: any, stored: integer, hits: integer }>
    self._hits = 0
    self._misses = 0
    self._evictions = 0
    return self
end

--- @param key any
--- @return any value or nil
function Cache:get(key)
    local item = self._data[key]
    if not item then
        self._misses = self._misses + 1
        return nil
    end
    if self.ttl and (vim.uv.hrtime() - item.stored) / 1e6 > self.ttl then
        self._data[key] = nil
        self._misses = self._misses + 1
        return nil
    end
    item.hits = item.hits + 1
    self._hits = self._hits + 1
    return item.value
end

--- @param key any
--- @param value any
--- @return any value
function Cache:set(key, value)
    if self.max and not self._data[key] and vim.tbl_count(self._data) >= self.max then
        -- Evict the oldest entry (cheap FIFO; keys are few in practice).
        local oldest_key, oldest_at
        for k, item in pairs(self._data) do
            if not oldest_at or item.stored < oldest_at then
                oldest_key, oldest_at = k, item.stored
            end
        end
        if oldest_key ~= nil then
            self._data[oldest_key] = nil
            self._evictions = self._evictions + 1
        end
    end
    self._data[key] = { value = value, stored = vim.uv.hrtime(), hits = 0 }
    return value
end

--- @param key any
--- @return boolean removed
function Cache:invalidate(key)
    if self._data[key] == nil then
        return false
    end
    self._data[key] = nil
    return true
end

--- @return integer removed
function Cache:clear()
    local n = vim.tbl_count(self._data)
    self._data = {}
    return n
end

--- @param key any
--- @return integer|nil # milliseconds since the value was stored
function Cache:age(key)
    local item = self._data[key]
    if not item then
        return nil
    end
    return math.floor((vim.uv.hrtime() - item.stored) / 1e6)
end

--- @return table
function Cache:stats()
    return {
        name = self.name,
        size = vim.tbl_count(self._data),
        hits = self._hits,
        misses = self._misses,
        evictions = self._evictions,
        ttl = self.ttl,
    }
end

return Cache
