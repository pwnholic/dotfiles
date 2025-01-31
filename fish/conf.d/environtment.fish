set -x GOPATH "$HOME/Dev/go"
set -x GOBIN "$GOPATH/bin"
set -x NPM "$HOME/.npm/bin"
set -x ELECTRON_OZONE_PLATFORM_HINT auto
set -x RIPGREP_CONFIG_PATH "$HOME/.config/rg/ripgreprc"
set -x STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"

fish_add_path -a "$GOPATH" "$GOBIN" "$NPM" "$ELECTRON_OZONE_PLATFORM_HINT" "$RIPGREP_CONFIG_PATH" "$STARSHIP_CONFIG"
fish_add_path -a ~/.foundry/bin
