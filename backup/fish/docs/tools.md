# Tools reference

Per-tool setup notes, install commands, and the version-specific decisions
behind this config. Sources are linked inline.

## ripgrep / fd / bat / eza

System packages, no env needed. Used as:

- **ripgrep** — default fzf file finder: `rg --files --hidden --glob "!.git/*"`.
- **fd** — fzf directory finder for ALT-C: `fd --type d ...`.
- **bat** — man-page renderer and fzf preview (`bat -n --color=always {}`).
- **eza** — powers the `ls`/`ll`/`la`/`lt` functions. Icons require a Nerd Font.

## fzf (0.74)

Source: <https://junegunn.github.io/fzf/shell-integration/>

- Bindings use the modern, officially-recommended **`fzf --fish | source`**
  (available since fzf 0.48). This replaces the older
  `source /usr/share/fish/vendor_functions.d/fzf_key_bindings.fish` +
  `fzf_key_bindings` approach, which is still installed as a vendor file but is
  now superseded.
- Bindings: **CTRL-T** (files), **CTRL-R** (history), **ALT-C** (cd into dir).
  In the file preview, **CTRL-/** toggles/hides the preview window.
- `FZF_DEFAULT_COMMAND` / `FZF_CTRL_T_COMMAND` use ripgrep; `FZF_ALT_C_COMMAND`
  uses fd. (Modern fzf also has a built-in `--walker`; explicit commands are
  used here so the "ripgrep as default finder" requirement is explicit.)

## Neovim

`$EDITOR` and `$VISUAL` are both `nvim` (set in `conf.d/00-env.fish`).

## Rust (rustup / cargo)

`RUSTUP_HOME` and `CARGO_HOME` are set to their defaults explicitly (fish does
not source rustup's `profile.d` snippet). `~/.cargo/bin` is on PATH.

## Go

`GOPATH=~/go`, `GOBIN=~/go/bin`, `GOPROXY=https://proxy.golang.org,direct`.
`~/go/bin` is added to PATH the moment it exists (after the first
`go install`).

## Node.js — fnm

Source: <https://github.com/Schniz/fnm> (Shell Setup > Fish)

Chosen over nvm/volta: nvm has no native fish support (needs `bass`/a fork);
volta's fish support is community-only. fnm is Rust-based, fast, and has a
first-class fish integration.

Install:

```sh
curl -fsSL https://fnm.vercel.app/install | bash
# or: cargo install fnm
```

The config sources `fnm env --use-on-cd --shell fish`, which:

- puts the active Node version on PATH, and
- auto-switches Node version on cd when a `.nvmrc` / `.node-version` is present.

Until fnm is installed, the system Node (`/usr/bin/node`) is used as-is.

## Python — uv

`uv` (already a system package) replaces pyenv + pipx + venv in one tool,
including Python version management (`uv python install <version>`). No env is
required. Uncomment `UV_PYTHON_PREFERENCE managed` in
`conf.d/20-python-uv.fish` to prefer uv-managed interpreters over the system
one.

## Solana CLI / Anchor (avm)

Sources:

- Solana: <https://docs.anza.xyz/cli/install-solana-cli> (install command +
  `~/.local/share/solana/install/active_release/bin` path).
- Anchor/AVM: <https://www.anchor-lang.com/docs/references/avm>
  (default data dir `~/.avm`, shim at `~/.avm/bin`).

Install:

```sh
# Solana CLI (Agave)
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"

# Anchor via AVM
cargo install --git https://github.com/coral-xyz/anchor avm --force
avm install <version>
avm use <version>
```

Both PATH entries (`~/.local/share/solana/.../bin` and `~/.avm/bin`) are
no-ops until the install dirs exist.

## yazi

Source: <https://yazi-rs.github.io/docs/quick-start#shell-wrapper> (Fish tab).

`functions/y.fish` is the **official** yazi shell wrapper verbatim (plus a
guard if yazi is missing). Use `y` instead of `yazi` so that quitting (q) drops
you into the directory yazi was in; press **Q** to quit without moving.

Install: `sudo pacman -S yazi`.

## zellij

No shell environment is required — it is a terminal multiplexer with its own
config (`~/.config/zellij/`). To auto-attach zellij when opening a terminal,
add to `config.fish`:

```fish
if status is-interactive; and not set -q ZELLIJ; and type -q zellij
    zellij attach --create
end
```

(Omitted by default because it changes terminal workflow significantly.)

## git / GitHub CLI

git is a system package. `gh`, once installed (`sudo pacman -S github-cli`),
lands in `/usr/bin` and needs no extra PATH entry.

Generate fish completions for cargo-installed CLIs (fnm, uv already ship
theirs via the package):

```sh
fnm completions --shell fish > ~/.config/fish/completions/fnm.fish   # if installed via cargo
```

## pi & Claude coding agents

- pi is at `~/.pi/agent/bin` (on PATH via `conf.d/10-paths.fish`).
- Claude Code installs to `~/.local/bin` (the native installer) which is
  already on PATH; no extra setup.

## NVIDIA / CUDA (development)

Source: <https://wiki.archlinux.org/title/GPGPU#CUDA>

The Arch `cuda` package installs to `/opt/cuda` and normally exports PATH /
`LD_LIBRARY_PATH` through `/etc/profile.d/cuda.sh`. **Fish does not source
`/etc/profile.d/*.sh`**, so those exports never apply — `conf.d/30-nvidia.fish`
sets the equivalent variables itself (`CUDA_HOME`, `CUDA_PATH`, PATH, and
`LD_LIBRARY_PATH` for `lib64` + CUPTI), guarded on `/opt/cuda` existing.

Install the toolkit:

```sh
sudo pacman -S cuda
```

Note: this machine has an **RTX 5050 Laptop GPU** (Blackwell, compute capability
`sm_120`). Blackwell requires **CUDA >= 12.8**; the installed driver
(610.x) supports current CUDA releases. Verify with `nvcc --version` after
install.
