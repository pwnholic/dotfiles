# Go toolchain (system go at /usr/bin/go).

set -gx GOPATH $HOME/.local/share/go
set -gx GOBIN $GOPATH/bin
set -gx GOPROXY https://proxy.golang.org,direct

# Put `go install`ed binaries on PATH.
fish_add_path --path $GOBIN
