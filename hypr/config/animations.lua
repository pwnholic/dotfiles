local curves = {
    expressive_fast = { 0.42, 1.67, 0.21, 0.90 },
    expressive_slow = { 0.39, 1.29, 0.35, 0.98 },
    emphasized_decel = { 0.05, 0.70, 0.10, 1.00 },
    emphasized_accel = { 0.30, 0.00, 0.80, 0.15 },
    standard_decel = { 0.00, 0.00, 0.00, 1.00 },
    menu_decel = { 0.10, 1.00, 0.00, 1.00 },
    menu_accel = { 0.52, 0.03, 0.72, 0.08 },
    stall = { 1.00, -0.10, 0.70, 0.85 },
}

for name, points in pairs(curves) do
    hl.curve(name, {
        type = "bezier",
        points = { { points[1], points[2] }, { points[3], points[4] } },
    })
end

hl.curve("glide", { type = "spring", mass = 1, stiffness = 320, dampening = 30 })
hl.curve("snap", { type = "spring", mass = 1, stiffness = 500, dampening = 38 })
hl.curve("drawer", { type = "spring", mass = 1, stiffness = 240, dampening = 26 })

local animations = {
    { leaf = "windowsIn",           speed = 3,   bezier = "emphasized_decel", style = "popin 80%" },
    { leaf = "windowsOut",          speed = 2,   bezier = "emphasized_decel", style = "popin 90%" },
    { leaf = "windowsMove",         speed = 10,  spring = "glide",            style = "slide" },
    { leaf = "border",              speed = 10,  spring = "snap" },
    { leaf = "fadeIn",              speed = 3,   bezier = "emphasized_decel" },
    { leaf = "fadeOut",             speed = 2,   bezier = "emphasized_accel" },
    { leaf = "fadeSwitch",          speed = 3,   bezier = "emphasized_decel" },
    { leaf = "fadeShadow",          speed = 3,   bezier = "emphasized_decel" },
    { leaf = "fadeDim",             speed = 3,   bezier = "emphasized_decel" },
    { leaf = "fadePopupsIn",        speed = 3,   bezier = "emphasized_decel" },
    { leaf = "fadePopupsOut",       speed = 2,   bezier = "emphasized_accel" },
    { leaf = "layersIn",            speed = 2.7, bezier = "emphasized_decel", style = "popin 93%" },
    { leaf = "layersOut",           speed = 2.4, bezier = "menu_accel",       style = "popin 94%" },
    { leaf = "fadeLayersIn",        speed = 0.5, bezier = "menu_decel" },
    { leaf = "fadeLayersOut",       speed = 2.7, bezier = "stall" },
    { leaf = "workspaces",          speed = 10,  spring = "glide",            style = "slide" },
    { leaf = "specialWorkspaceIn",  speed = 10,  spring = "drawer",           style = "slidevert" },
    { leaf = "specialWorkspaceOut", speed = 10,  spring = "snap",             style = "slidevert" },
    { leaf = "monitorAdded",        speed = 2,   bezier = "emphasized_decel" },
    { leaf = "borderangle",         speed = 5,   bezier = "standard_decel",   style = "once" },
    { leaf = "zoomFactor",          speed = 3,   bezier = "standard_decel" },
}

for _, animation in ipairs(animations) do
    local spec = {
        leaf = animation.leaf,
        enabled = true,
        speed = animation.speed,
        style = animation.style,
        bezier = animation.bezier,
        spring = animation.spring,
    }
    hl.animation(spec)
end
