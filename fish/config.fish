source /usr/share/cachyos-fish-config/cachyos-config.fish

function fish_greeting
    # smth smth
end

# Pi
fish_add_path "$HOME/.local/bin"

# Git SSH: pakai agent systemd (socket shared semua terminal)
set -x SSH_AUTH_SOCK /run/user/1000/ssh-agent.socket

if status is-interactive
    direnv hook fish | source

    set -gx ATUIN_NOBIND true
    atuin init fish | source

    starship init fish | source
end
