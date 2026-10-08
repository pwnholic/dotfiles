--- t04: terminal slots, reuse, context synchronization, lazygit.
local T = dofile(vim.fs.joinpath(vim.fn.stdpath("config"), "tests", "helpers.lua"))

local term = require("core.terminal")

local base = T.tmpdir("terminal")
local proj_a = vim.fs.joinpath(base, "alpha")
local proj_b = vim.fs.joinpath(base, "beta")
for _, dir in ipairs({ proj_a, proj_b }) do
    vim.fn.mkdir(dir, "p")
    T.write(vim.fs.joinpath(dir, ".git", "HEAD"), { "ref: refs/heads/main" })
end
T.write(vim.fs.joinpath(proj_a, "a.txt"), { "a" })
T.write(vim.fs.joinpath(proj_b, "b.txt"), { "b" })

vim.cmd.cd(vim.fn.fnameescape(proj_a))
vim.cmd.edit(vim.fn.fnameescape(vim.fs.joinpath(proj_a, "a.txt")))
T.equal(require("core.root").context_root(), proj_a, "context root is project alpha")

-- Creating a slot spawns exactly one shell and shows a float.
T.check(term.toggle(1), "slot 1 opened")
T.wait(1500)
local slot = assert(term.slot_state(1), "slot state is inspectable")
T.check(slot.alive, "slot shell is running")
T.check(slot.visible, "slot is visible")
T.equal(slot.cwd, proj_a, "slot starts in the project context directory")
local bufnr_first = slot.bufnr

-- Hiding keeps the process and the buffer: reopening reuses them.
T.check(term.hide(1), "slot 1 hidden")
T.equal(term.slot_state(1).visible, false, "slot is no longer visible")
T.check(term.slot_state(1).alive, "process survived hiding")
T.check(term.toggle(1), "slot 1 shown again")
T.equal(assert(term.slot_state(1)).bufnr, bufnr_first, "the same terminal buffer is reused")
T.check(assert(term.slot_state(1)).job == slot.job, "the same process is reused (no new shell)")

-- Visible terminals are never forcibly changed.
term.hide(1)
local synced, sync_reason = term.sync_slot(1, proj_b)
T.check(synced, "hidden, idle terminal is synchronized (reason: " .. tostring(sync_reason) .. ")")
T.wait(700)
T.equal(term.slot_state(1).cwd, proj_b, "hidden, idle terminal followed the context")
T.check(term.toggle(1), "slot 1 shown")
T.equal(term.sync_cwd(proj_a), 0, "visible terminals are skipped by sync_cwd")
T.equal(term.slot_state(1).cwd, proj_b, "visible terminal keeps its own cwd")

-- Busy shells are never written to (no stray input into running programs).
T.check(term.hide(1), "slot 1 hidden before the busy test")
term.send(1, "sleep 5\n")
T.wait(900)
T.equal(term.is_idle(1), false, "a foreground job is detected as busy")
T.equal(term.sync_slot(1, proj_a), false, "busy shells are not synchronized")
T.equal(term.slot_state(1).cwd, proj_b, "busy shell cwd unchanged")
term.send(1, "\3")
T.wait(900)
T.equal(term.is_idle(1), true, "shell is idle again after interrupting the job")

-- Slot isolation: slot 2 is a separate process.
T.check(term.toggle(2), "slot 2 opened")
T.wait(1200)
local slot2 = assert(term.slot_state(2), "slot 2 state")
T.check(slot2.alive, "slot 2 is running")
T.check(slot2.bufnr ~= bufnr_first, "slot 2 uses its own buffer")
T.check(slot2.pid ~= slot.pid, "slot 2 uses its own process")
term.hide(2)

-- lazygit reuses the terminal infrastructure (same slot code path).
T.check(term.lazygit("root"), "lazygit is accepted in root mode")
local launched = term.inspect().last_command
T.check(launched ~= nil, "the launched command is inspectable")
T.equal(launched.cmd, { "lazygit" }, "lazygit is the launched command")
T.equal(launched.cwd, proj_a, "lazygit root mode resolves the project root")
T.check(term.lazygit("cwd"), "lazygit cwd mode is accepted while a slot exists")
T.equal(
    term.inspect().last_command.cwd,
    vim.uv.cwd(),
    "lazygit cwd mode resolves the current directory"
)
-- In a headless session lazygit has no usable TTY and exits immediately; the
-- integration must clean the slot up instead of leaving a dead terminal.
T.wait(1500)
local git_slot = term.slot_state("lazygit")
T.check(git_slot == nil or git_slot.alive, "lazygit slot is either alive or cleaned up")
term.kill("lazygit")

-- Failures are reported, not raised.
local messages = T.capture_notifications()
vim.cmd("Lazygit nonsense")
T.flush_notifications()
T.check(T.notified(messages, "expected root|cwd"), ":Lazygit validates its argument")

-- Inspector + command surface.
T.check(#term.report_lines() > 3, ":Terminal inspector has content")
local inspector_messages = T.capture_notifications()
vim.cmd("Terminal info")
T.check(vim.fn.bufnr("core://terminals") ~= -1, ":Terminal info opens the inspector")
vim.cmd("Terminal 99")
T.check(T.notified(inspector_messages, "beyond the configured"), "out-of-range slot warns")
vim.cmd("Terminal close")
T.equal(term.is_visible(1), false, ":Terminal close hides all terminals")

-- Teardown kills processes (used by :ConfigReload so no shell is orphaned).
local pid = term.slot_state(1).pid
term.kill(1)
T.equal(term.slot_state(1), nil, "slot removed")
-- SIGHUP is asynchronous: give the kernel a moment before asserting.
vim.wait(2000, function()
    return not require("lib.process").is_running(pid)
end, 50)
T.equal(require("lib.process").is_running(pid), false, "shell process was terminated")

T.finish()
