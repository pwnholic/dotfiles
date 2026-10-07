--- Process / executable helpers.
---
--- Synchronous calls use `vim.system(...):wait()`; callers that must not block
--- startup use `run_async`. Every function returns an explicit result instead of
--- throwing, so failures can be reported with context by the caller.
---
--- @class lib.process
local M = {}

local uv = vim.uv or vim.loop

--- Is `cmd` executable and where is it? (`vim.fn.executable` + `exepath`)
--- @param cmd string
--- @return string|nil path
function M.executable(cmd)
    if type(cmd) ~= "string" or cmd == "" then
        return nil
    end
    if vim.fn.executable(cmd) ~= 1 then
        return nil
    end
    return vim.fn.exepath(cmd)
end

--- @param cmd string
--- @return boolean
function M.have(cmd)
    return M.executable(cmd) ~= nil
end

--- Run a command and wait for it.
--- @param cmd string[]
--- @param opts? vim.SystemOpts
--- @return { code: integer, stdout: string, stderr: string }|nil result
--- @return string|nil err
function M.run(cmd, opts)
    if vim.in_fast_event() then
        -- `vim.system():wait()` blocks on `vim.wait()`, which Neovim forbids in a
        -- fast event context. Callers in libuv callbacks must use `run_async()`.
        return nil, ("cannot run %q synchronously from a fast event (use run_async)"):format(cmd[1])
    end
    opts = vim.tbl_extend("force", { text = true }, opts or {})
    local ok, proc = pcall(vim.system, cmd, opts)
    if not ok then
        return nil, ("cannot run %q: %s"):format(cmd[1], tostring(proc))
    end
    local res = proc:wait()
    if res.code ~= 0 then
        return {
            code = res.code,
            stdout = res.stdout or "",
            stderr = res.stderr or "",
        },
            nil
    end
    return { code = 0, stdout = res.stdout or "", stderr = res.stderr or "" }, nil
end

--- Run a command in the background. `cb` receives the same shape as `run`.
--- Returns a handle whose `:kill(signal)` can stop the process.
--- @param cmd string[]
--- @param opts? vim.SystemOpts
--- @param cb? fun(result: { code: integer, stdout: string, stderr: string })
--- @return vim.SystemObj|nil
function M.run_async(cmd, opts, cb)
    opts = vim.tbl_extend("force", { text = true }, opts or {})
    local ok, proc = pcall(vim.system, cmd, opts, function(res)
        if not cb then
            return
        end
        -- `vim.system` invokes `on_exit` in a fast event context; the callback is
        -- scheduled so it may use the normal API (and `run()`).
        vim.schedule(function()
            cb({ code = res.code, stdout = res.stdout or "", stderr = res.stderr or "" })
        end)
    end)
    if not ok then
        if cb then
            cb({ code = -1, stdout = "", stderr = tostring(proc) })
        end
        return nil
    end
    return proc
end

--- First line of `cmd --version`, trimmed. Never raises.
--- @param cmd string
--- @param args? string[]
--- @return string|nil version
function M.version(cmd, args)
    args = args or { "--version" }
    local path = M.executable(cmd)
    if not path then
        return nil
    end
    local res = M.run({ path, unpack(args) }, { timeout = 5000 })
    if not res then
        return nil
    end
    local text = res.stdout ~= "" and res.stdout or res.stderr
    local first = vim.split(text, "\n", { plain = true })[1]
    return first and vim.trim(first) or nil
end

--- Send `text` to a channel/terminal job (used by the terminal subsystem).
--- `chansend()` returns the number of bytes written (0 on failure), not a
--- boolean, so any positive number is a success.
--- @param chan integer
--- @param text string
--- @return boolean ok
function M.write(chan, text)
    local sent = vim.fn.chansend(chan, text)
    return type(sent) == "number" and sent > 0
end

--- ---------------------------------------------------------------------------
--- Process introspection (used by the terminal subsystem)
--- ---------------------------------------------------------------------------

--- Is a process alive?
--- @param pid integer
--- @return boolean
function M.is_running(pid)
    if type(pid) ~= "number" or pid <= 0 then
        return false
    end
    return uv.fs_stat(("/proc/%d"):format(pid)) ~= nil
end

--- Real working directory of a process (Linux `/proc`).
--- @param pid integer
--- @return string? cwd
--- @return string? source 'proc' when read from the kernel, nil otherwise
function M.cwd_of(pid)
    if vim.fn.has("linux") ~= 1 or type(pid) ~= "number" then
        return nil, nil
    end
    local path = uv.fs_realpath(("/proc/%d/cwd"):format(pid))
    if not path then
        return nil, nil
    end
    return path, "proc"
end

--- Read selected fields of `/proc/<pid>/stat`.
--- Returns nil when the platform does not expose it.
--- @param pid integer
--- @return { state: string, ppid: integer, pgrp: integer, tpgid: integer }|nil
function M.stat(pid)
    if vim.fn.has("linux") ~= 1 or type(pid) ~= "number" then
        return nil
    end
    local f = uv.fs_open(("/proc/%d/stat"):format(pid), "r", 438)
    if not f then
        return nil
    end
    -- procfs reports st_size == 0, so the content is read with an explicit
    -- length instead of `fstat().size`.
    local data = uv.fs_read(f, 4096, 0) or ""
    uv.fs_close(f)
    if data == "" then
        return nil
    end
    -- The comm field can contain spaces and parentheses: cut up to the last ')'.
    local rest = data:match("^%d+ %(.*%) (.*)$")
    if not rest then
        return nil
    end
    local f_ = vim.split(rest, " ", { plain = true })
    return {
        state = f_[1],
        ppid = tonumber(f_[2]),
        pgrp = tonumber(f_[3]),
        tpgid = tonumber(f_[6]),
    }
end

--- Is the process the foreground process group of its terminal?
---
--- `true`  -- the shell is at its prompt (safe to inject input)
--- `false` -- a foreground child owns the terminal (injecting would corrupt it)
--- `nil`   -- undeterminable on this platform/process
--- @param pid integer
--- @return boolean|nil
function M.foreground_idle(pid)
    local stat = M.stat(pid)
    if not stat or not stat.pgrp or not stat.tpgid then
        return nil
    end
    return stat.pgrp == stat.tpgid
end

return M
