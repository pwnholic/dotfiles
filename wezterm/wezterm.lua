local wezterm = require('wezterm')
local config = wezterm.config_builder and wezterm.config_builder() or {}
local config_dir = wezterm.config_dir

config.automatically_reload_config = true
config.animation_fps = 1 -- Disable cursor blinking easing animation
config.color_scheme_dirs = { config_dir .. '/colors' }
-- config.color_scheme = 'Dragon Dark' -- Default colorscheme
config.check_for_updates = false
config.enable_tab_bar = false

config.font = wezterm.font_with_fallback({
  { family = 'Iosevka Nerd Font', weight = 'Medium' },
  { family = 'Symbols Nerd Font Mono' },
})

config.font_size = 11
config.initial_rows = 24
config.initial_cols = 112
config.term = 'wezterm'
config.window_padding = {
  left = '1cell',
  right = '1cell',
  top = '0.5cell',
  bottom = '0.5cell',
}

return config
