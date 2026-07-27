# fish shell config

A clean, from-scratch [fish](https://fishshell.com) 4.x configuration for a
Linux (CachyOS) developer working with TypeScript, Rust, Python and Go, with
Solana / Anchor tooling and an NVIDIA GPU for compute.

Design principles:

- **No `abbr`, no `alias`.** Every convenience command is a plain fish
  **function**. Fish's `alias` builtin is itself just a wrapper around a
  function, so functions are used directly here.
- **Comments are in English** throughout the config.
- **Modular by concern.** Everything is split into small numbered files under
  `conf.d/`, each self-contained, so adding or removing a tool touches one file.

---

## Folder layout

```
~/.config/fish/
├── config.fish                 # Thin entry point. Documents the startup order.
├── conf.d/                     # Sourced alphabetically on every fish start.
│   ├── 00-env.fish             # $EDITOR, $PAGER, $MANPAGER, defaults.
│   ├── 10-paths.fish           # Generic user bin dirs (~/.local/bin, pi).
│   ├── 20-rust.fish            # rustup / cargo env + bin.
│   ├── 20-go.fish              # GOPATH / GOBIN / GOPROXY + bin.
│   ├── 20-node-fnm.fish        # fnm (Node version manager) integration.
│   ├── 20-solana.fish          # Solana CLI + Anchor (avm) PATH.
│   ├── 20-python-uv.fish       # uv (Python) notes.
│   ├── 30-nvidia.fish          # CUDA toolkit env (guarded on /opt/cuda).
│   ├── 40-fzf.fish             # fzf env + key bindings (CTRL-T/R, ALT-C).
│   ├── 45-bang-bang.fish       # Optional `!!` / `!$` history expansion.
│   └── 50-functions.fish       # Convenience functions (ls/eza, .., mkcd).
├── functions/                  # Autoloaded on first use.
│   ├── fish_prompt.fish        # Custom prompt (cwd + git + status char).
│   ├── fish_right_prompt.fish  # vi-mode indicator (only with vi bindings).
│   ├── fish_greeting.fish      # Empty by default (fast startup).
│   └── y.fish                  # yazi "cd on exit" wrapper.
├── completions/                # Tool-provided completions land here.
└── docs/
    └── tools.md                # Per-tool quick reference + version notes.
```

### Why `conf.d/` with number prefixes?

Fish sources every `conf.d/*.fish` file (in collated/alphabetical order) before
`config.fish`. Numbered prefixes give a deterministic order (environment before
paths, paths before toolchains) and make the intent of each file obvious at a
glance.

### `fish_add_path --path`

Used everywhere instead of editing `$fish_user_paths`. It prepends to `PATH`
for the current session only (no universal-variable drift), deduplicates, and
**silently skips directories that do not exist yet**. That means toolchains
that are not installed yet are picked up automatically the moment their install
directory appears — no edits needed.

---

## Adding a new tool or environment variable

1. Create `conf.d/NN-name.fish` (pick a number that sorts it after its
   dependencies; toolchains usually start with `20-`).
2. Set environment variables with `set -gx VAR value`.
3. Add binaries with `fish_add_path --path /the/dir` (no `test -d` guard needed).
4. Put interactive-only setup (key bindings, prompt hooks) inside
   `if status is-interactive ... end`.
5. If the tool needs a command wrapper, add a `functions/<name>.fish` file.

Example — adding `bun`:

```fish
# conf.d/20-bun.fish
fish_add_path --path $HOME/.bun/bin
```

---

## Configured tools

Legend: **[installed]** present on this machine · **[auto]** not installed yet;
will activate automatically once its directory/command appears.

| Tool                    | Status                        | Notes                                              |
| ----------------------- | ----------------------------- | -------------------------------------------------- |
| ripgrep (`rg`)          | installed                     | Default fzf file finder (`rg --files`).            |
| fzf                     | installed                     | Bindings via `fzf --fish` (CTRL-T, CTRL-R, ALT-C). |
| fd                      | installed                     | Directory finder for ALT-C.                        |
| bat                     | installed                     | Man pager + fzf file preview.                      |
| eza                     | installed                     | Powers the `ls`/`ll`/`la`/`lt` functions.          |
| git / GitHub CLI (`gh`) | git installed · **gh [auto]** | `gh` added to PATH once installed.                 |
| Neovim (`nvim`)         | installed                     | `$EDITOR` and `$VISUAL`.                           |
| Rust (rustup, cargo)    | installed                     | `~/.cargo/bin` on PATH.                            |
| Go                      | installed                     | GOPATH `~/go`, `~/go/bin` on PATH (auto).          |
| Node (fnm)              | **[auto]**                    | `fnm env --use-on-cd` when fnm is installed.       |
| Python (uv)             | installed                     | No env needed; uv manages versions/venvs.          |
| Solana CLI              | **[auto]**                    | `~/.local/share/solana/.../bin` on PATH.           |
| Anchor (avm)            | **[auto]**                    | `~/.avm/bin` on PATH; `avm` via cargo.             |
| zellij                  | **[auto]**                    | No env required; see `docs/tools.md`.              |
| yazi                    | **[auto]**                    | `y` wrapper (cd on exit).                          |
| pi coding agent         | installed                     | `~/.pi/agent/bin` on PATH.                         |
| Claude Code (`claude`)  | **[auto]**                    | Lands in `~/.local/bin` (already on PATH).         |
| NVIDIA CUDA             | **[auto]**                    | Env set when `/opt/cuda` exists.                   |

See `docs/tools.md` for install commands, usage and the version-specific
decisions (with sources).

---

## Convenience functions (no aliases)

Defined in `conf.d/50-functions.fish` and `functions/`. All are interactive-only
and use real binaries via `command`/`builtin` where it matters.

| Function                  | Does                                                |
| ------------------------- | --------------------------------------------------- |
| `ls` / `ll` / `la` / `lt` | eza listings (dirs-first, auto icons).              |
| `..` / `...` / `....`     | cd up 1 / 2 / 3 levels.                             |
| `mkcd <dir>`              | `mkdir -p` then cd into it.                         |
| `y`                       | yazi with "cd into the exited directory".           |
| `!!` / `!$` (keys)        | bash-style last-command / last-argument (optional). |

To use the real `ls` binary instead of the eza wrapper, run `command ls`.

---

## Prompt

Custom, dependency-free prompt in `functions/fish_prompt.fish`:

- Line 1: working directory (blue) + git branch/status (`fish_git_prompt`).
- Line 2: `>` green if the last command succeeded, red otherwise.

The right prompt shows a vi-mode indicator only when `fish_vi_key_bindings` is
enabled (it is **off** by default; to enable it add
`set -g fish_key_bindings fish_vi_key_bindings` to `config.fish`).

To switch to [starship](https://starship.rs) instead, install it and add
`starship init fish | source` to `config.fish`, then delete
`functions/fish_prompt.fish`.

---

## Restore the old config

The previous config was backed up before this rebuild:

```
~/.config/fish.backup-<timestamp>.tar.gz
```

Restore with:

```sh
rm -rf ~/.config/fish
mkdir -p ~/.config
tar -xzf ~/.config/fish.backup-*.tar.gz -C ~/.config
```
