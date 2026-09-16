local S = require("config.settings")

hl.on("config.reloaded", function()
    S.notify("Hyprland config reloaded")
end)
