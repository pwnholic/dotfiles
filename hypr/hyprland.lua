local modules = {
    "config.settings",
    "config.monitors",
    "config.environment",
    "config.inputs",
    "config.decorations",
    "config.animations",
    "config.rules",
    "config.binds",
    "config.events",
}

local function notify(message)
    pcall(function()
        hl.notification.create({ text = message, timeout = 15000 })
    end)
end

local failures = 0
for _, module_name in ipairs(modules) do
    local ok, err = pcall(require, module_name)
    if not ok then
        failures = failures + 1
        notify("Hyprland config error: " .. module_name)
    end
end

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("uwsm app -- noctalia")
end)
