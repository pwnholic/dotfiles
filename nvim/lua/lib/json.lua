--- JSON helpers with explicit, reportable failure.
---
--- `vim.json` raises on malformed input; these wrappers turn that into a
--- `(nil, message)` contract so callers can decide what to do instead of
--- accidentally propagating a raw error traceback to the user.
---
--- @class lib.json
local M = {}

--- @param value any
--- @return string|nil encoded
--- @return string|nil err
function M.encode(value)
    local ok, res = pcall(vim.json.encode, value)
    if not ok then
        return nil, ("cannot encode JSON: %s"):format(tostring(res))
    end
    return res
end

--- Decode a JSON string.
--- @param text string
--- @param opts? { source?: string } used in the error message
--- @return any|nil value
--- @return string|nil err
function M.decode(text, opts)
    opts = opts or {}
    local where = opts.source and (" in %s"):format(opts.source) or ""
    if type(text) ~= "string" then
        return nil, ("cannot decode JSON%s: expected string, got %s"):format(where, type(text))
    end
    local ok, res = pcall(vim.json.decode, text, { luanil = { object = false, array = false } })
    if not ok then
        local msg = tostring(res)
        -- Surface the parser position when the message contains it (LuaJIT/json).
        local line, col = msg:match("at line (%d+) column (%d+)")
        if line then
            msg = ("%s (line %s, column %s)"):format(msg:match("^[^%(]+") or msg, line, col)
        end
        return nil, ("invalid JSON%s: %s"):format(where, msg)
    end
    return res
end

--- Decode JSON that must be a JSON array (used for LSP command arguments).
--- @param text string
--- @param opts? { source?: string }
--- @return table|nil list
--- @return string|nil err
function M.decode_list(text, opts)
    local value, err = M.decode(text, opts)
    if err then
        return nil, err
    end
    if type(value) ~= "table" then
        return nil, ("JSON arguments must be an array, got %s"):format(type(value))
    end
    if vim.tbl_count(value) > 0 and not vim.islist(value) then
        return nil, "JSON arguments must be an array (got an object)"
    end
    return value, nil
end

--- Read and decode a JSON file. A missing file is not an error.
--- @param path string
--- @return any value (empty table when missing)
--- @return string|nil err
function M.read(path)
    local fd = vim.uv.fs_open(path, "r", 438)
    if not fd then
        return {}, nil
    end
    local stat = vim.uv.fs_fstat(fd)
    local data = stat and stat.size > 0 and vim.uv.fs_read(fd, stat.size, 0) or ""
    vim.uv.fs_close(fd)
    if data == "" then
        return {}, nil
    end
    return M.decode(data, { source = path })
end

--- Write a JSON file. The file is written to a temporary sibling and renamed,
--- so a crash cannot leave a half-written file behind.
--- @param path string
--- @param value any
--- @param opts? { pretty?: boolean }
--- @return boolean ok
--- @return string|nil err
function M.write(path, value, opts)
    local text, err = M.encode(value)
    if not text then
        return false, err
    end
    if opts and opts.pretty then
        text = text:gsub(",", ",\n")
    end
    -- The parent directory is created here so callers cannot silently lose
    -- state when it does not exist yet (e.g. `<state>/core/`).
    local dir = vim.fs.dirname(path)
    if dir and vim.uv.fs_stat(dir) == nil then
        vim.fn.mkdir(dir, "p")
    end
    local tmp = path .. ".tmp"
    local fd, ferr = vim.uv.fs_open(tmp, "w", 420)
    if not fd then
        return false, ("cannot open %s: %s"):format(tmp, tostring(ferr))
    end
    local wrote = vim.uv.fs_write(fd, text, 0)
    vim.uv.fs_close(fd)
    if not wrote then
        vim.uv.fs_unlink(tmp)
        return false, ("cannot write %s"):format(tmp)
    end
    local ok, rerr = vim.uv.fs_rename(tmp, path)
    if not ok then
        vim.uv.fs_unlink(tmp)
        return false, ("cannot rename %s -> %s: %s"):format(tmp, path, tostring(rerr))
    end
    return true
end

return M
