fish_add_path -p \
    $HOME/.bin \
    $HOME/.local/bin \
    $HOME/.cargo/bin \
    $HOME/Dev/go/bin \
    $HOME/.foundry/bin \
    $HOME/.local/share/nvim/mason/bin

if test -f $HOME/.envvars
    source $HOME/.envvars
end

if test -f $__fish_config_dir/fish_envvars
    source $__fish_config_dir/fish_envvars
end

if type -q nvim
    set -gx EDITOR nvim
    set -gx MANPAGER 'nvim +Man!'
else if type -q vim
    set -gx EDITOR vim
else if type -q vi
    set -gx EDITOR vi
end

if type -q xhost
    xhost +local:root &>/dev/null
end

set -gx RIPGREP_CONFIG_PATH $HOME/.config/rg/ripgreprc
set -gx GOPATH "$HOME/Dev/go"
set -gx GOBIN "$GOPATH/bin"
set -gx NPM "$HOME/.npm/bin"
set -gx ELECTRON_OZONE_PLATFORM_HINT auto
set -gx RIPGREP_CONFIG_PATH ""
set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
