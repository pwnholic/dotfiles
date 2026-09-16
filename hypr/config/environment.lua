-- Environment owned by the Hyprland compositor.
-- Session-wide variables and AQ_DRM_DEVICES are defined in ~/.config/uwsm/env.

-- Both active outputs are currently driven by the Intel iGPU. Keep normal
-- applications on it; use prime-run when an application needs NVIDIA offload.
hl.env("HYPRCURSOR_SIZE", "24")
