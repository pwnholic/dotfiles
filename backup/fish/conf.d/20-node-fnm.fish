# Node.js version management via fnm.
# Chosen over nvm/volta: fast (Rust), single binary, and first-class fish
# support through `fnm env`. nvm has no native fish support; volta's fish
# support is community-only.
#
# Install:   curl -fsSL https://fnm.vercel.app/install | bash
#   (binary -> ~/.local/share/fnm)   or   cargo install fnm  (-> ~/.cargo/bin)

fish_add_path --path $HOME/.local/share/fnm

# `fnm env` puts the active Node on PATH and registers an auto-switch hook for
# .nvmrc / .node-version. Sourced whenever fnm is installed.
if type -q fnm
    fnm env --use-on-cd --shell fish | source
end
