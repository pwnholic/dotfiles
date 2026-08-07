# ~/.config/fish/config.fish
#
# Thin entry point. Fish startup order (fish 4.x):
#   1. /etc/fish config + vendor files
#   2. ~/.config/fish/conf.d/*.fish   (sourced alphabetically)
#   3. this file                       (config.fish)
#   4. ~/.config/fish/functions/*.fish (autoloaded on first use)
#
# Everything environment/path/tool related lives in the numbered files under
# conf.d/; lazy-loaded functions live in functions/. This file only wires up
# the prompt.

# Starship prompt (replaces the default fish prompt).
starship init fish | source

# The default greeting is suppressed via functions/fish_greeting.fish.

# Vigolium CLI
export PATH="/home/pwnholic/.local/bin:$PATH"
