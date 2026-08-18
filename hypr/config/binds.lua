-- Keybinds — a vim grammar for the window manager, designed for a hardcore
-- Neovim user switching between two keyboards:
--   1. Internal laptop keyboard (full layout, has arrow keys)
--   2. 60% external keyboard (no arrows / nav cluster; Fn layer sends XF86 media keys)
--
-- THE GRAMMAR (operator + motion, like vim):
--   SUPER             + H/J/K/L   -> focus window (motion)
--   SUPER + SHIFT     + H/J/K/L   -> move window (SHIFT = "stronger" motion)
--   SUPER + CTRL      + H/L, N    -> workspace motion (:bprev/:bnext, :buffer N)
--   SUPER + ALT       + H/L       -> monitor motion (relative, works docked or not)
--   SUPER + SHIFT     + ALT + dir -> preselect split for the NEXT window
--   SUPER + ALT       + Left/Right-> move window to monitor (hjkl form is taken
--                                      by preselect; arrows + ALT+wheel cover it)
--   SUPER + R                     -> modal resize mode (hjkl resize, ESC exits)
--   ESC always exits a mode; SUPER+ESC force-kills a window (":q!");
--   SUPER+SHIFT+ESC locks the session.
-- Arrow keys mirror every hjkl motion, so the internal keyboard feels identical.
-- Mouse wheel convention (unified): wheel UP = next, wheel DOWN = previous.
-- Media/volume/brightness need no extra binds: the 60% Fn layer emits XF86* keys.
-- Docs: https://wiki.hypr.land/Configuring/Basics/Binds/

local S = require("config.settings")

local mainMod = "SUPER"
local noctCall = "noctalia msg "
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")

--------------------------------------------------------------------
-- Bind registry: guards against accidental duplicate chords.
-- Hyprland silently lets the LAST bind win, so a collision means one feature
-- quietly stops working. Surface it as a notification instead.
--------------------------------------------------------------------
local submap_ctx = "" -- "" = global scope, otherwise the submap name
local seen_binds = {}

-- Canonical chord form: modifiers sorted alphabetically + key last, so
-- "SUPER + SHIFT + ALT + H" and "SUPER + ALT + SHIFT + H" compare equal
-- (they are the same chord to Hyprland).
local function canonical(keys)
	local mods, key = {}, nil
	for token in keys:gmatch("[^+]+") do
		local t = token:gsub("^%s+", ""):gsub("%s+$", "")
		if key == nil and not t:match("^SUPER$|^SHIFT$|^ALT$|^CONTROL$|^CTRL$") then
			key = t -- first non-modifier token is the key
		else
			table.insert(mods, t)
		end
	end
	table.sort(mods)
	return table.concat(mods, "+") .. "|" .. (key or "")
end

local function bind(keys, dispatcher, opts)
	local id = submap_ctx .. "|" .. canonical(keys)
	if seen_binds[id] then
		local where = (submap_ctx ~= "") and ("submap '" .. submap_ctx .. "'") or "global scope"
		S.notify(("duplicate bind '%s' in %s — last one wins"):format(keys, where))
	end
	seen_binds[id] = true
	return hl.bind(keys, dispatcher, opts)
end

-- define_submap wrapper that also scopes the duplicate detection
local function submap(name, body)
	submap_ctx = name
	local ok, err = pcall(hl.define_submap, name, body)
	submap_ctx = ""
	if not ok then
		S.notify(("failed to define submap '%s'"):format(name))
		error(err)
	end
end

--------------------------------------------------------------------
-- Motion tables (single source of truth for hjkl <-> arrows/directions)
--------------------------------------------------------------------
-- focus: Hyprland focus direction names; move: dwindle move codes
local MOTIONS = {
	{ key = "H", lower = "h", arrow = "Left", arrow_lower = "left", focus = "left", move = "l", rx = -20, ry = 0 },
	{ key = "J", lower = "j", arrow = "Down", arrow_lower = "down", focus = "down", move = "d", rx = 0, ry = 20 },
	{ key = "K", lower = "k", arrow = "Up", arrow_lower = "up", focus = "up", move = "u", rx = 0, ry = -20 },
	{ key = "L", lower = "l", arrow = "Right", arrow_lower = "right", focus = "right", move = "r", rx = 20, ry = 0 },
}

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Close / kill (":q" vs ":q!")
bind(mainMod .. " + Q", hl.dsp.window.close())
bind(mainMod .. " + Escape", hl.dsp.window.kill())

