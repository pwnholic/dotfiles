local S = require("config.settings")

hl.window_rule({ match = { float = true }, center = true, persistent_size = true })

hl.window_rule({
    match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float = true,
    keep_aspect_ratio = true,
    size = { "max(monitor_w, monitor_h)*0.25", "min(monitor_w, monitor_h)*0.25" },
    pin = true,
})

hl.window_rule({ match = { class = "^(vesktop|discord)$" }, monitor = S.monitors.primary })
hl.window_rule({
    match = { class = "^(.*[Cc]alc.*)$" },
    float = true,
    size = { "max(monitor_w, monitor_h)*0.17", "min(monitor_w, monitor_h)*0.43" },
})
hl.window_rule({ match = { class = "^(org\\.kde\\.keditfiletype)$" }, float = true })
hl.window_rule({
    match = { class = "^(org\\.kde\\.ark)$" },
    size = { "max(monitor_w, monitor_h)*0.40", "min(monitor_w, monitor_h)*0.40" },
})
hl.window_rule({
    match = { class = "^(.*satty.*)$", title = "^(Satty)$" },
    min_size = { "max(monitor_w, monitor_h)*0.35", "min(monitor_w, monitor_h)*0.35" },
    float = true,
})
hl.window_rule({
    match = { class = "^(dev\\.)?(noctalia\\.Noctalia(\\.Settings)?)$" },
    float = true,
    size = { "monitor_w*0.70", "monitor_h*0.70" },
})

hl.window_rule({
    match = {
        class = "^(firefox|zen|brave-browser|Brave-browser|spotify|com\\.spotify\\.Client|discord|vesktop|"
            .. "org\\.telegram\\.desktop(\\.desktop)?|md\\.obsidian\\.Obsidian|"
            .. "dev\\.zed\\.Zed|codium|tabularis|zennotes|org\\.gnome\\.Nautilus|"
            .. "org\\.gnome\\.TextEditor|org\\.gnome\\.Meld|"
            .. S.classes.terminals
            .. "|mpv|org\\.kde\\.haruna|.*plex.*|org\\.kde\\.gwenview|.*vlc.*)$",
    },
    opacity = "1.0 override",
})

local utility_windows = {
    "^(gnome-calculator|org\\.gnome\\.Calculator)$",
    "^(pavucontrol|org\\.pulseaudio\\.pavucontrol|pwvucontrol|easyeffects)$",
    "^(qt6ct|nwg-look|font-manager|font-viewer)$",
    "^(nvidia-settings|cachyos-pi|org\\.cachyos\\.hello|org\\.cachyos\\.KernelManager|org\\.cachyos\\.scx-manager|btrfs-assistant)$",
    "^(qv4l2|qvidcap|hushmic)$",
}
for _, class in ipairs(utility_windows) do
    hl.window_rule({ match = { class = class }, float = true, center = true })
end

hl.window_rule({
    match = { class = "^(pinentry.*|Gcr-prompter|gcr-prompter)$" },
    float = true,
    stay_focused = true,
    dim_around = true,
})

local floating = {
    { class = "^(kvantummanager|qt[56]ct|nwg-look)$" },
    { class = "^(org\\.pulseaudio\\.pavucontrol|blueman-manager|nm-applet|nm-connection-editor)$" },
    { title = "^(Winetricks.*|Protontricks.*)$" },
    { title = "^(Open|Authentication Required|Add Folder to Workspace|Choose Files|Save As|Confirm to replace files|File Operation Progress)$" },
    { initial_title = "^(Open File)$" },
    { class = "^([Xx]dg-desktop-portal-gtk)$" },
    { title = "^(Enter name of file to save to.*|Save As.*|Open File.*)$" },
    { class = "^(.*dialog.*)$" },
    { title = "^(.*dialog.*)$" },
    { class = "^(hyprland-share-picker)$" },
}
for _, match in ipairs(floating) do
    hl.window_rule({ match = match, float = true })
end

hl.window_rule({
    match = { class = "^([Xx]dg-desktop-portal-gtk)$" },
    float = true,
    center = true,
    size = { "max(monitor_w, monitor_h)*0.60", "max(monitor_w, monitor_h)*0.40" },
})

hl.window_rule({ match = { class = "^(com\\.obsproject\\.Studio)$" }, monitor = S.monitors.primary })
hl.window_rule({
    match = { class = "^(com\\.obsproject\\.Studio)$", title = "^(.*)[Pp]rojector(.*)$" },
    float = true,
})

for _, class in ipairs({
    "md\\.obsidian\\.Obsidian",
    "org\\.telegram\\.desktop(\\.desktop)?",
    "discord",
    "vesktop",
}) do
    hl.window_rule({ match = { class = "^" .. class .. "$" }, no_screen_share = true })
end

hl.window_rule({ match = { class = "^(gpu-screen-recorder.*)$" }, no_focus = true })
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.layer_rule({
    name = "noctalia-solid",
    match = {
        namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
    },
    no_anim = true,
    ignore_alpha = 0.5,
})
