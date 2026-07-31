# ~/.config/fish/config.fish
#
# Thin entry point. Fish startup order:
#   1. /etc/fish config + vendor files
#   2. ~/.config/fish/conf.d/*.fish   (sourced alphabetically)
#   3. this file                       (config.fish)
#   4. ~/.config/fish/functions/*.fish (lazy-loaded on first use)
#
# The CachyOS base config is sourced first -- it sets the fastfetch greeting,
# the `done` desktop-notification hook, the `!!`/`!$` history bindings and a
# base PATH. starship then takes over the prompt and atuin takes over history.
# Everything else (env vars, per-tool PATH, fzf, gh switching) lives in the
# numbered files under conf.d/, so this file stays minimal.

# CachyOS base: greeting (fastfetch), done notifications, !! / !$, base PATH.
# source /usr/share/cachyos-fish-config/cachyos-config.fish

function fish_greeting
    # do nothing
end

# Prompt + shell history (override the CachyOS defaults).
starship init fish | source

fish_add_path -m ~/.local/share/nvim/mason/bin
fish_add_path -m ~/.foundry/bin

# Added by codebase-memory-mcp install
fish_add_path /home/pwnholic/.local/bin
