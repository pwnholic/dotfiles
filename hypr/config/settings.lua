-- Central settings module: the ONLY file you should need to edit to tune the
-- setup. Apps, monitors, workspaces, shared match patterns, and the palette.
-- Consumers use:  local S = require("config.settings")
-- The module validates its own values at load time (see validate() below).

local M = {}

-- ===== Default apps =====
M.apps = {
	terminal = "kitty", -- kitty runs programs directly: `kitty btop` (no -e flag)
	file_manager = "nautilus",
	browser = "firefox",
	editor = "zeditor",
	calculator = "gnome-calculator",
}

-- ===== Monitors (output names come from `hyprctl monitors`) =====
M.monitors = {
	external = "HDMI-A-1", -- docked external screen
	internal = "eDP-1", -- laptop panel
	primary = "HDMI-A-1",
}

-- ===== Workspaces =====
M.workspaces = {
	num_per_monitor = 9, -- workspace count per monitor (valid range: 1..10)
}

-- ===== Shared window-class patterns =====
-- Single source of truth: reused by rules.lua (opacity overrides) and
-- decorations.lua (swallow_regex). Keep this an alternation without anchors.
M.classes = {
	terminals = "kitty|ghostty|[Kk]onsole|Alacritty|foot|gnome-terminal|xfce[0-9]?-terminal",
}

-- ===== Color palette =====
-- Synchronized with the Noctalia "aurora" palette
-- (~/.config/noctalia/palettes/aurora.json) so Hyprland borders and the shell
-- speak the same color language: teal-mint primary, violet secondary.
M.palette = {
	primary_deep = "rgba(0f8d7aff)",
	secondary_deep = "rgba(6d4fd6ff)",
	grey = "rgba(98a0c3ff)",
	invisible = "rgba(31313600)",
	shadow = "rgba(07080f30)",
	primary = "rgba(5fd6c2ff)",
	surface = "rgba(0d0f1aff)",
	secondary = "rgba(a78bfaff)",
	error = "rgba(f28b92ff)",
}

-- ===== Notification helper =====
-- Noctalia is the session's notification daemon, so config errors go through
-- `noctalia msg notification-show`. hl.notification.create is only a fallback
-- (compositor-internal OSD). Note: during the very first session start
-- noctalia is not up yet, so startup errors land in the journal instead.
local function shell_quote(s)
	return "'" .. tostring(s):gsub("'", "'\\''") .. "'"
end

function M.notify(text)
	print("[hypr config] " .. text)
	local ok = pcall(hl.exec_cmd, "noctalia msg notification-show " .. shell_quote(text))
	if not ok then
		pcall(function()
			hl.notification.create({ text = text, timeout = 15000 })
		end)
	end
end

-- ===== Validation =====
-- Clamp/repair obviously wrong values instead of failing at runtime with a
-- cryptic compositor error. Each repair surfaces a notification so the
-- mistake does not silently change behavior.
local function warn(message)
	M.notify("settings.lua: " .. message)
end

local function validate()
	local ws = M.workspaces
	if type(ws.num_per_monitor) ~= "number" then
		warn("workspaces.num_per_monitor must be a number; falling back to 9")
		ws.num_per_monitor = 9
	elseif ws.num_per_monitor < 1 or ws.num_per_monitor > 10 then
		warn(("workspaces.num_per_monitor %d out of range 1..10; clamped"):format(ws.num_per_monitor))
		ws.num_per_monitor = math.max(1, math.min(10, math.floor(ws.num_per_monitor)))
	end

	for name, output in pairs({ external = M.monitors.external, internal = M.monitors.internal }) do
		if type(output) ~= "string" or output == "" then
			warn(("monitors.%s must be a non-empty string (run `hyprctl monitors`)"):format(name))
		end
	end

	-- Palette entries must be rgba(RRGGBBAA) — exactly 8 hex digits — or
	-- Hyprland rejects them with a cryptic "invalid color" at load time
	-- (verified: a 9-digit hex typo produced 'invalid color' on a gradient stop).
	for pname, color in pairs(M.palette) do
		if type(color) == "string" then
			local hex = color:match("rgba%((%x+)%)")
			if hex == nil or #hex ~= 8 then
				warn(("palette.%s = '%s' is not a valid rgba color (need exactly 8 hex digits)"):format(pname, color))
			end
		end
	end

	if M.monitors.primary ~= M.monitors.external and M.monitors.primary ~= M.monitors.internal then
		warn("monitors.primary does not match any known output; monitor rules may misplace windows")
	end
end

validate()

return M
