--- Shared helpers for the headless test suite.
---
--- Run through `tests/run.sh`; each test file is executed in a fresh Neovim with
--- the real configuration loaded (`lua/core/user.lua` absent) and an isolated
--- state directory, so tests never touch the user's real state.
---
--- @class tests.helpers
local T = {}

local passed, failed = 0, 0
local failures = {}

--- @param cond any
--- @param msg string
function T.check(cond, msg)
    if cond then
        passed = passed + 1
    else
        failed = failed + 1
        failures[#failures + 1] = msg
        print("  FAIL: " .. msg)
    end
    return cond
end

--- @param actual any
--- @param expected any
--- @param msg string
function T.equal(actual, expected, msg)
    return T.check(
        vim.deep_equal(actual, expected),
        ("%s (expected %s, got %s)"):format(msg, vim.inspect(expected), vim.inspect(actual))
    )
end

--- Print the summary and exit with the right status.
function T.finish()
    print(("\nRESULT: %d passed, %d failed"):format(passed, failed))
    if failed > 0 then
        for _, msg in ipairs(failures) do
            print("  - " .. msg)
        end
        vim.cmd("cquit 1")
    end
    vim.cmd("qa!")
end

--- Capture notifications by installing a backend in `core.notify`.
--- @return string[] messages
function T.capture_notifications()
    local messages = {}
    require("core.notify").set_backend(function(msg)
        messages[#messages + 1] = tostring(msg)
    end)
    return messages
end

--- @param messages string[]
--- @param needle string
--- @return boolean
function T.notified(messages, needle)
    for _, msg in ipairs(messages) do
        if msg:find(needle, 1, true) then
            return true
        end
    end
    return false
end

--- Create (and clean) a temporary directory.
--- @param name string
--- @return string
function T.tmpdir(name)
    local dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "core-tests", name)
    vim.fn.delete(dir, "rf")
    vim.fn.mkdir(dir, "p")
    return vim.uv.fs_realpath(dir) or dir
end

--- Count active handles of a libuv type (watcher/timer leak detection).
--- @param kind string
--- @return integer
function T.count_handles(kind)
    local n = 0
    vim.uv.walk(function(handle)
        if handle:get_type() == kind and not handle:is_closing() then
            n = n + 1
        end
    end)
    return n
end

--- Number of autocommands in augroups owned by this configuration.
--- @return integer
function T.count_core_autocmds()
    local total = 0
    for _, name in ipairs(vim.fn.getcompletion("", "augroup")) do
        if name:sub(1, 5) == "core." then
            local ok, autocmds = pcall(vim.api.nvim_get_autocmds, { group = name })
            if ok then
                total = total + #autocmds
            end
        end
    end
    return total
end

--- Snapshot of the configuration's autocommands: one line per autocommand in
--- an owned augroup. Comparing snapshots detects duplicates *and* losses.
--- @return string[]
function T.autocmd_snapshot()
    local out = {}
    for _, name in ipairs(vim.fn.getcompletion("", "augroup")) do
        if name:sub(1, 5) == "core." then
            local ok, autocmds = pcall(vim.api.nvim_get_autocmds, { group = name })
            if ok then
                for _, au in ipairs(autocmds) do
                    out[#out + 1] = ("%s|%s|%s|%s"):format(
                        name,
                        au.event,
                        au.pattern or "*",
                        au.desc or ""
                    )
                end
            end
        end
    end
    table.sort(out)
    return out
end

--- All mappings per mode, as a sorted list of `mode lhs` strings.
--- @return string[]
function T.mapping_snapshot()
    local out = {}
    for _, mode in ipairs({ "n", "i", "v", "x", "o", "t", "c" }) do
        vim.list_extend(
            out,
            vim.iter(vim.api.nvim_get_keymap(mode))
                :map(function(map)
                    return ("%s %s"):format(mode, map.lhs)
                end)
                :totable()
        )
    end
    table.sort(out)
    return out
end

--- @return string[]
function T.command_snapshot()
    local names = vim.iter(vim.api.nvim_get_commands({}))
        :map(function(name)
            return name
        end)
        :totable()
    table.sort(names)
    return names
end

--- @param path string
--- @param lines string[]
function T.write(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile(lines, path)
end

--- @param ms integer
function T.wait(ms)
    vim.wait(ms, function()
        return false
    end, 10)
end

--- Flush scheduled work so deferred (error-level) notifications are captured.
function T.flush_notifications()
    vim.wait(80, function()
        return false
    end, 5)
end

--- Let deferred startup events (`VimEnter` -> `User VeryLazy`) settle so tests
--- observe the same state as an interactive session.
--- @param ms? integer
function T.flush_startup(ms)
    vim.wait(ms or 300, function()
        return false
    end, 10)
end

return T
