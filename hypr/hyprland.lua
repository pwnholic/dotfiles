-- CachyOS Hyprland Configuration — entry point.
--
-- Modules load in dependency order (settings first, everything else requires
-- it). Each module is loaded with error isolation: a broken module reports
-- itself through a compositor notification and the journal instead of taking
-- the whole session config down. "critical" modules abort the load sequence
-- because everything after them depends on them.

local MODULES = {
	{ name = "config.settings", critical = true }, -- apps / monitors / palette
	{ name = "config.monitors", critical = true }, -- monitor & workspace rules
	{ name = "config.environment", critical = false }, -- GPU / env vars
	{ name = "config.inputs", critical = false }, -- keyboard / touchpad / gestures
	{ name = "config.decorations", critical = false }, -- look & feel
	{ name = "config.animations", critical = false }, -- curves & animations
	{ name = "config.rules", critical = false }, -- window & layer rules
	{ name = "config.binds", critical = false }, -- keybinds (vim grammar)
	{ name = "config.events", critical = false }, -- IPC event handlers (socket2)
}

local failures = 0

-- Notification via Noctalia (the session daemon). Falls back to the
-- compositor's built-in notification if config.settings itself is broken.
local function notify(text)
	local ok, S = pcall(require, "config.settings")
	if ok and type(S.notify) == "function" then
		S.notify(text)
	else
		print("[hypr config] " .. text)
		pcall(function()
			hl.notification.create({ text = text, timeout = 30000 })
		end)
	end
end

for _, m in ipairs(MODULES) do
	local ok, err = pcall(require, m.name)
	if not ok then
		failures = failures + 1
		print(("[hypr config] FAILED to load %s:\n\t%s"):format(m.name, err))
		notify(("Hypr config: error in %s (see journalctl)"):format(m.name))
		if m.critical then
			print("[hypr config] aborting: critical module failed")
			break
		end
	end
end

if failures == 0 then
	print("[hypr config] all modules loaded")
end

--------------------------------------------------------------------
-- Autostart (merged from config/autostart.lua).
-- Session is UWSM-managed: prefer XDG autostart for regular apps
-- (https://wiki.archlinux.org/title/XDG_Autostart); only compositor-level
-- bootstrap commands belong here.
--------------------------------------------------------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	-- Noctalia via uwsm: systemd user unit → survives shell restarts,
	-- own cgroup, inherits the Wayland session cleanly.
	-- Secret Service (org.freedesktop.secrets) via gnome-keyring:
	-- persistent credentials for Zed (GitHub/API logins) and Noctalia
	-- storage (`key_source = "secret-service"`). No exec-once needed:
	-- gnome-keyring ships a D-Bus activation file and is auto-started
	-- on first request; unlocked at login via pam_gnome_keyring in
	-- /etc/pam.d/greetd.
	hl.exec_cmd("uwsm app -- noctalia")
	-- Polkit agent: provided by Noctalia (`polkit_agent = true` in shell.toml);
	-- hyprpolkitagent intentionally not started to avoid duplicate agents.
	hl.exec_cmd("xhost +SI:localuser:root")
end)
