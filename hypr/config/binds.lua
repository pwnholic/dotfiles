-- Keybinds for the vim-style Hyprland setup.

local S = require("config.settings")

local main_mod = "SUPER"
local noctalia_cmd = "noctalia msg "
local launch_prefix = "uwsm app -- "

local submap_context = ""
local seen_binds = {}
local modifiers = {
    ALT = true,
    CONTROL = true,
    CTRL = true,
    SHIFT = true,
    SUPER = true,
}

local function canonical(keys)
    local mods = {}
    local key
    for token in keys:gmatch("[^+]+") do
        local value = token:gsub("^%s+", ""):gsub("%s+$", "")
        if modifiers[value] then
            mods[#mods + 1] = value
        elseif key == nil then
            key = value
        end
    end

    table.sort(mods)
    return table.concat(mods, "+") .. "|" .. (key or "")
end

local function bind(keys, dispatcher, flags)
    if flags ~= nil and type(flags) ~= "table" then
        error(("bind flags for '%s' must be a table"):format(keys), 2)
    end

    local id = submap_context .. "|" .. canonical(keys)
    if seen_binds[id] then
        local scope = submap_context ~= "" and ("submap '" .. submap_context .. "'") or "global scope"
        S.notify(("duplicate bind '%s' in %s — last one wins"):format(keys, scope))
    end
    seen_binds[id] = true
    if flags == nil then
        return hl.bind(keys, dispatcher)
    end
    return hl.bind(keys, dispatcher, flags)
end

local function submap(name, body)
    submap_context = name
    local ok, err = pcall(hl.define_submap, name, body)
    submap_context = ""
    if not ok then
        S.notify(("failed to define submap '%s'"):format(name))
        error(err)
    end
end

local motions = {
    { key = "H", lower = "h", arrow = "Left",  arrow_lower = "left",  focus = "left",  move = "l", x = -20, y = 0 },
    { key = "J", lower = "j", arrow = "Down",  arrow_lower = "down",  focus = "down",  move = "d", x = 0,   y = 20 },
    { key = "K", lower = "k", arrow = "Up",    arrow_lower = "up",    focus = "up",    move = "u", x = 0,   y = -20 },
    { key = "L", lower = "l", arrow = "Right", arrow_lower = "right", focus = "right", move = "r", x = 20,  y = 0 },
}

-- Window management
bind(main_mod .. " + Q", hl.dsp.window.close())
bind(main_mod .. " + Escape", hl.dsp.window.kill())
bind(main_mod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }))
bind(main_mod .. " + F", hl.dsp.window.fullscreen())
bind(main_mod .. " + D", hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Focus and movement
for _, motion in ipairs(motions) do
    bind(main_mod .. " + " .. motion.key, hl.dsp.focus({ direction = motion.focus }))
    bind(main_mod .. " + " .. motion.arrow, hl.dsp.focus({ direction = motion.focus }))
    bind(main_mod .. " + SHIFT + " .. motion.key, hl.dsp.window.move({ direction = motion.move }))
    bind(main_mod .. " + SHIFT + " .. motion.arrow, hl.dsp.window.move({ direction = motion.move }))
end

bind("ALT + Tab", hl.dsp.window.cycle_next(), { non_consuming = true })
bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }), { non_consuming = true })
bind(main_mod .. " + Tab", hl.dsp.exec_cmd(noctalia_cmd .. "window-switcher"), { non_consuming = false })
bind(main_mod .. " + O", hl.dsp.focus({ urgent_or_last = true }))
bind(main_mod .. " + ALT + P", hl.dsp.window.pin())

-- Groups
bind(main_mod .. " + G", hl.dsp.group.toggle())
bind(main_mod .. " + SHIFT + G", hl.dsp.window.move({ out_of_group = true }))
bind("CONTROL + Tab", hl.dsp.group.next(), { allow_input_capture = true })
bind("CONTROL + SHIFT + Tab", hl.dsp.group.prev(), { allow_input_capture = true })
bind(main_mod .. " + ALT + G", hl.dsp.group.lock_active())

-- Resize submap
bind(main_mod .. " + R", hl.dsp.submap("resize"))
submap("resize", function()
    for _, motion in ipairs(motions) do
        local resize_flags = { repeating = true }
        bind(motion.lower, hl.dsp.window.resize({ x = motion.x, y = motion.y, relative = true }), resize_flags)
        bind(motion.arrow_lower, hl.dsp.window.resize({ x = motion.x, y = motion.y, relative = true }), resize_flags)
    end
    for _, key in ipairs({ "escape", "return", "q", "catchall" }) do
        bind(key, hl.dsp.submap("reset"))
    end
end)

