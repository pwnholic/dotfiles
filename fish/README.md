# fish shell config

A lean [fish](https://fishshell.com) 4.x configuration on top of the
**CachyOS** default, for a Linux developer working with Rust, Python, Go and
Node.js.

## Stack

| Layer        | Tool                                   | Notes                                          |
| ------------ | -------------------------------------- | ---------------------------------------------- |
| Base         | CachyOS fish config                    | Sourced first: fastfetch greeting, `done` notifications, `!!`/`!$` bindings, base PATH. |
| Prompt       | [starship](https://starship.rs)        | Initialised in `config.fish`. Own config in `~/.config/starship.toml`. |
| History      | [atuin](https://atuin.sh)              | Synced, fuzzy, directory-aware. Config in `~/.config/atuin/config.toml`. |
| Finder       | [fzf](https://github.com/junegunn/fzf) | CTRL-T / CTRL-R / ALT-C, ripgrep + fd + bat.   |

## Folder layout

```
~/.config/fish/
├── config.fish                 # Entry point: sources CachyOS base, starship, atuin.
├── conf.d/                     # Sourced alphabetically on every fish start.
│   ├── 00-env.fish             # $EDITOR, $PAGER, $MANPAGER, defaults.
│   ├── 10-paths.fish           # Generic user bin dirs (~/.local/bin, pi).
│   ├── 20-go.fish              # GOPATH / GOBIN / GOPROXY + bin.
│   ├── 20-node-fnm.fish        # fnm (Node version manager).
│   ├── 20-python-uv.fish       # uv (Python) notes.
│   ├── 20-rust.fish            # rustup / cargo env + bin.
│   ├── 40-fzf.fish             # fzf env + key bindings.
│   └── 60-gh.fish              # Auto-switch `gh` account on cd (personal/work).
├── fish_variables              # Universal vars (only `__done_*` settings).
└── docs/
    └── tools.md                # Per-tool quick reference + notes.
```

`functions/` and `completions/` directories are not used right now -- the
CachyOS base already provides `!!`/`!$` and the `done` hook, so nothing extra
is needed. Tool-provided completions (e.g. from `fnm`, `uv`) can still be
dropped into `~/.config/fish/completions/` and fish will pick them up.

### Why `conf.d/` with number prefixes?

Fish sources every `conf.d/*.fish` file (in alphabetical order) before
`config.fish`. Numbered prefixes give a deterministic order -- environment
before paths, paths before toolchains -- and make each file's intent obvious.

### `fish_add_path --path`

Used everywhere instead of editing `$fish_user_paths`. It prepends to `PATH`
for the current session only (no universal-variable drift), deduplicates, and
**silently skips directories that do not exist yet**, so toolchains that are
not installed yet activate automatically once their directory appears.

## Adding a new tool

1. Create `conf.d/NN-name.fish` (toolchains usually start with `20-`).
2. Set env vars with `set -gx VAR value`.
3. Add binaries with `fish_add_path --path /the/dir`.
4. Put interactive-only setup (key bindings) inside
   `if status is-interactive ... end`.

Example -- adding `bun`:

```fish
# conf.d/20-bun.fish
fish_add_path --path $HOME/.bun/bin
```

## Configured tools

| Tool                    | Status    | Notes                                              |
| ----------------------- | --------- | -------------------------------------------------- |
| ripgrep (`rg`)          | installed | Default fzf file finder (`rg --files`).            |
| fzf                     | installed | Bindings via `fzf --fish`.                         |
| fd                      | installed | Directory finder for ALT-C.                        |
| bat                     | installed | Man pager + fzf preview.                           |
| eza                     | installed | Available as `eza` (no `ls` override).             |
| Neovim (`nvim`)         | installed | `$EDITOR` / `$VISUAL`.                             |
| Rust (rustup, cargo)    | installed | `~/.local/share/cargo/bin` on PATH.                |
| Go                      | installed | GOPATH `~/.local/share/go`, `go/bin` on PATH.      |
| Node (fnm)              | [auto]    | Activates when fnm is installed.                   |
| Python (uv)             | installed | No env needed.                                     |
| git / GitHub CLI (`gh`) | installed | `gh` auto-switches account per directory.          |
| zellij / yazi           | installed | Used directly; no shell wrapper.                   |
| pi coding agent         | installed | `~/.pi/agent/bin` on PATH.                         |

See `docs/tools.md` for install commands and version-specific notes.

## fish_variables

This file holds fish *universal* variables (shared across sessions). It is kept
intentionally tiny -- only the `done` notification plugin's two settings
(`__done_min_cmd_duration`, `__done_notification_urgency_level`).

> **Note:** a previous prompt theme (Pure) left ~70 `pure_*` universal variables
> behind. They are purged from the committed `fish_variables`. Because fish
> synchronises universals across *running* sessions, your already-open shells
> still hold them in memory and may rewrite the local file until you **restart
> them once** (close & reopen terminals, or reboot). They are harmless -- Pure
> is not loaded, starship is -- and disappear entirely after the restart.
