-- Input configuration — optimized for this hardware:
--   • Touchpad: ASCF1201:00 2808:0231 (I2C-HID, internal). Hyprland misclassifies it as a
--     "mouse" (listed under mice:), so input.touchpad.* does NOT apply to it.
--     => Use hl.device() by name to target it reliably (verified working).
--   • External keyboard: "Sino Wealth USB Keyboard" (main) + laptop "AT Translated Set 2 keyboard"
--   • External wireless mouse: YICHIP Wireless Device Mouse (dongle)
--   • Layout: us (en_US locale), single layout
--   • User is a hardcore Neovim user => CapsLock as extra Esc + aggressive key repeat for hjkl
-- Docs: https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
	input = {
		-- Pointer / external mouse
		accel_profile = "flat", -- no cursor acceleration (raw, predictable pointer for precise editing)
		sensitivity = 1.0, -- neutral (range -1.0..1.0)
		natural_scroll = false, -- external mice: standard scroll (wheel up = content up)
		scroll_factor = 1.0, -- external mouse scroll speed multiplier
		follow_mouse = 1, -- focus follows cursor (0=off, 1=always, 2=detached, 3=fully separate)
		mouse_refocus = true, -- refocus only when cursor crosses a window boundary
		float_switch_override_focus = 1, -- focus follows mouse on tile<->float switch

		-- Keyboard (Vim-optimized)
		kb_layout = "us",
		-- CapsLock -> additional Esc (Esc stays Esc): two Esc keys for Neovim,
		-- and CapsLock can never be toggled on by accident (unlike caps:swapescape).
		kb_options = "caps:escape",
		numlock_by_default = true, -- enable numlock on session start
		repeat_rate = 50, -- repeats/sec (default 25; aggressive for fast hjkl nav in Neovim)
		repeat_delay = 250, -- ms before repeat starts (default 600; snappy for vim)
		resolve_binds_by_sym = false, -- keybinds resolve via first layout (fine for single-layout)

		-- NOTE: input.touchpad.* is kept as a no-op fallback; it does NOT apply to the ASCF1201
		-- because Hyprland classifies it as a mouse. Touchpad options are set per-device below.
		touchpad = {
			disable_while_typing = true,
			natural_scroll = true,
			tap_to_click = true,
			clickfinger_behavior = true,
			tap_and_drag = true,
			drag_lock = 0, -- 0=off, 1=timeout, 2=sticky (int per docs)
			middle_button_emulation = false,
			scroll_factor = 1.0,
		},
	},
})

-- Per-device touchpad config (robust: ASCF1201 is misclassified as "mouse", so input.touchpad
-- does not apply. Target it by name to guarantee touchpad behavior. Verified working.)
hl.device({
	name = "ascf1201:00-2808:0231-touchpad",
	natural_scroll = true, -- Mac-like: content follows finger direction
	tap_to_click = true, -- tap with 1/2/3 fingers = L/R/M click
	clickfinger_behavior = true, -- 1/2/3-finger click = L/R/M (location-independent; disables bottom zones)
	tap_and_drag = true, -- tap then drag without holding the button
	drag_lock = 0, -- 0=off, 1=timeout, 2=sticky (int per docs)
	disable_while_typing = true, -- palm rejection: ignore touchpad while typing
	middle_button_emulation = false, -- keep default (no LMB+RMB = middle emulation)
	scroll_factor = 1.0, -- touchpad scroll speed multiplier
})

-- Touchpad gestures (docs: Advanced/Gestures)
-- 4 fingers, horizontal: switch workspaces (like scrolling :bnext/:bprev)
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
-- 4 fingers, down: toggle the scratchpad (dropdown-style, like SUPER+S)
hl.gesture({ fingers = 4, direction = "down", action = "special", workspace_name = "special" })
-- 3 fingers, any swipe: move the active window; pinch: fullscreen.
-- (A catch-all "swipe" gesture overshadows any direction-specific gesture
-- with the same finger count, so no extra per-direction gestures here.)
hl.gesture({ fingers = 3, direction = "swipe", action = "move" })
hl.gesture({ fingers = 3, direction = "pinch", action = "fullscreen" })

-- Gesture tuning (end-4 style): longer, more deliberate workspace swipes
hl.config({
	gestures = {
		workspace_swipe_distance = 700,
		workspace_swipe_cancel_ratio = 0.2,
		workspace_swipe_min_speed_to_force = 5,
		workspace_swipe_direction_lock = true,
		workspace_swipe_direction_lock_threshold = 10,
		workspace_swipe_create_new = true,
	},
})
