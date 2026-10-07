--- t07: LSP helpers, `:LspExec` JSON validation, file-operation fallback, and
--- the "restart recommended" notification after a plugin update.
local T = dofile(vim.fs.joinpath(vim.fn.stdpath("config"), "tests", "helpers.lua"))

local lsp = require("core.lsp")

-- No client attached: every helper must degrade instead of raising.
T.equal(lsp.buffer_clients(0), {}, "no clients attached in a headless session")
T.equal(
    select(1, lsp.supports(0, "textDocument/formatting")),
    false,
    "capability check without clients is false"
)
T.check(type(lsp.server_info()) == "table", "server info is inspectable")
T.check(#lsp.configs() >= 0, "registered configs are enumerable")

-- Server registration is declarative and reports availability.
local ok_reg, reg_err = lsp.register_server("core-test-server", {
    cmd = { "definitely-not-installed-binary" },
    filetypes = { "lua" },
    root_markers = { ".git" },
})
T.check(ok_reg, "server registration works: " .. tostring(reg_err))
local info
for _, server in ipairs(lsp.server_info()) do
    if server.name == "core-test-server" then
        info = server
    end
end
T.check(info ~= nil, "registered server appears in server_info()")
T.equal(info.available, false, "missing executable is reported as unavailable")

-- Servers declared in configuration (`defaults.lsp.servers`) extend the
-- built-in list without editing plugins/lsp.lua.
require("core.defaults").values.lsp.servers = {
    core_declared_server = { cmd = { "definitely-not-installed-binary" }, filetypes = { "lua" } },
}
require("plugins.lsp").setup()
local declared_found = false
for _, server in ipairs(lsp.server_info()) do
    if server.name == "core_declared_server" then
        declared_found = true
    end
end
T.check(declared_found, "server declared through defaults.lsp.servers is registered")

-- Command hints are a registry: core, user and plugins can extend it.
local ok_hints = lsp.register_command_hints("core-test-server", {
    ["core.testCommand"] = { description = "test command", example = '["a"]' },
})
T.check(ok_hints, "command hints registered")
T.equal(
    lsp.command_hint("core-test-server", "core.testCommand").example,
    '["a"]',
    "hint lookup works"
)
T.check(next(lsp.command_hints("core-test-server")) ~= nil, "hints are enumerable per server")

-- ---------------------------------------------------------------------------
-- Command hints: display + required-argument guard
-- ---------------------------------------------------------------------------

-- A hint for a command is rendered as text (description/params/example/source).
local ok_hint = lsp.register_command_hints("core-test-server", {
    ["core.paramCommand"] = {
        description = "command with arguments",
        params = {
            {
                name = "Targets",
                type = "string[]",
                required = true,
                description = "what to act on",
            },
            { name = "Options", type = "table", description = "optional flags" },
        },
        example = '[["a"]]',
        docs = "https://example.com/docs",
    },
})
T.check(ok_hint, "hint with params registered")
local hint_text =
    assert(lsp.hint_text("core-test-server", "core.paramCommand"), "hint text is produced")
T.check(
    hint_text:find("command with arguments", 1, true) ~= nil,
    "hint text contains the description"
)
T.check(
    hint_text:find("arg 1: Targets", 1, true) ~= nil,
    "hint text lists the positional arguments"
)
T.check(hint_text:find("required", 1, true) ~= nil, "hint text marks required arguments")
T.check(hint_text:find("example", 1, true) ~= nil, "hint text shows the example")
T.check(hint_text:find("example.com", 1, true) ~= nil, "hint text cites its source")
T.equal(
    lsp.hint_text("core-test-server", "core.unknownCommand"),
    nil,
    "unknown command has no hint text"
)
T.check(
    lsp.no_hint_text("core-test-server", "core.unknownCommand"):find("no parameter schema", 1, true)
        ~= nil,
    "the fallback explains that LSP exposes no parameter schema"
)

-- Argument validation is a *guard*: required arguments are checked before the
-- command runs at all.
local ran = false
local ok_named = lsp.register_command({
    id = "core.param",
    server = "core-test-server",
    command = "core.paramCommand",
    description = "client-side command with declared arguments",
    args = { "Targets" },
    run = function()
        ran = true
    end,
})
T.check(ok_named, "named command with a runner registered")

local ok_missing, err_missing = lsp.exec_json({
    server = "core-test-server",
    command = "core.paramCommand",
    json = "[]",
})
T.equal(ok_missing, false, "missing required argument is rejected")
T.check(
    tostring(err_missing):find("missing required argument #1", 1, true) ~= nil,
    "rejection names the missing argument: " .. tostring(err_missing)
)
T.equal(ran, false, "the command was not executed")

local ok_args, args_err =
    lsp.validate_args(lsp.command_hint("core-test-server", "core.paramCommand"), { "a", "b" })
T.equal(
    ok_args,
    true,
    "validation passes when required arguments are present: " .. tostring(args_err)
)
local ok_args2, args_err2 =
    lsp.validate_args(lsp.command_hint("core-test-server", "core.paramCommand"), {})
T.equal(ok_args2, false, "validation fails without required arguments: " .. tostring(args_err2))

-- The command list carries the hint's description and declared arguments.
local fake_client = {
    id = 1,
    name = "core-test-server",
    server_capabilities = {},
    commands = {},
    attached_buffers = {},
}
local names, found = lsp.commands_for(fake_client)
T.check(
    vim.tbl_contains(names, "core.paramCommand"),
    "declared commands appear in the command list"
)
T.check(found["core.paramCommand"].description ~= nil, "command list carries the hint description")

-- JSON validation: malformed input is rejected *before* anything runs.
local messages = T.capture_notifications()
local ok_bad, err_bad =
    lsp.exec_json({ server = "core-test-server", command = "core.testCommand", json = "{not json" })
T.equal(ok_bad, false, "malformed JSON is rejected")
T.check(
    tostring(err_bad):find("invalid JSON", 1, true) ~= nil,
    "rejection explains the parse error: " .. tostring(err_bad)
)
local bad_text = assert(err_bad, "malformed JSON is rejected with a message")
T.check(
    bad_text:find("array", 1, true) ~= nil or bad_text:find("JSON", 1, true) ~= nil,
    "rejection mentions the expected shape"
)

local ok_obj, err_obj = lsp.exec_json({
    server = "core-test-server",
    command = "core.testCommand",
    json = '{"not":"an array"}',
})
T.equal(ok_obj, false, "JSON object is rejected where an array is required")
T.check(tostring(err_obj):find("array", 1, true) ~= nil, "array requirement is explained")

-- Unknown server / command produce clear failures, not tracebacks.
local ok_unknown = lsp.exec_json({ server = "no-such-server", command = "x", json = "[]" })
T.equal(ok_unknown, false, "unknown server is rejected")

-- `:LspExec` with a non-interactive form must not raise.
T.check(
    pcall(vim.cmd, "LspExec no-such-server some.command []") ~= false,
    ":LspExec reports instead of raising"
)
T.flush_notifications()
T.check(
    T.notified(messages, "no active LSP client") or T.notified(messages, "unknown"),
    ":LspExec reported the problem"
)

-- `:LspInfo` and `:LspLog` are usable without any LSP activity.
T.check(pcall(vim.cmd, "LspInfo"), ":LspInfo runs")
T.check(vim.fn.bufnr("core://lsp") ~= -1, ":LspInfo opens its inspector buffer")
T.check(pcall(vim.cmd, "LspLog"), ":LspLog runs")

-- File operations: capability-checked, and never in the way of a plain rename.
T.equal(lsp.file_operations.clients(), {}, "no client supports file renames here")
local dir = T.tmpdir("lsp-rename")
local old_path = vim.fs.joinpath(dir, "old.lua")
local new_path = vim.fs.joinpath(dir, "new.lua")
T.write(old_path, { "return 1" })
local ok_rename, rename_err = lsp.file_operations.rename(old_path, new_path, { notify = false })
T.equal(ok_rename, true, "rename without LSP support still succeeds: " .. tostring(rename_err))
T.equal(vim.uv.fs_stat(old_path), nil, "old path is gone")
T.check(vim.uv.fs_stat(new_path) ~= nil, "new path exists")

-- `PackChanged` with kind = "update" produces the documented restart hint, and
-- no restart happens by default.
T.equal(
    require("core.defaults").get("reload.auto_restart", false),
    false,
    "auto_restart defaults to off (never restart silently)"
)
local update_messages = T.capture_notifications()
vim.api.nvim_exec_autocmds("PackChanged", {
    pattern = "/tmp/core-test-plugin",
    data = {
        active = true,
        kind = "update",
        spec = { name = "core-test-plugin", src = "file:///tmp/none" },
        path = "/tmp/core-test-plugin",
    },
})
vim.wait(900, function()
    return false
end, 20)
T.flush_notifications()
T.check(T.notified(update_messages, "core-test-plugin"), "update is reported")
T.check(T.notified(update_messages, ":restart"), "the notification tells the user to run :restart")
T.check(not T.notified(update_messages, "restarting Neovim"), "no automatic restart by default")

T.finish()
