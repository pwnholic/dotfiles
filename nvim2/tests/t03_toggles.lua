--- t03: toggle registry, scopes, notifications, format gates.
local T = dofile(vim.fs.joinpath(vim.fn.stdpath("config"), "tests", "helpers.lua"))

local format = require("core.format")
local toggle = require("core.toggle")

-- A provider is required for the "would format" decision (the plugin layer
-- registers conform.nvim in a real session).
format.set_provider({
    name = "test-provider",
    format = function()
        return true
    end,
})

local buf = vim.api.nvim_create_buf(true, false)
vim.api.nvim_win_set_buf(0, buf)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local x = 1", "return x" })

-- Notifications report the *verified* resulting state.
local messages = T.capture_notifications()
T.equal(toggle.toggle("diagnostics"), false, "diagnostics toggled off")
T.check(T.notified(messages, "Diagnostics: OFF"), "notification reports OFF")
T.equal(toggle.toggle("diagnostics"), true, "diagnostics toggled back on")
T.check(T.notified(messages, "Diagnostics: ON"), "notification reports ON")

-- Window scope: the toggle must not leak into other windows.
local other = vim.api.nvim_open_win(
    buf,
    false,
    { relative = "editor", width = 10, height = 3, row = 1, col = 1 }
)
vim.api.nvim_set_current_win(other)
T.equal(vim.wo[other].wrap, true, "wrap is on in the second window (global default)")
local first_state = toggle.toggle("wrap", { winid = other, bufnr = buf })
T.equal(first_state, false, "wrap toggled off in the second window")
T.equal(vim.wo[other].wrap, false, "window-local wrap changed")
T.equal(vim.wo[vim.api.nvim_get_current_win()].wrap, false, "current window is the same window")

-- Gate matrix requires a provider: it is re-registered above.

-- Buffer scope: buffer-local gates are buffer-local.
local other_buf = vim.api.nvim_create_buf(true, false)
T.equal(format.effective_buffer_enabled(other_buf), true, "buffer gate defaults to inherit (on)")
toggle.set("autoformat_buffer", false, { bufnr = other_buf, winid = 0 })
T.equal(format.buffer_state(other_buf), false, "buffer gate off only for that buffer")
T.equal(format.effective_buffer_enabled(buf), true, "other buffer keeps inheriting")
T.equal(
    toggle.state("autoformat_buffer", { bufnr = other_buf, winid = 0 }),
    false,
    "state read back"
)

-- Global gate: runtime state survives a new configuration generation
-- (documented precedence: runtime state wins over the configured default).
toggle.set("autoformat", false)
T.equal(format.enabled(), false, "global format gate off")
format.teardown()
format.setup({ on_save = true, autoformat = true })
T.equal(format.enabled(), false, "runtime gate wins over the configured default")
toggle.set("autoformat", true)
format.set_provider({
    name = "test-provider",
    format = function()
        return true
    end,
})

-- The gate matrix (the four documented combinations).
local cases = {
    { gate = true, buffer = nil, want = true },
    { gate = true, buffer = true, want = true },
    { gate = true, buffer = false, want = false },
    { gate = false, buffer = nil, want = false },
    { gate = false, buffer = true, want = false },
    { gate = false, buffer = false, want = false },
}
for _, case in ipairs(cases) do
    format.set_enabled(case.gate)
    vim.b[buf].core_autoformat = case.buffer
    local should, reason = format.should_format(buf)
    T.equal(
        should,
        case.want,
        ("gate matrix global=%s buffer=%s -> %s (%s)"):format(
            tostring(case.gate),
            tostring(case.buffer),
            tostring(case.want),
            reason
        )
    )
end
format.set_enabled(true)
vim.b[buf].core_autoformat = nil

-- Special buffers are never formatted, whatever the gates say.
local special = vim.api.nvim_create_buf(false, true)
vim.bo[special].buftype = "nofile"
T.equal(format.should_format(special), false, 'buftype != "" is never formatted')

-- A toggle without a provider is unavailable, not an error.
local state, err = toggle.state("treesitter_context")
T.equal(state, nil, "unavailable toggle has unknown state")
T.check(tostring(err) ~= "nil", "unavailable toggle explains itself: " .. tostring(err))
local messages2 = T.capture_notifications()
T.equal(toggle.toggle("treesitter_context"), nil, "toggling an unavailable provider returns nil")
T.check(
    T.notified(messages2, "unavailable") or T.notified(messages2, "state unknown"),
    "unavailable provider is reported to the user"
)

-- Unknown toggle ids are rejected.
T.equal(toggle.toggle("does-not-exist"), nil, "unknown toggle is reported, not thrown")

-- Inspector + :Toggles <id>.
T.check(#toggle.report_lines() > 5, "toggle inspector has content")
T.check(pcall(vim.cmd, "Toggles"), ":Toggles runs")
T.check(vim.fn.bufnr("core://toggles") ~= -1, ":Toggles opens the inspector buffer")

-- Extension point: register + attach a toggle at runtime.
local ok_reg = toggle.register({
    id = "test-toggle",
    label = "Test toggle",
    scope = "buffer",
})
T.check(ok_reg, "custom toggle registered")
local value = false
local ok_att = toggle.attach("test-toggle", {
    get = function()
        return value
    end,
    set = function(v)
        value = v
    end,
})
T.check(ok_att, "implementation attached")
T.equal(toggle.toggle("test-toggle"), true, "custom toggle flips to on")
T.equal(toggle.toggle("test-toggle"), false, "custom toggle flips back to off")
T.equal(toggle.register({ id = "bad", scope = "planet" }), false, "invalid scope rejected")

-- A toggle registered after setup gets its keymap immediately (registry change
-- notification), so late registrations are first-class.
T.check(
    toggle.register({ id = "late", label = "Late toggle", scope = "window", key = "<leader>uL" }),
    "late toggle registered"
)
local late_map = vim.fn.maparg("<leader>uL", "n", false, true)
T.check(
    late_map.desc ~= nil and late_map.desc:find("Late toggle", 1, true) ~= nil,
    "late toggle keymap exists: " .. tostring(late_map.desc)
)

-- Toggles without a provider still report their default state honestly.
local late_state, late_err = toggle.state("late")
T.equal(late_state, nil, "late toggle without implementation has unknown state")
T.check(tostring(late_err):find("no implementation", 1, true) ~= nil, "reason is explicit")

T.finish()
