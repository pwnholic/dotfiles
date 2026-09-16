local M = {}

M.apps = {
    terminal = "kitty",
    file_manager = "nautilus",
    browser = "firefox",
    editor = "zeditor",
    calculator = "gnome-calculator",
}

M.monitors = {
    external = { name = "DP-1", position = "0x60" },
    internal = { name = "eDP-1", position = "1920x0" },
    primary = "eDP-1",
}

M.workspaces = { count = 9 }
M.layout = "dwindle"
M.commands = {
    launch = "uwsm app -- ",
    noctalia = "noctalia msg ",
}

M.classes = {
    terminals = "kitty|ghostty|[Kk]onsole|Alacritty|foot|gnome-terminal|xfce[0-9]?-terminal",
}

M.palette = {
    primary = "rgba(5fd6c2ff)",
    primary_deep = "rgba(0f8d7aff)",
    secondary = "rgba(a78bfaff)",
    secondary_deep = "rgba(6d4fd6ff)",
    surface = "rgba(0d0f1aff)",
    grey = "rgba(98a0c3ff)",
    shadow = "rgba(07080f30)",
    invisible = "rgba(31313600)",
    error = "rgba(f28b92ff)",
}

local function quote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

function M.notify(message)
    local ok = pcall(hl.exec_cmd, M.commands.noctalia .. "notification-show " .. quote(message))
    if not ok then
        pcall(function()
            hl.notification.create({ text = message, timeout = 15000 })
        end)
    end
end

local function validate()
    local count = M.workspaces.count
    if type(count) ~= "number" or count < 1 or count > 10 then
        M.workspaces.count = 9
        M.notify("settings.lua: workspace count reset to 9")
    else
        M.workspaces.count = math.floor(count)
    end

    for key, monitor in pairs({ external = M.monitors.external, internal = M.monitors.internal }) do
        if type(monitor.name) ~= "string" or monitor.name == "" then
            M.notify("settings.lua: monitors." .. key .. ".name is invalid")
        end
    end

    for name, color in pairs(M.palette) do
        local hex = type(color) == "string" and color:match("rgba%((%x+)%)")
        if hex == nil or #hex ~= 8 then
            M.notify("settings.lua: invalid color " .. name)
        end
    end

    if M.monitors.primary ~= M.monitors.external.name
        and M.monitors.primary ~= M.monitors.internal.name then
        M.notify("settings.lua: primary monitor is not configured")
    end
end

validate()
return M
