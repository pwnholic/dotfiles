# ~/.config/fish/config.fish
#
# Fish startup order:
#   1. ~/.config/fish/conf.d/*.fish   (sourced alphabetically)
#   2. this file                       (config.fish)
#   3. ~/.config/fish/functions/*.fish (lazy-loaded on first use)
#
# This file is intentionally minimal: all environment, PATH and tool setup lives
# in numbered files under conf.d/. There are NO `abbr` and NO `alias`
# anywhere in this config; every convenience command is a plain fish function
# (see conf.d/50-functions.fish and functions/).
#
# See README.md for the full layout and how to add new tools.

source /usr/share/cachyos-fish-config/cachyos-config.fish

starship init fish | source

# Added by codebase-memory-mcp install
fish_add_path /home/pwnholic/.local/bin
