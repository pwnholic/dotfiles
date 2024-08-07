set -x GOPATH "$HOME/Programming/go"
set -x GOBIN "$GOPATH/bin"
set -x NPM "$HOME/.npm/bin"
set -x JUPYTERLAB_DIR "$HOME/.local/share/jupyter/lab"
set -x DOTNET_ROOT "/opt/dotnet"

fish_add_path -a "$GOPATH" "$GOBIN" "$NPM" "$JUPYTERLAB_DIR" "$DOTNET_ROOT"
fish_add_path -a "$HOME/.dotnet/tools"
