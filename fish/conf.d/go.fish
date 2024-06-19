set -x GOPATH "$HOME/Programming/go"
set -x GOBIN "$GOPATH/bin"

fish_add_path -m -p -g "$GOPATH" "$GOBIN"
