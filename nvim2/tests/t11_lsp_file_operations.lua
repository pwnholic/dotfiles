--- t11: `workspace/willRenameFiles` against a *capable* client.
---
--- No server on this machine advertises file operations, so the test starts a
--- minimal mock server (Python, JSON-RPC over stdio) that:
---   * answers `initialize` with `workspace.fileOperations.willRename`,
---   * records the request it receives in a marker file,
---   * replies with a `WorkspaceEdit`, so the *apply* path is exercised too.
---
--- That makes the assertion end to end: the request really goes over the wire and
--- the edit that comes back is applied by `core.lsp`.
local T = dofile(vim.fs.joinpath(vim.fn.stdpath("config"), "tests", "helpers.lua"))

local fs = require("lib.fs")
local lsp = require("core.lsp")
local process = require("lib.process")

local messages = T.capture_notifications()

local MOCK = [[import json
import sys

marker = sys.argv[1]


def read_message():
    header = b""
    while b"\r\n\r\n" not in header:
        chunk = sys.stdin.buffer.read(1)
        if not chunk:
            return None
        header += chunk
    length = 0
    for line in header.split(b"\r\n"):
        if line.lower().startswith(b"content-length:"):
            length = int(line.split(b":")[1])
    body = sys.stdin.buffer.read(length)
    if not body:
        return None
    return json.loads(body.decode("utf-8"))


def send(message):
    data = json.dumps(message).encode("utf-8")
    sys.stdout.buffer.write(b"Content-Length: " + str(len(data)).encode())
    sys.stdout.buffer.write(b"\r\n\r\n")
    sys.stdout.buffer.write(data)
    sys.stdout.buffer.flush()


while True:
    message = read_message()
    if message is None:
        break
    method = message.get("method")
    request_id = message.get("id")
    if method == "initialize":
        send(
            {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {
                    "capabilities": {
                        "textDocumentSync": 1,
                        "workspace": {
                            "fileOperations": {
                                "willRename": {"filters": [{"pattern": {"glob": "**/*"}}]}
                            }
                        },
                    },
                    "serverInfo": {"name": "mock-rename"},
                },
            }
        )
    elif method == "workspace/willRenameFiles":
        params = message.get("params") or {}
        with open(marker, "w") as handle:
            json.dump(params, handle)
        target = params["files"][0]["newUri"]
        send(
            {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": {
                    "changes": {
                        target: [
                            {
                                "range": {
                                    "start": {"line": 0, "character": 0},
                                    "end": {"line": 0, "character": 0},
                                },
                                "newText": "-- renamed via mock\n",
                            }
                        ]
                    }
                },
            }
        )
    elif method == "shutdown":
        send({"jsonrpc": "2.0", "id": request_id, "result": None})
    elif method == "exit":
        break
    elif request_id is not None:
        send({"jsonrpc": "2.0", "id": request_id, "result": None})
]]

if not process.have("python3") then
    T.info("python3 not available: skipping the willRenameFiles check")
    T.finish()
end

local dir = T.tmpdir("rename")
local marker = vim.fs.joinpath(dir, "marker.json")
local mock = vim.fs.joinpath(dir, "mock_lsp.py")
T.write(mock, vim.split(MOCK, "\n"))

local old_path = vim.fs.joinpath(dir, "old_name.lua")
local new_path = vim.fs.joinpath(dir, "new_name.lua")
T.write(old_path, { "return 1" })
T.write(new_path, { "return 1" })

-- Unsupported clients are skipped, as before.
local none_ok, none_err = lsp.file_operations.will_rename(old_path, new_path, { timeout_ms = 200 })
T.equal(none_ok, false, "without a capable client the operation reports false")
T.check(
    tostring(none_err):find("willRenameFiles", 1, true) ~= nil,
    "and explains why: " .. tostring(none_err)
)

local client_id = vim.lsp.start({
    name = "mock_rename",
    cmd = { "python3", mock, marker },
    root_dir = dir,
    capabilities = {},
})
T.check(client_id ~= nil, "mock client started")
local client = client_id and vim.lsp.get_client_by_id(client_id) or nil
T.check(client ~= nil, "mock client is reachable")
if client then
    local advertised = vim.wait(15000, function()
        return client:supports_method("workspace/willRenameFiles")
    end, 100)
    T.check(advertised, "mock advertises workspace/fileOperations/willRename")
    T.equal(client.name, "mock_rename", "client identity is the mock")

    local ok, err = lsp.file_operations.will_rename(old_path, new_path, { timeout_ms = 5000 })
    T.check(ok, "will_rename accepted with a capable client: " .. tostring(err))

    local arrived = vim.wait(10000, function()
        return vim.uv.fs_stat(marker) ~= nil
    end, 100)
    T.check(arrived, "the request reached the server")

    if arrived then
        local params = vim.json.decode(table.concat(vim.fn.readfile(marker), "\n"))
        local file = params.files and params.files[1] or {}
        T.check(
            tostring(file.oldUri):find("old_name.lua", 1, true) ~= nil,
            "request carries the old URI: " .. tostring(file.oldUri)
        )
        T.check(
            tostring(file.newUri):find("new_name.lua", 1, true) ~= nil,
            "request carries the new URI: " .. tostring(file.newUri)
        )
    end

    -- A workspace edit is applied to the *buffer* (Neovim does not write it to
    -- disk), so the assertion has to look there.
    local function buffer_lines(path)
        local bufnr = vim.fn.bufnr(path)
        if bufnr == -1 then
            return {}
        end
        return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    end
    local applied = vim.wait(5000, function()
        return table.concat(buffer_lines(new_path), "\n"):find("renamed via mock", 1, true) ~= nil
    end, 100)
    T.check(
        applied,
        "the returned workspace edit was applied to the buffer; notifications: "
            .. vim.inspect(vim.tbl_map(function(m)
                return m.msg
            end, messages))
    )
    T.check(vim.fn.bufnr(new_path) ~= -1, "the edited file was loaded as a buffer")
    T.equal(vim.bo[vim.fn.bufnr(new_path)].modified, true, "the buffer is marked as modified")

    pcall(function()
        client:stop(true)
    end)
end

T.check(fs.is_dir(dir), "temporary project directory cleaned up by the harness")
T.finish()