-- Window state toggles
bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))
bind(mainMod .. " + F", hl.dsp.window.fullscreen()) -- real fullscreen (covers everything)
bind(mainMod .. " + D", hl.dsp.window.fullscreen({ mode = "maximized" })) -- maximized (keeps gaps/bar)

---------------------------------
---- FOCUS (window motion) ----
---------------------------------

for _, d in ipairs(MOTIONS) do
	-- Vim home row (primary form, identical on both keyboards)
	bind(mainMod .. " + " .. d.key, hl.dsp.focus({ direction = d.focus }))
	-- Arrow mirrors (internal keyboard)
	bind(mainMod .. " + " .. d.arrow, hl.dsp.focus({ direction = d.focus }))
end

-- Cycle windows (:bnext / :bprev)
bind("ALT + Tab", hl.dsp.window.cycle_next())
bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))
bind(mainMod .. " + Tab", hl.dsp.exec_cmd(noctCall .. "window-switcher"))
-- Jumplist back: jump to the urgent or last-focused window (CTRL+O in Neovim)
bind(mainMod .. " + O", hl.dsp.focus({ urgent_or_last = true }))

------------------------------------------
---- MOVE WINDOW (SHIFT = stronger) ----
------------------------------------------

for _, d in ipairs(MOTIONS) do
	bind(mainMod .. " + SHIFT + " .. d.key, hl.dsp.window.move({ direction = d.move }))
	bind(mainMod .. " + SHIFT + " .. d.arrow, hl.dsp.window.move({ direction = d.move }))
end

-- Pin window: always on top, visible on all workspaces (PiP style)
bind(mainMod .. " + ALT + P", hl.dsp.window.pin())

---------------------------------
---- GROUPS (tabbed windows) ----
---------------------------------

bind(mainMod .. " + G", hl.dsp.group.toggle()) -- group / ungroup active window
bind(mainMod .. " + SHIFT + G", hl.dsp.window.move({ out_of_group = true })) -- pull window out of its group
bind("CONTROL + Tab", hl.dsp.group.next()) -- next tab in group (browser-like)
bind("CONTROL + SHIFT + Tab", hl.dsp.group.prev()) -- previous tab in group
bind(mainMod .. " + ALT + G", hl.dsp.group.lock_active()) -- lock group against accidental tab switches

---------------------------------
---- RESIZE (modal, SUPER+R) ----
---------------------------------

-- SUPER+R enters resize mode, then H/L change width and J/K change height
-- (repeat while held). ESC / Enter / Q — or any unknown key — exits the mode.
bind(mainMod .. " + R", hl.dsp.submap("resize"))
submap("resize", function()
	for _, d in ipairs(MOTIONS) do
		bind(d.lower, hl.dsp.window.resize({ x = d.rx, y = d.ry, relative = true }), { repeating = true })
		bind(d.arrow_lower, hl.dsp.window.resize({ x = d.rx, y = d.ry, relative = true }), { repeating = true })
	end
	-- Exit the mode (like ESC in vim). catchall also exits on any unknown key,
	-- so no keystrokes leak into the focused app while resizing (docs pattern).
	for _, k in ipairs({ "escape", "return", "q", "catchall" }) do
		bind(k, hl.dsp.submap("reset"))
	end
end)

-- Move & resize with the mouse
bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

----------------------------------
---- DWINDLE LAYOUT MESSAGES ----
----------------------------------

-- Split control (requires dwindle.preserve_split = true, set in decorations.lua)
bind(mainMod .. " + CONTROL + S", hl.dsp.layout("togglesplit")) -- toggle split orientation (h/v)
bind(mainMod .. " + ALT + S", hl.dsp.layout("swapsplit")) -- swap the two halves of the split
bind(mainMod .. " + ALT + R", hl.dsp.layout("rotatesplit")) -- rotate split 90 degrees clockwise
bind(mainMod .. " + SHIFT + M", hl.dsp.layout("movetoroot active")) -- maximize within its subtree
-- Preselect the split direction for the NEXT window to open (one-shot override,
-- like setting a split before :new)
for _, d in ipairs(MOTIONS) do
	bind(mainMod .. " + SHIFT + ALT + " .. d.key, hl.dsp.layout("preselect " .. d.move))
end
-- Pseudo tiling: tile the window but keep its floating size
bind(mainMod .. " + ALT + D", hl.dsp.window.pseudo())

