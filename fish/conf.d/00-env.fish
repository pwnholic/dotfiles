# General environment: XDG base dirs, editor, pager, and sane defaults.

# XDG Base Directory
# Pin the base dirs explicitly so every tool keeps its config/cache/data
# under ~/.config, ~/.cache, ~/.local/share, ~/.local/state.
# XDG_RUNTIME_DIR is owned by systemd -- never override it here.
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_STATE_HOME $HOME/.local/state

# Editor / pager
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
if type -q bat
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -gx MANROFFOPT "-c"
end
set -gx LESS "-R"          # allow ANSI color escape codes in less
set -gx LESSHISTFILE "-"   # do not write a ~/.lesshst file
set -gx BAT_THEME "TwoDark"

# Neovim runtime
# nvim locates its own runtime by default; pin VIMRUNTIME when the bundled
# runtime exists so tools that read it see a stable path.
if test -d /usr/share/nvim/runtime; and not set -q VIMRUNTIME
    set -gx VIMRUNTIME /usr/share/nvim/runtime
end

# npm
set -gx NPM_CONFIG_FUND false
set -gx npm_config_cache $XDG_CACHE_HOME/npm