bind(main_mod .. " + mouse:272", hl.dsp.window.drag())
bind(main_mod .. " + mouse:273", hl.dsp.window.resize())

-- Dwindle layout
bind(main_mod .. " + CONTROL + S", hl.dsp.layout("togglesplit"))
bind(main_mod .. " + ALT + S", hl.dsp.layout("swapsplit"))
bind(main_mod .. " + ALT + R", hl.dsp.layout("rotatesplit"))
bind(main_mod .. " + SHIFT + M", hl.dsp.layout("movetoroot active"))
for _, motion in ipairs(motions) do
    bind(main_mod .. " + SHIFT + ALT + " .. motion.key, hl.dsp.layout("preselect " .. motion.move))
end
bind(main_mod .. " + ALT + D", hl.dsp.window.pseudo())

-- Cursor zoom
local function zoom(delta)
    local current, err = hl.get_config("cursor:zoom_factor")
    if err ~= nil or type(current) ~= "number" then
        current = 1.0
    end
    local value = math.max(1.0, math.min(3.0, current + delta))
    hl.config({ cursor = { zoom_factor = value } })
end

for _, zoom_bind in ipairs({
    { keys = { "Minus", "code:82" }, delta = -0.3 },
    { keys = { "Plus", "code:86" },  delta = 0.3 },
}) do
    for _, key in ipairs(zoom_bind.keys) do
        bind(main_mod .. " + " .. key, function()
            zoom(zoom_bind.delta)
        end, { repeating = true })
    end
end

-- Launchers
bind(main_mod .. " + Return", hl.dsp.exec_cmd(launch_prefix .. S.apps.terminal))
bind(main_mod .. " + E", hl.dsp.exec_cmd(launch_prefix .. S.apps.file_manager))
bind(main_mod .. " + T", hl.dsp.exec_cmd(launch_prefix .. S.apps.editor))
bind(main_mod .. " + C", hl.dsp.exec_cmd(launch_prefix .. S.apps.calculator))
bind("XF86Calculator", hl.dsp.exec_cmd(launch_prefix .. S.apps.calculator))
bind(main_mod .. " + W", hl.dsp.exec_cmd(launch_prefix .. S.apps.browser))
bind(main_mod .. " + Z", hl.dsp.exec_cmd(noctalia_cmd .. "settings-toggle"))
bind(main_mod .. " + X", hl.dsp.exec_cmd(noctalia_cmd .. "panel-toggle control-center"))
bind(main_mod .. " + Space", hl.dsp.exec_cmd(noctalia_cmd .. "panel-toggle launcher"))
bind(main_mod .. " + period", hl.dsp.exec_cmd(noctalia_cmd .. "panel-toggle launcher /emo"))
bind(main_mod .. " + SHIFT + code:201", hl.dsp.exec_cmd(noctalia_cmd .. "panel-toggle launcher"))
bind(main_mod .. " + SHIFT + Escape", hl.dsp.exec_cmd(noctalia_cmd .. "session lock"))
bind(main_mod .. " + SHIFT + E", hl.dsp.exec_cmd(noctalia_cmd .. "panel-toggle session"))

-- Hardware controls. Each flags value is a table accepted by hl.bind.
local hardware_binds = {
    { key = "XF86AudioRaiseVolume",  cmd = "volume-up",        flags = { locked = true, repeating = true } },
    { key = "XF86AudioLowerVolume",  cmd = "volume-down",      flags = { locked = true, repeating = true } },
    { key = "XF86AudioMute",         cmd = "volume-mute",      flags = { locked = true } },
    { key = "XF86AudioMicMute",      cmd = "mic-mute",         flags = { locked = true } },
    { key = "XF86AudioPlay",         cmd = "media toggle",     flags = { locked = true } },
    { key = "XF86AudioPause",        cmd = "media toggle",     flags = { locked = true } },
    { key = "XF86AudioNext",         cmd = "media next",       flags = { locked = true } },
    { key = "XF86AudioPrev",         cmd = "media previous",   flags = { locked = true } },
    { key = "XF86Bluetooth",         cmd = "bluetooth-toggle", flags = { locked = true } },
    { key = "XF86MonBrightnessUp",   cmd = "brightness-up",    flags = { locked = true, repeating = true } },
    { key = "XF86MonBrightnessDown", cmd = "brightness-down",  flags = { locked = true, repeating = true } },
}
for _, hardware in ipairs(hardware_binds) do
    bind(hardware.key, hl.dsp.exec_cmd(noctalia_cmd .. hardware.cmd), hardware.flags)