-- Zoom (cursor magnifier), clamped to [1.0, 3.0]
local function zoom(delta)
	local current, err = hl.get_config("cursor:zoom_factor")
	if err ~= nil or type(current) ~= "number" then
		-- Config read failed (e.g. key renamed upstream): reset to neutral.
		current = 1.0
	end
	local clamped = math.max(1.0, math.min(3.0, current + delta))
	hl.config({ cursor = { zoom_factor = clamped } })
end

local ZOOM_KEYS = {
	{ keys = { "Minus", "code:82" }, delta = -0.3 }, -- minus / numpad minus
	{ keys = { "Plus", "code:86" }, delta = 0.3 }, -- plus / numpad plus (internal keyboard)
}
for _, z in ipairs(ZOOM_KEYS) do
	for _, key in ipairs(z.keys) do
		bind(mainMod .. " + " .. key, function()
			zoom(z.delta)
		end, { repeating = true })
	end
end

------------------
---- LAUNCHER ----
------------------

bind(mainMod .. " + Return", hl.dsp.exec_cmd(launchPrefix .. S.apps.terminal))
bind(mainMod .. " + E", hl.dsp.exec_cmd(launchPrefix .. S.apps.file_manager))
bind(mainMod .. " + T", hl.dsp.exec_cmd(launchPrefix .. S.apps.editor))
bind(mainMod .. " + C", hl.dsp.exec_cmd(launchPrefix .. S.apps.calculator))
bind("XF86Calculator", hl.dsp.exec_cmd(launchPrefix .. S.apps.calculator))
bind(mainMod .. " + W", hl.dsp.exec_cmd(launchPrefix .. S.apps.browser))
bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(launchPrefix .. S.apps.terminal .. " btop")) -- kitty runs programs directly (no -e flag)
bind(mainMod .. " + Z", hl.dsp.exec_cmd(noctCall .. "settings-toggle"))
bind(mainMod .. " + X", hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center"))
bind(mainMod .. " + Space", hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher"))
bind(mainMod .. " + period", hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher /emo"))
-- Lock screen on SUPER+SHIFT+Escape; plain SUPER+L is vim-style focus right
-- and SUPER+ALT+L is monitor-focus (grammar). The original SUPER+ALT+L lock
-- chord collided with monitor focus and silently disabled it.
bind(mainMod .. " + SHIFT + Escape", hl.dsp.exec_cmd(noctCall .. "session lock"))
bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd(noctCall .. "panel-toggle session"))

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio & media (work from the 60% Fn layer too: it emits real XF86* keys)
local HARDWARE_KEYS = {
	{ key = "XF86AudioRaiseVolume", cmd = "volume-up", repeat_key = true },
	{ key = "XF86AudioLowerVolume", cmd = "volume-down", repeat_key = true },
	{ key = "XF86AudioMute", cmd = "volume-mute" },
	{ key = "XF86AudioMicMute", cmd = "mic-mute" },
	{ key = "XF86AudioPlay", cmd = "media toggle" },
	{ key = "XF86AudioPause", cmd = "media toggle" },
	{ key = "XF86AudioNext", cmd = "media next" },
	{ key = "XF86AudioPrev", cmd = "media previous" },
	{ key = "XF86Bluetooth", cmd = "bluetooth-toggle" },
	{ key = "XF86MonBrightnessUp", cmd = "brightness-up", repeat_key = true },
	{ key = "XF86MonBrightnessDown", cmd = "brightness-down", repeat_key = true },
}
for _, h in ipairs(HARDWARE_KEYS) do
	local opts = { locked = true }
	if h.repeat_key then
		opts.repeating = true
	end
	bind(h.key, hl.dsp.exec_cmd(noctCall .. h.cmd), opts)
end

-------------------
---- UTILITIES ----
-------------------

-- Screen capture
bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -a -n"))
bind("Print", hl.dsp.exec_cmd(noctCall .. "screenshot-region"))
bind(mainMod .. " + Print", hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"))

-- Theming / wallpaper / clipboard / notifications
bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(noctCall .. "panel-toggle wallpaper"))
bind(mainMod .. " + V", hl.dsp.exec_cmd(noctCall .. "panel-toggle clipboard"))
bind(mainMod .. " + A", hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center notifications"))

-- Session exit ("ZZ"): use hyprshutdown, the docs-recommended way to quit
bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("hyprshutdown"))

------------------------------------------
---- NOCTALIA SHELL INTEGRATION (extra) ----
------------------------------------------
-- Quality-of-life shell controls that have no hardware key on the 60% board.
local NOCTALIA_BINDS = {
	-- Radios
	{ keys = mainMod .. " + B", cmd = "bluetooth-toggle" },
	-- Focus modes
	{ keys = mainMod .. " + SHIFT + A", cmd = "notification-dnd-toggle" }, -- A = notifications panel, SHIFT = stronger
	{ keys = mainMod .. " + ALT + N", cmd = "nightlight-toggle" },
	{ keys = mainMod .. " + ALT + K", cmd = "caffeine-toggle" }, -- "keep awake"
	-- Looks
	{ keys = mainMod .. " + ALT + W", cmd = "wallpaper-next" },
	{ keys = mainMod .. " + ALT + T", cmd = "theme-mode-toggle" }, -- T = editor; ALT+T = theme toggle
	-- Power profile cycle (performance/balanced/power-saver)
	{ keys = mainMod .. " + ALT + M", cmd = "power-cycle" },
}
for _, n in ipairs(NOCTALIA_BINDS) do
	bind(n.keys, hl.dsp.exec_cmd(noctCall .. n.cmd))
end

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Workspace N, like :buffer N (absolute numbering); SHIFT+N moves the window
-- there; CTRL+N is workspace N on the CURRENT monitor (relative: m~N).
for i = 1, S.workspaces.num_per_monitor do
	local key = tostring(i % 10)
	bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
	bind(mainMod .. " + CONTROL + " .. key, hl.dsp.focus({ workspace = "m~" .. i }))
end

-- Previous / next workspace, like :bprev / :bnext
local WS_PREV_NEXT = { H = "m-1", L = "m+1", Left = "m-1", Right = "m+1" }
for key, target in pairs(WS_PREV_NEXT) do
	bind(mainMod .. " + CONTROL + " .. key, hl.dsp.focus({ workspace = target }))
end
-- First empty workspace on this monitor, like :enew
bind(mainMod .. " + CONTROL + J", hl.dsp.focus({ workspace = "emptym" }))
bind(mainMod .. " + CONTROL + Down", hl.dsp.focus({ workspace = "emptym" }))
-- Alternate workspace (vim C-^: jump to the workspace you just came from)
bind(mainMod .. " + grave", hl.dsp.focus({ workspace = "previous_per_monitor" }))
bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "previous_per_monitor", follow = true }))

