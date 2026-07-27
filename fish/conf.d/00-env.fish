# General environment variables: editor, pager, and sane defaults.

# Editor / visual (heavy Neovim user).
set -gx EDITOR nvim
set -gx VISUAL nvim

# Pager: keep `less` for general paging, render man pages with bat when it
# is installed; otherwise man falls back to its default pager.
set -gx PAGER less
if type -q bat
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -gx MANROFFOPT "-c"
end
set -gx LESS "-R"          # allow ANSI color escape codes in less
set -gx LESSHISTFILE "-"   # do not write a ~/.lesshst file

# Default theme for bat.
set -gx BAT_THEME "TwoDark"

# Quieter npm output.
set -gx NPM_CONFIG_FUND false
