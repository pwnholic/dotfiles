-- Look & feel and general compositor settings.
-- Visual language ported from end-4/dots-hyprland (illogical-impulse):
-- tight gaps + huge inter-workspace gap, hairline translucent border,
-- squircle-lite rounding, frosted xray blur, soft shadow, subtle inactive dim.
-- Accent colors are synchronized with the Noctalia "aurora" palette
-- (settings.lua -> M.palette): teal-mint focus accent, violet group accent.

local S = require("config.settings")

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 5,
        gaps_workspaces = 50, -- end-4 signature: workspaces breathe apart during switches
        border_size = 2,
        extend_border_grab_area = 10,
        resize_on_border = true,
        col = {
            -- Only the ACTIVE window gets a colored border; inactive windows are
            -- fully transparent (rgba ...00) so the accent reads as a focus indicator.
            -- Gradient matches the Noctalia aurora accent (teal -> deep teal).
            active_border = {
                colors = { S.palette.primary, S.palette.primary_deep },
                angle = 45,
            },
            inactive_border = S.palette.surface,
        },
        -- focus stays put when nothing is in that direction (no monitor-jumping focus)
        no_focus_fallback = true,
        snap = {
            enabled = true,
            window_gap = 4,
            monitor_gap = 5,
            respect_gaps = true,
        },
    },
    group = {
        col = {
            -- Grouped windows flash violet (aurora secondary) to distinguish
            -- them from the teal focus accent.
            border_active = S.palette.secondary,
            border_inactive = S.palette.surface,
            border_locked_active = S.palette.errors,
            border_locked_inactive = S.palette.surface,
        },
        groupbar = {
            col = {
                active = S.palette.secondary,
                inactive = S.palette.surface,
                locked_active = S.palette.error,
                locked_inactive = S.palette.surface,
            },
        },
    },
    decoration = {
        -- Super-ellipse ("squircle") corners: rounding_power 4 makes the curve
        -- continuous into the straight edges (iOS/macOS-style) instead of a
        -- circular arc that shows a visible tangent break. This is what makes
        -- corners read as "very smooth" — the radius is only half the story.
        rounding = 0,
        rounding_power = 0,
        active_opacity = 0.97,
        inactive_opacity = 0.84,
        fullscreen_opacity = 1,
        dim_inactive = true,
        dim_strength = 0.08, -- slightly stronger than end-4: focus reads clearly at 144Hz glance
        dim_special = 0.2,
        blur = {
            size = 12,
            passes = 3,    -- sweet spot for the Intel iGPU at 144Hz: quality without frame drops
            xray = true,   -- floating windows show tiled silhouettes through the frost
            brightness = 1.0,
            noise = 0.035, -- finer grain reads as glass, not static
            contrast = 0.86,
            vibrancy = 0.6,
            vibrancy_darkness = 0.5,
            special = true,
            -- Frosted Wayland popups (menus/tooltips), crisp rounded corners
            popups = true,
            popups_ignorealpha = 0.2,
            input_methods = true,
            input_methods_ignorealpha = 0.2,
        },
        shadow = {
            enabled = true,
            range = 24,       -- wider falloff: softer, more diffuse grounding
            offset = { 0, 3 },
            render_power = 4, -- docs cap: [1-4]
            color = S.palette.shadow,
        },
    },
    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = false,
        precise_mouse_move = true, -- bindm drag drops windows where the cursor actually is
    },
    misc = {
        -- Global UI font for Hyprland-rendered text (splash, notifications,
        -- config errors). Family "Iosevka" verified installed via fc-list;
        -- the "Iosevka Nerd Font" name does not resolve in fontconfig.
        font_family = "Iosevka",
        splash_font_family = "Iosevka",
        col = {
            splash = S.palette.primary,
        },
        middle_click_paste = false,
        enable_swallow = true,
        -- Terminal class list is shared with rules.lua via settings.classes
        swallow_regex = "(" .. S.classes.terminals .. ")",
        -- vrr = 0: with vrr=3, Hyprland forces a DRM modeset every time a window
        -- (e.g. mpv) enters fullscreen to enable Variable Refresh Rate -> the screen
        -- flashes black. Disabled on purpose; the eDP-1 panel doesn't expose VRR
        -- anyway (hyprctl monitors shows vrr: false).
        vrr = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        -- wake the display from DPMS-off on any input (end-4 behavior)
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
    binds = {
        scroll_event_delay = 0, -- workspace wheel switching feels instant
        hide_special_on_workspace_change = true,
        -- Re-focusing the current workspace number jumps back to the previous
        -- one (vim's C-^ alternate-buffer behavior)
        workspace_back_and_forth = true,
    },
    xwayland = {
        force_zero_scaling = true,
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
})