-- Move window to prev/next workspace (SHIFT = stronger motion)
for _, key in ipairs({ "H", "L", "Left", "Right" }) do
	local target = (key == "H" or key == "Left") and "m-1" or "m+1"
	bind(mainMod .. " + SHIFT + CONTROL + " .. key, hl.dsp.window.move({ workspace = target }))
end
-- ...and via the wheel (unified: UP = next, DOWN = previous)
bind(mainMod .. " + SHIFT + CONTROL + mouse_up", hl.dsp.window.move({ workspace = "m+1" }))
bind(mainMod .. " + SHIFT + CONTROL + mouse_down", hl.dsp.window.move({ workspace = "m-1" }))

-- Scroll through workspaces with the mouse wheel (unified direction)
bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "m+1" }))
bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "m-1" }))
bind(mainMod .. " + CONTROL + mouse_up", hl.dsp.focus({ workspace = "m+1" }))
bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.focus({ workspace = "m-1" }))

-- Monitors, RELATIVE left/right (works identically docked or standalone,
-- no hardcoded monitor names or indices)
bind(mainMod .. " + ALT + H", hl.dsp.focus({ monitor = "-1" }))
bind(mainMod .. " + ALT + L", hl.dsp.focus({ monitor = "+1" }))
-- Move window to prev/next monitor. NOTE: the hjkl form (SUPER+ALT+SHIFT+H/L)
-- is intentionally NOT used here — it belongs to preselect (see grammar above);
-- a duplicate chord would silently disable one of the two features.
bind(mainMod .. " + ALT + Left", hl.dsp.window.move({ monitor = "-1" }))
bind(mainMod .. " + ALT + Right", hl.dsp.window.move({ monitor = "+1" }))
bind(mainMod .. " + ALT + mouse_up", hl.dsp.window.move({ monitor = "+1" }))
bind(mainMod .. " + ALT + mouse_down", hl.dsp.window.move({ monitor = "-1" }))

-- Special workspace (scratchpad) — a toggleable dropdown, like a terminal toggle
bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))
bind(mainMod .. " + S", hl.dsp.workspace.toggle_special())
