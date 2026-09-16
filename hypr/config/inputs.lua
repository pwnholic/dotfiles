hl.config({
    input = {
        accel_profile = "flat",
        sensitivity = 1,
        natural_scroll = false,
        scroll_factor = 1,
        follow_mouse = 1,
        mouse_refocus = true,
        float_switch_override_focus = 1,
        kb_layout = "us",
        kb_options = "caps:escape",
        numlock_by_default = true,
        repeat_rate = 50,
        repeat_delay = 250,
        resolve_binds_by_sym = false,
        touchpad = {
            disable_while_typing = true,
            natural_scroll = true,
            tap_to_click = true,
            clickfinger_behavior = true,
            tap_and_drag = true,
            drag_lock = 0,
            middle_button_emulation = false,
            scroll_factor = 1,
        },
    },
})

hl.device({
    name = "ascf1201:00-2808:0231-touchpad",
    disable_while_typing = true,
    natural_scroll = true,
    tap_to_click = true,
    clickfinger_behavior = true,
    tap_and_drag = true,
    drag_lock = 0,
    middle_button_emulation = false,
    scroll_factor = 1,
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "down", action = "special", workspace_name = "special" })
hl.gesture({ fingers = 3, direction = "swipe", action = "move" })
hl.gesture({ fingers = 3, direction = "pinch", action = "fullscreen" })

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
