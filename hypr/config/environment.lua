-- Environmental variables.
-- Wiki: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-Variables/
-- Session is launched via the "Hyprland (uwsm-managed)" entry
-- (hyprland-uwsm.desktop): uwsm sources ~/.config/uwsm/env for session-wide
-- vars (BROWSER, QT theme, cursor, ...). GPU/NVIDIA vars are defined HERE
-- via hl.env() — keep them here, NOT in uwsm/env (avoids double-set; this
-- is the more up-to-date source per the Nvidia/Hyprland wiki).

-- NVIDIA GPU (per https://wiki.hypr.land/Nvidia/)
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia") -- OpenGL vendor -> NVIDIA
hl.env("LIBVA_DRIVER_NAME", "nvidia") -- Hardware video acceleration (VA-API)
hl.env("NVD_BACKEND", "direct") -- VA-API direct backend
-- (GBM_BACKEND & __GL_GSYNC_ALLOWED no longer recommended on modern drivers per Nvidia wiki)

-- Hybrid GPU: Intel iGPU primary renderer (battery), NVIDIA dGPU included for external HDMI
-- Symlinks created by /etc/udev/rules.d/99-hypr-gpu-symlinks.rules (colon-free, per Multi-GPU wiki)
hl.env("AQ_DRM_DEVICES", "/dev/dri/intel-igpu:/dev/dri/nvidia-dgpu")

hl.env("HYPRCURSOR_SIZE", "20")
