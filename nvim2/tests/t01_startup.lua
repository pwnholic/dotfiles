--- t01: startup, registries, lazy declarations, resource ownership.
local T = dofile(vim.fs.joinpath(vim.fn.stdpath("config"), "tests", "helpers.lua"))

local core = require("core")
T.equal(core.errors, {}, "startup has no subsystem errors")
T.check(core.state.setup_count >= 1, "core.setup ran")

-- Let deferred startup events (`VimEnter` -> `User VeryLazy`) settle, so the
-- assertions below describe the same state an interactive session reaches.
T.flush_startup()

-- Indentation is 4 by default for every filetype, except the toolchains that
-- mandate hard tabs.
for _, ft in ipairs({ "lua", "json", "yaml", "html", "css", "markdown", "sh", "python" }) do
    vim.cmd.enew()
    vim.bo.filetype = ft
    T.equal(vim.bo.shiftwidth, 4, ("%s: shiftwidth 4"):format(ft))
    T.equal(vim.bo.softtabstop, 4, ("%s: softtabstop 4"):format(ft))
    T.equal(vim.bo.tabstop, 4, ("%s: tabstop 4"):format(ft))
    T.equal(vim.bo.expandtab, true, ("%s: expandtab"):format(ft))
    vim.cmd.bwipeout({ bang = true })
end
for _, ft in ipairs({ "make", "go" }) do
    vim.cmd.enew()
    vim.bo.filetype = ft
    T.equal(vim.bo.expandtab, false, ("%s keeps hard tabs (toolchain)"):format(ft))
    vim.cmd.bwipeout({ bang = true })
end

-- Registries are populated and inspectable.
local root = require("core.root")
T.check(#root.list_strategies() >= 3, "root strategies registered")
T.check(vim.tbl_contains(root.kinds(), "marker"), "marker kind registered")
T.check(vim.tbl_contains(root.kinds(), "lsp"), "lsp kind registered")

-- Toggle order is the documented one: priority descending, then registration
-- order (stable), which is what makes `:Toggles` and the keymap family
-- predictable.
T.equal(require("core.toggle").ids(), {
    "diagnostics",
    "inlay_hints",
    "autoformat",
    "autoformat_buffer",
    "spell",
    "wrap",
    "relativenumber",
    "number",
    "cursorword",
    "treesitter_context",
}, "built-in toggles in registration order")

local commands = require("core.commands").inspect()
local names = vim.iter(commands)
    :map(function(entry)
        return entry.name
    end)
    :totable()
for _, required in ipairs({
    "Root",
    "LspLog",
    "LspExec",
    "ConfigReload",
    "PackUpdate",
    "Format",
    "Toggles",
}) do
    T.check(vim.tbl_contains(names, required), (":%s is registered"):format(required))
end
T.equal(require("core.commands").is_builtin("edit"), true, ":edit detected as built-in")
T.equal(require("core.commands").is_builtin("Root"), false, ":Root is not treated as a built-in")

local pack = require("core.pack")
T.check(#pack.ids() >= 5, "plugin specs are declared")

-- Lazy semantics: after startup, plugins whose trigger has not fired are still
-- unloaded, while their stubs exist.
T.equal(pack.is_loaded("oil.nvim"), false, "command-triggered plugin stays unloaded after startup")
T.equal(
    pack.is_loaded("conform.nvim"),
    false,
    "event-triggered plugin stays unloaded after startup"
)
T.check(vim.api.nvim_get_commands({}).Oil ~= nil, "command stub for Oil exists")
T.check(vim.fn.maparg("-", "n", false, true).desc ~= nil, "key stub for oil's '-' exists")
T.equal(pack.get("oil.nvim").cmd, { "Oil" }, "oil command trigger declared")
T.equal(pack.get("conform.nvim").event, { "BufWritePre" }, "conform event trigger declared")
T.equal(pack.get("nvim-treesitter-context").event, { "VeryLazy" }, "VeryLazy trigger declared")
T.equal(pack.get("mini.nvim").reloadable, true, "reloadable flag preserved")

-- A headless session never installs plugins (documented safety property).
pack.register({
    src = "file:///nonexistent/core-test-missing",
    name = "core-test-missing",
    cmd = { "CoreTestMissing" },
})
local ok, err = pack.load("core-test-missing")
T.equal(ok, false, "loading a missing plugin fails instead of installing")
T.check(
    tostring(err):find("headless session", 1, true) ~= nil,
    "failure reason explains the headless install refusal: " .. tostring(err)
)

-- Core autocommands exist in owned augroups (clearing them is what makes
-- reload duplicate-free).
T.check(T.count_core_autocmds() > 0, "core autocommands exist")

-- Subsystems are loadable and report state.
T.check(require("core.health") ~= nil, "health module loadable")
T.check(type(require("core.reload").watch_state().watched), "number", "watcher reports counts")

T.finish()
