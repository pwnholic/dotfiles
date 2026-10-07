--- Filesystem helpers built on `vim.fs` and `vim.uv`.
---
--- Only generic mechanisms live here; anything config-specific (which state
--- file is used for what, which directories are watched, ...) belongs to core.
---
--- @class lib.fs
local M = {}

local uv = vim.uv or vim.loop

--- @param path string
--- @return boolean
function M.is_dir(path)
    local stat = uv.fs_stat(path)
    return stat ~= nil and stat.type == "directory"
end

--- @param path string
--- @return boolean
function M.is_file(path)
    local stat = uv.fs_stat(path)
    return stat ~= nil and stat.type == "file"
end

--- @param ... string
--- @return string
function M.joinpath(...)
    return vim.fs.joinpath(...)
end

--- @param path string
--- @return string
function M.basename(path)
    return vim.fs.basename(path)
end

--- List directory entries (names only), sorted.
--- @param path string
--- @param opts? { dirs_only?: boolean, files_only?: boolean }
--- @return string[]
function M.list(path, opts)
    opts = opts or {}
    local iter = vim.fs.dir(path)
    if not iter then
        return {}
    end
    -- `map` drops `nil` results, so the predicate selects in a single stage.
    local names = vim.iter(iter)
        :map(function(name, kind)
            if opts.dirs_only and kind ~= "directory" then
                return nil
            end
            if opts.files_only and kind ~= "file" then
                return nil
            end
            return name
        end)
        :totable()
    table.sort(names)
    return names
end

--- Recursively collect subdirectories (absolute paths, sorted, excluding
--- symlinked directories to avoid loops). Used by the config watcher.
--- @class lib.fs.WalkOpts
--- @field ignore? fun(name: string, path: string): boolean
--- @field max? integer

--- @param root string
--- @param opts? lib.fs.WalkOpts
--- @return string[]
function M.walk_dirs(root, opts)
    opts = opts or {}
    local out = { root }
    local max = opts.max or 500
    local function walk(dir)
        if #out >= max then
            return
        end
        local iter = vim.fs.dir(dir)
        if not iter then
            return
        end
        for name, kind in iter do
            local path = vim.fs.joinpath(dir, name)
            local skip = opts.ignore and opts.ignore(name, path)
            if kind == "directory" and not skip then
                out[#out + 1] = path
                walk(path)
            end
        end
    end
    walk(root)
    return out
end

--- `stdpath()` sub-path helpers. Persistent metadata belongs in "state",
--- user-visible generated data in "data", rebuildable data in "cache".
--- @param ... string
--- @return string
function M.state_path(...)
    return vim.fs.joinpath(vim.fn.stdpath("state"), ...)
end

--- @param ... string
--- @return string
function M.config_path(...)
    return vim.fs.joinpath(vim.fn.stdpath("config"), ...)
end

--- @param ... string
--- @return string
function M.data_path(...)
    return vim.fs.joinpath(vim.fn.stdpath("data"), ...)
end

return M