end

-- Utility binds
bind(main_mod .. " + P", hl.dsp.exec_cmd("hyprpicker -a -n"))
bind("Print", hl.dsp.exec_cmd(noctalia_cmd .. "screenshot-region"))
bind(main_mod .. " + Print", hl.dsp.exec_cmd(noctalia_cmd .. "screenshot-fullscreen"))
bind(main_mod .. " + SHIFT + W", hl.dsp.exec_cmd(noctalia_cmd .. "panel-toggle wallpaper"))
bind(main_mod .. " + V", hl.dsp.exec_cmd(noctalia_cmd .. "panel-toggle clipboard"))
bind(main_mod .. " + A", hl.dsp.exec_cmd(noctalia_cmd .. "panel-toggle control-center notifications"))

-- Noctalia shell controls without dedicated hardware keys
local noctalia_binds = {
    { keys = main_mod .. " + B",         cmd = "bluetooth-toggle" },
    { keys = main_mod .. " + SHIFT + A", cmd = "notification-dnd-toggle" },
    { keys = main_mod .. " + ALT + N",   cmd = "nightlight-toggle" },
    { keys = main_mod .. " + ALT + K",   cmd = "caffeine-toggle" },
    { keys = main_mod .. " + ALT + W",   cmd = "wallpaper-next" },
    { keys = main_mod .. " + ALT + T",   cmd = "theme-mode-toggle" },
    { keys = main_mod .. " + ALT + M",   cmd = "power-cycle" },
}
for _, item in ipairs(noctalia_binds) do
    bind(item.keys, hl.dsp.exec_cmd(noctalia_cmd .. item.cmd))
end

-- Workspaces
for i = 1, S.workspaces.count do
    local key = tostring(i % 10)
    bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    bind(main_mod .. " + CONTROL + " .. key, hl.dsp.focus({ workspace = "m~" .. i }))
end

for key, target in pairs({ H = "m-1", L = "m+1", Left = "m-1", Right = "m+1" }) do
    bind(main_mod .. " + CONTROL + " .. key, hl.dsp.focus({ workspace = target }))
end
bind(main_mod .. " + CONTROL + J", hl.dsp.focus({ workspace = "emptym" }))
bind(main_mod .. " + CONTROL + Down", hl.dsp.focus({ workspace = "emptym" }))
bind(main_mod .. " + grave", hl.dsp.focus({ workspace = "previous_per_monitor" }))
bind(main_mod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "previous_per_monitor", follow = true }))

for _, key in ipairs({ "H", "L", "Left", "Right" }) do
    local target = (key == "H" or key == "Left") and "m-1" or "m+1"
    bind(main_mod .. " + SHIFT + CONTROL + " .. key, hl.dsp.window.move({ workspace = target }))
end

bind(main_mod .. " + SHIFT + CONTROL + mouse_up", hl.dsp.window.move({ workspace = "m+1" }))
bind(main_mod .. " + SHIFT + CONTROL + mouse_down", hl.dsp.window.move({ workspace = "m-1" }))
bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "m+1" }))
bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "m-1" }))
bind(main_mod .. " + CONTROL + mouse_up", hl.dsp.focus({ workspace = "m+1" }))
bind(main_mod .. " + CONTROL + mouse_down", hl.dsp.focus({ workspace = "m-1" }))

-- Monitors
bind(main_mod .. " + ALT + H", hl.dsp.focus({ monitor = "-1" }))
bind(main_mod .. " + ALT + L", hl.dsp.focus({ monitor = "+1" }))
bind(main_mod .. " + ALT + Left", hl.dsp.window.move({ monitor = "-1" }))
bind(main_mod .. " + ALT + Right", hl.dsp.window.move({ monitor = "+1" }))
bind(main_mod .. " + ALT + mouse_up", hl.dsp.window.move({ monitor = "+1" }))
bind(main_mod .. " + ALT + mouse_down", hl.dsp.window.move({ monitor = "-1" }))

-- Special workspace
bind(main_mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special" }))
bind(main_mod .. " + S", hl.dsp.workspace.toggle_special())
