# Tools reference

Per-tool setup notes, install commands, and version-specific decisions.

## Base shell: CachyOS fish config

The system package `cachyos-fish-config` provides `/usr/share/cachyos-fish-config/cachyos-config.fish`,
sourced from `config.fish`. It sets up:

- `fish_greeting` -> `fastfetch` system summary.
- the [`done`](https://github.com/franciscolourenco/done) hook (desktop
  notification when a long command finishes), configured via the
  `__done_*` universal variables in `fish_variables`.
- bash-style `!!` / `!$` history bindings.
- `MANPAGER` / `MANROFFOPT` (bat-rendered man pages).
- a base PATH (`~/.local/bin`, `~/.cargo/bin`, ...).

We deliberately do **not** duplicate any of this in `conf.d/`.

## starship (prompt)

Source: <https://starship.rs>

Initialised in `config.fish` with `starship init fish | source`, replacing the
CachyOS default prompt. Its own configuration lives at
`~/.config/starship.toml` (not part of this fish config).

## atuin (shell history)

Source: <https://docs.atuin.sh>

Initialised in `config.fish` with `atuin init fish | source`. Configured in
`~/.config/atuin/config.toml`. Highlights of the chosen setup:

- **Ctrl-R** searches the full global history (every machine); **Up arrow**
  searches only commands run in the *current directory* (`filter_mode_shell_up_key_binding = "directory"`).
- `workspaces = true` -- inside a git repo, up-arrow matches commands run
  anywhere under that repo.
- `search_mode = "fuzzy"`, `inline_height = 40`, `enter_accept = true`,
  `secrets_filter = true` (never saves things that look like tokens).
- The history UI shows `duration | directory | command` (`[ui] columns`).

Log in to enable sync across machines:

```sh
atuin login -u <username>
```

Or self-host by setting `sync_address` in the config.

## ripgrep / fd / bat / eza

System packages, no env needed:

- **ripgrep** -- fzf default + CTRL-T finder (`rg --files --hidden --glob "!.git/*"`).
- **fd** -- fzf ALT-C directory finder (`fd --type d --hidden --follow --exclude .git`).
- **bat** -- man renderer and fzf preview (`bat -n --color=always {}`). Theme: `TwoDay`.
- **eza** -- modern `ls`. Available as `eza` directly; `ls` is **not** overridden.

## fzf (0.74)

Source: <https://junegunn.github.io/fzf/shell-integration/>

Uses the modern, officially-recommended **`fzf --fish | source`** (fzf >= 0.48),
which registers CTRL-T (files), CTRL-R (history) and ALT-C (cd into dir). In
the file preview, CTRL-/ toggles the preview window.

> Note: atuin also binds CTRL-R. atuin is initialised *after* fzf in
> `config.fish`, so **CTRL-R opens atuin** (the richer, synced history search),
> while fzf's bindings (CTRL-T, ALT-C) remain available. This is the intended
> setup; if you ever want fzf's CTRL-R back, initialise fzf after atuin.

## Neovim

`$EDITOR` and `$VISUAL` are both `nvim` (set in `conf.d/00-env.fish`).

## Rust (rustup / cargo)

`RUSTUP_HOME` and `CARGO_HOME` are set explicitly to their defaults
(`~/.local/share/rustup`, `~/.local/share/cargo`) -- fish does not source
rustup's `profile.d` snippet. `~/.local/share/cargo/bin` is on PATH.

## Go

`GOPATH=~/.local/share/go`, `GOBIN=$GOPATH/bin`,
`GOPROXY=https://proxy.golang.org,direct`. `$GOBIN` is added to PATH the moment
it exists (after the first `go install`).

## Node.js -- fnm

Source: <https://github.com/Schniz/fnm> (Shell Setup > Fish)

Chosen over nvm/volta: nvm has no native fish support; volta's fish support is
community-only. fnm is Rust-based, fast, and first-class for fish.

Install:

```sh
curl -fsSL https://fnm.vercel.app/install | bash
# or: cargo install fnm
```

`fnm env --use-on-cd --shell fish` puts the active Node on PATH and
auto-switches version on `cd` into a `.nvmrc` / `.node-version`. Until fnm is
installed, the system Node (`/usr/bin/node`) is used as-is.

## Python -- uv

`uv` (system package) replaces pyenv + pipx + venv in one tool, including
Python version management (`uv python install <version>`). No env required.
Uncomment `UV_PYTHON_PREFERENCE managed` in `conf.d/20-python-uv.fish` to prefer
uv-managed interpreters over the system one.

## zellij / yazi

Both are system packages and need no shell environment.

- **zellij** is a terminal multiplexer with its own config (`~/.config/zellij/`).
- **yazi** is used directly (`yazi`); there is no `y` cd-on-exit wrapper here.
  To add the official wrapper, see
  <https://yazi-rs.github.io/docs/quick-start#shell-wrapper> and drop a
  `functions/y.fish` file.

## git / GitHub CLI

git is a system package. `gh` (`sudo pacman -S github-cli`) lands in `/usr/bin`
and needs no extra PATH entry.

`conf.d/60-gh.fish` auto-switches the active `gh` account based on the current
directory: `pwnholic` everywhere except under `~/Projects/work`, which uses the
work account. This mirrors the `git includeIf` split.

## pi coding agent

`pi` lives at `~/.pi/agent/bin` (on PATH via `conf.d/10-paths.fish`).
Claude Code installs to `~/.local/bin` (already on PATH); no extra setup.
