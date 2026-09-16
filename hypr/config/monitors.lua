local S = require("config.settings")

local outputs = {
    {
        name = S.monitors.external.name,
        mode = "1920x1080@100",
        position = S.monitors.external.position,
    },
    {
        name = S.monitors.internal.name,
        mode = "1920x1200@144",
        position = S.monitors.internal.position,
    },
}

for _, monitor in ipairs(outputs) do
    hl.monitor({
        output = monitor.name,
        mode = monitor.mode,
        position = monitor.position,
        scale = 1,
        bitdepth = 10,
        cm = "auto",
    })
end

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

local names = { "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X" }
for index = 1, S.workspaces.count do
    hl.workspace_rule({
        workspace = tostring(index),
        default_name = names[index] or tostring(index),
    })
end

hl.workspace_rule({
    workspace = "special",
    on_created_empty = "[float] " .. S.apps.terminal,
})
