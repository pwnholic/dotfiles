--- t05: safe reload (no duplicate resources, no leaked handles/timers).
local T = dofile(vim.fs.joinpath(vim.fn.stdpath("config"), "tests", "helpers.lua"))

local reload = require("core.reload")
local term = require("core.terminal")

-- Let deferred startup work (`VimEnter` -> `User VeryLazy` -> plugin loads)
-- settle, so the "before" snapshot is taken in a stable state, and load one
-- plugin explicitly so the trigger set is deterministic (a loaded plugin has no
-- stubs; that state must simply survive the reload unchanged).
T.flush_startup(800)
T.check(require("core.pack").load("nvim-treesitter"), "a plugin is loaded before the snapshot")

-- Exercise some state first so teardown has something to clean up.
local base = T.tmpdir("reload")
T.write(vim.fs.joinpath(base, ".git", "HEAD"), { "ref: refs/heads/main" })
T.write(vim.fs.joinpath(base, "file.txt"), { "x" })
vim.cmd.cd(vim.fn.fnameescape(base))
vim.cmd.edit(vim.fn.fnameescape(vim.fs.joinpath(base, "file.txt")))
local messages = T.capture_notifications()
require("core.toggle").toggle("spell")
local format = require("core.format")
local provider_ok = format.set_provider({
    name = "test-provider",
    format = function()
        return true
    end,
})
T.check(provider_ok, "test formatting provider registered")
T.check(term.toggle(1), "terminal opened before reload")
T.wait(1200)

local before = {
    autocmds = T.count_core_autocmds(),
    autocmd_list = T.autocmd_snapshot(),
    mappings = T.mapping_snapshot(),
    commands = T.command_snapshot(),
    fs_events = T.count_handles("fs_event"),
    timers = T.count_handles("timer"),
    watched = reload.watch_state().watched,
    terminal_pid = term.slot_state(1).pid,
}
T.check(before.autocmds > 0, "autocommands exist before reload")
T.check(before.fs_events > 0, "watcher handles exist before reload")

local ok, problems = reload.reload({ changed = { "tests" } })
T.equal(ok, true, "reload succeeded")
T.equal(problems, {}, "reload reported no problems")
T.check(T.notified(messages, "configuration reloaded"), "reload is reported to the user")

-- No duplicates: identical resource counts and identical mapping/command sets.
T.equal(T.autocmd_snapshot(), before.autocmd_list, "autocommand set is identical after reload")
T.equal(T.count_core_autocmds(), before.autocmds, "no duplicate autocommands after reload")
T.equal(T.mapping_snapshot(), before.mappings, "no duplicate or lost mappings after reload")
T.equal(T.command_snapshot(), before.commands, "no duplicate or lost commands after reload")

-- No leaked handles: watchers and timers must not accumulate.
T.equal(T.count_handles("fs_event"), before.fs_events, "no leaked file watchers after reload")
T.check(T.count_handles("timer") <= before.timers, "no leaked timers after reload")
-- Module identity changes across a reload (`package.loaded` is dropped), so the
-- new generation is inspected through a fresh require.
local reload_new = require("core.reload")
T.equal(reload_new.watch_state().watched, before.watched, "watcher still covers the same tree")
T.equal(reload_new.watch_state().enabled, true, "watcher is enabled after reload")
reload = reload_new

-- Documented behaviour: terminals are processes and are terminated on reload.
-- SIGHUP delivery is asynchronous, so wait for the kernel to reap the process.
vim.wait(2000, function()
    return not require("lib.process").is_running(before.terminal_pid)
end, 50)
T.equal(
    require("lib.process").is_running(before.terminal_pid),
    false,
    "terminal process was terminated by reload"
)
T.equal(require("core.terminal").slot_state(1), nil, "terminal slot state was cleared")

-- The new configuration generation is healthy (fresh require: the module
-- instance belongs to the new generation).
local core = require("core")
T.equal(core.errors, {}, "reloaded configuration has no errors")
T.equal(vim.g.core_generation, 2, "setup ran again (second configuration generation)")
T.equal(
    require("core.format").provider_name(),
    nil,
    "provider belongs to the previous generation and was dropped"
)

-- A second reload is equally clean (idempotent).
local ok2, problems2 = reload.reload()
T.equal(ok2, true, "second reload succeeded")
T.equal(problems2, {}, "second reload reported no problems")
T.equal(T.autocmd_snapshot(), before.autocmd_list, "still an identical autocommand set")
T.equal(vim.g.core_generation, 3, "third configuration generation")
T.equal(T.count_handles("fs_event"), before.fs_events, "still no leaked watchers")

-- Commands that the reload path depends on still work.
T.check(pcall(vim.cmd, "ConfigWatch status"), ":ConfigWatch status runs")
T.check(vim.fn.bufnr("core://config-watch") ~= -1, "watcher inspector opened")
T.check(pcall(vim.cmd, "PackStatus"), ":PackStatus runs after reload")
T.check(pcall(vim.cmd, "LspInfo"), ":LspInfo runs after reload")
T.check(pcall(vim.cmd, "FormatInfo"), ":FormatInfo runs after reload")

--- ---------------------------------------------------------------------------
--- Watcher-driven behaviours (auto reload + new directories)
--- ---------------------------------------------------------------------------

-- `reload.auto_reload` is off by default (notify-only), so the reload has to be
-- triggered by hand *or* by turning the option on: with the option on, a file
-- change under the config tree reloads the configuration by itself.
local defaults = require("core.defaults")
local previous_auto = defaults.values.reload.auto_reload
defaults.values.reload.auto_reload = true
T.equal(defaults.values.reload.auto_reload, true, "auto_reload can be enabled at runtime")

local generation = vim.g.core_generation
local probe = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "core", "__probe_auto_reload.lua")
vim.fn.writefile({ "-- probe: triggers the watcher", "return {}" }, probe)
local auto_reloaded = vim.wait(20000, function()
    return vim.g.core_generation > generation
end, 200)
T.check(auto_reloaded, "a file change reloads the configuration when auto_reload is on")
vim.fn.delete(probe)
defaults.values.reload.auto_reload = previous_auto

-- Directories created after the initial scan are watched too (the event arrives
-- through the parent directory, then the watcher list is refreshed).
-- The auto reload above replaced the module: read the *current* generation
-- (the previous instance's watcher table is frozen).
local reload_now = require("core.reload")
local watched_before = reload_now.watch_state().watched
local new_dir = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "probe_dir")
vim.fn.mkdir(new_dir, "p")
vim.fn.writefile({ "return {}" }, vim.fs.joinpath(new_dir, "init.lua"))
local grew = vim.wait(20000, function()
    return reload_now.watch_state().watched > watched_before
end, 200)
T.check(grew, "new directories are picked up by the watcher refresh")
vim.fn.delete(new_dir, "rf")
-- Reconciling the watchers is deterministic when called directly (the debounce
-- path above can race with an in-flight reload recreating all watchers).
require("core.reload").refresh_watchers()
T.equal(
    require("core.reload").watch_state().watched,
    watched_before,
    "refresh_watchers() drops watchers for removed directories"
)

T.finish()
