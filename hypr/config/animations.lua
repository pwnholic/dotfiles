-- Animations — end-4 "expressive" family upgraded with physical springs.
-- Two-curve strategy: springs for SPATIAL motion (window/workspace moves are
-- mass-spring simulations that stay fluid at 144Hz), beziers for OPACITY and
-- popin timing (asymmetric ease-out only). No loop styles anywhere (battery).
-- Curves are shared visually with the Noctalia shell: its panels pop with the
-- same emphasized-deceleration feel.

-- ===== Curves =====
-- Bezier family (end-4 "expressive", for fades/popins/borders)
local CURVES = {
	expressiveFastSpatial = { { 0.42, 1.67 }, { 0.21, 0.90 } },
	expressiveSlowSpatial = { { 0.39, 1.29 }, { 0.35, 0.98 } },
	expressiveDefaultSpatial = { { 0.38, 1.21 }, { 0.22, 1.00 } },
	emphasizedDecel = { { 0.05, 0.7 }, { 0.1, 1 } },
	emphasizedAccel = { { 0.3, 0 }, { 0.8, 0.15 } },
	standardDecel = { { 0, 0 }, { 0, 1 } },
	menu_decel = { { 0.1, 1 }, { 0, 1 } },
	menu_accel = { { 0.52, 0.03 }, { 0.72, 0.08 } },
	stall = { { 1, -0.1 }, { 0.7, 0.85 } },
	-- Spring family (for spatial motion at high refresh rates):
	-- mass=1 per docs guidance; stiffness = speed, dampening = less bounce.
	-- "glide": near-critically damped — fast settle, no visible oscillation.
	-- "snap": quick and tight for small elements (borders, layers).
	-- "drawer": slightly softer for the scratchpad dropdown.
	glide = { type = "spring", mass = 1, stiffness = 320, dampening = 30 },
	snap = { type = "spring", mass = 1, stiffness = 500, dampening = 38 },
	drawer = { type = "spring", mass = 1, stiffness = 240, dampening = 26 },
}

for name, def in pairs(CURVES) do
	if def.type == "spring" then
		hl.curve(name, { type = "spring", mass = def.mass, stiffness = def.stiffness, dampening = def.dampening })
	else
		-- bezier entries store the two control points directly in the table
		-- (def[1], def[2]), so `points = def` — NOT `def.points` (which is nil).
		hl.curve(name, { type = "bezier", points = def })
	end
end

-- ===== Animation table: leaf -> { speed, bezier|spring, style } =====
local ANIMATIONS = {
	-- Windows: pop in fast (bezier), move with physical spring
	windowsIn = { speed = 3, bezier = "emphasizedDecel", style = "popin 80%" },
	fadeIn = { speed = 3, bezier = "emphasizedDecel" },
	windowsOut = { speed = 2, bezier = "emphasizedDecel", style = "popin 90%" },
	fadeOut = { speed = 2, bezier = "emphasizedAccel" },
	-- Spring: dragging/moving windows tracks the pointer like a physical object.
	-- NOTE: speed stays required even with a spring curve — omitting it makes
	-- Hyprland treat the leaf as unset (verified live via `hyprctl animations`).
	windowsMove = { speed = 10, spring = "glide", style = "slide" },
	border = { speed = 10, spring = "snap" },
	-- Focus-change fades: one motion language for opacity/shadow/dim
	fadeSwitch = { speed = 3, bezier = "emphasizedDecel" },
	fadeShadow = { speed = 3, bezier = "emphasizedDecel" },
	fadeDim = { speed = 3, bezier = "emphasizedDecel" },
	-- Wayland popups (menus, tooltips): quick fade so they feel attached
	fadePopupsIn = { speed = 3, bezier = "emphasizedDecel" },
	fadePopupsOut = { speed = 2, bezier = "emphasizedAccel" },

	-- Layers (shell panels): pop in near-full size, menu-style out.
	-- These cover the Noctalia launcher/control-center/OSD surfaces.
	layersIn = { speed = 2.7, bezier = "emphasizedDecel", style = "popin 93%" },
	layersOut = { speed = 2.4, bezier = "menu_accel", style = "popin 94%" },
	fadeLayersIn = { speed = 0.5, bezier = "menu_decel" },
	fadeLayersOut = { speed = 2.7, bezier = "stall" },

	-- Workspaces: spring "whoosh" — the end-4 long deceleration, now physical.
	-- Slides stop exactly when the workspace lands (no bezier overshoot fight).
	workspaces = { speed = 10, spring = "glide", style = "slide" },

	-- Special workspace: drawer feel with its own softer spring
	specialWorkspaceIn = { speed = 10, spring = "drawer", style = "slidevert" },
	specialWorkspaceOut = { speed = 10, spring = "snap", style = "slidevert" },

	-- Hotplug: new monitor settles with a short zoom (no loop styles)
	monitorAdded = { speed = 2, bezier = "emphasizedDecel" },

	-- Border gradient angle: settle once per focus change, never loop
	borderangle = { speed = 5, bezier = "standardDecel", style = "once" },

	-- Cursor zoom (SUPER+Minus/Plus)
	zoomFactor = { speed = 3, bezier = "standardDecel" },
}

-- Guard: every animation must reference a known curve (bezier or spring);
-- a typo here would otherwise fail silently or fall back to "default".
local known_curves = {}
for name in pairs(CURVES) do
	known_curves[name] = true
end

local ok, S = pcall(require, "config.settings")
local notify = ok and type(S.notify) == "function" and S.notify or print

for leaf, a in pairs(ANIMATIONS) do
	local curve_name = a.bezier or a.spring
	if not known_curves[curve_name] then
		notify(("animations.lua: leaf '%s' references unknown curve '%s'"):format(leaf, tostring(curve_name)))
	end
	local spec = { leaf = leaf, enabled = true, speed = a.speed, style = a.style }
	if a.spring then
		spec.spring = a.spring
	else
		spec.bezier = a.bezier
	end
	hl.animation(spec)
end
