-- Window & layer rules (merged: both are declarative match-based rules).
-- Wiki: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--       https://wiki.hypr.land/Configuring/Basics/Window-Rules/#layer-rules

local S = require("config.settings")

-- ============================================================
-- WINDOW RULES
-- ============================================================

-- Generic floating position
hl.window_rule({ match = { float = true }, center = true, persistent_size = true })

-- Picture-in-Picture
hl.window_rule({
	match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
	float = true,
	keep_aspect_ratio = true,
	size = { "max(monitor_w, monitor_h)*0.25", "min(monitor_w, monitor_h)*0.25" },
	pin = true,
})

-- Apps
hl.window_rule({ match = { class = "^(vesktop|discord)$" }, monitor = S.monitors.primary })
hl.window_rule({
	match = { class = "^(.*[Cc]alc.*)$" },
	float = true,
	size = { "max(monitor_w, monitor_h)*0.17", "min(monitor_w, monitor_h)*0.43" },
})
hl.window_rule({ match = { class = "^(org\\.kde\\.keditfiletype)$" }, float = true })
hl.window_rule({
	match = { class = "^(org\\.kde\\.ark)$" },
	size = { "max(monitor_w, monitor_h)*0.40", "min(monitor_w, monitor_h)*0.40" },
})
hl.window_rule({
	match = { class = "^(.*satty.*)$", title = "^(Satty)$" },
	min_size = { "max(monitor_w, monitor_h)*0.35", "min(monitor_w, monitor_h)*0.35" },
	float = true,
})
hl.window_rule({
	match = { class = "^(dev\\.)?(noctalia\\.Noctalia(\\.Settings)?)$" },
	float = true,
	size = { "monitor_w*0.70", "monitor_h*0.70" },
})

-- hl.window_rule({
-- 	match = {
-- 		class = "^(org\\.gnome\\.Nautilus)$",
-- 		title = "negative:^(Moving.*|Create New.*|Extract.*|Compress.*|Copying.*|Progress.*|Configure.*|Properties.*|Choose\\sApplication.*)$",
-- 	},
-- 	float = true,
-- 	size = { "max(monitor_w, monitor_h)*0.50", "min(monitor_w, monitor_h)*0.55" },
-- 	move = {
-- 		"max(20,min(cursor_x-(window_w*0.50),monitor_w-window_w+20))", -- X axis clamping
-- 		"max(20,min(cursor_y-50,monitor_h-window_h+20))", -- Y axis clamping
-- 	},
-- })

-- Opacity overrides: one rule instead of three (terminals + media players get
-- full opacity so terminal-configured transparency / video pipelines win).
-- Terminal class list is shared with decorations.lua via settings.classes.
hl.window_rule({
	match = {
		class = "^(firefox|zen|"
			.. S.classes.terminals
			.. "|mpv|org\\.kde\\.haruna|.*plex.*|org\\.kde\\.gwenview|.*vlc.*)$",
	},
	opacity = "1.0 override",
})

-- GPG pinentry (docs example): stays focused + on top so git commit --gpg-sign
-- and ssh auth prompts never lose focus behind the terminal that triggered them
hl.window_rule({
	match = { class = "^(pinentry.*|Gcr-prompter|gcr-prompter)$" },
	float = true,
	stay_focused = true,
	dim_around = true,
})

-- Float utility windows & common modals (single table, single loop)
local FLOAT_MATCHES = {
	-- Utility apps
	{ class = "^(kvantummanager|qt[56]ct|nwg-look)$" },
	{ class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-applet|nm-connection-editor)$" },
	{ title = "^(Winetricks.*|Protontricks.*)$" },
	-- Common modal dialogs
	{
		title = "^(Open|Authentication Required|Add Folder to Workspace|Choose Files|Save As|Confirm to replace files|File Operation Progress)$",
	},
	{ initial_title = "^(Open File)$" },
	{ class = "^([Xx]dg-desktop-portal-gtk)$" },
	{ title = "^(Enter name of file to save to.*|Save As.*|Open File.*)$" },
	{ class = "^(.*dialog.*)$" },
	{ title = "^(.*dialog.*)$" },
	{ class = "^(hyprland-share-picker)$" },
}
for _, m in ipairs(FLOAT_MATCHES) do
	hl.window_rule({ match = m, float = true })
end

-- Portal dialogs: constrain size so they don't blow up to monitor dimensions
hl.window_rule({
	match = { class = "^([Xx]dg-desktop-portal-gtk)$" },
	float = true,
	center = true,
	size = { "max(monitor_w, monitor_h)*0.60", "max(monitor_w, monitor_h)*0.40" },
})

-- Streaming & recording apps
hl.window_rule({
	match = { class = "^(com\\.obsproject\\.Studio)$" },
	monitor = S.monitors.primary,
})
-- Privacy: blank Obsidian so its content NEVER appears in screen shares / recordings.
-- (Hyprland >= 0.50; draws a black rectangle over the window during capture.)
hl.window_rule({
	match = { class = "^(md\\.obsidian\\.Obsidian)$" },
	no_screen_share = true,
})

hl.window_rule({
	match = { class = "^(org\\.telegram\\.desktop)$" },
	no_screen_share = true,
})

hl.window_rule({
	match = { class = "discord" },
	no_screen_share = true,
})

-- OBS projector / fullscreen previews: float, always on top, no focus steal
hl.window_rule({
	match = { class = "^(com\\.obsproject\\.Studio)$", title = "^(.*)[Pp]rojector(.*)$" },
	float = true,
})
-- gpu-screen-recorder overlay: never steal focus from the game
hl.window_rule({ match = { class = "^(gpu-screen-recorder.*)$" }, no_focus = true })
hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

-- ============================================================
-- LAYER RULES
-- ============================================================

-- Noctalia v5 shell surfaces (official rule from the Noctalia Hyprland
-- docs). One regex covers every surface the shell draws:
--   bar-*  · notification · dock · panel · attached-panel · osd · window-switcher
-- Surfaces are SOLID (no transparency): only ignore_alpha keeps rounded
-- corners crisp, and no_anim disables Hyprland's layer animations so
-- Noctalia's own open/close motion (shell.animation) plays alone.
hl.layer_rule({
	name = "noctalia-solid",
	match = {
		namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
	},
	no_anim = true,
	ignore_alpha = 0.5,
})
