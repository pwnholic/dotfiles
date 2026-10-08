# Neovim 0.12+ configuration

A native, modular, data-driven Neovim configuration. Plugins are managed with
**`vim.pack()`** (no third-party plugin manager) and only *policy* lives in the
configuration: infrastructure is a thin orchestration layer on top of official
Neovim APIs.

```
~/.config/nvim
├── init.lua                  # declarative entry point (re-sourced by :ConfigReload)
├── stylua.toml / selene.toml / vim.yml     # format/lint configuration
├── .luarc.json               # lua-language-server: LuaJIT, runtime+uv libraries, format off
├── types/neovim.lua          # @meta stub for the runtime surface used (see "Static checks")
├── lua/
│   ├── core/                 # configuration + system behaviour (see below)
│   ├── config/health.lua     # `:checkhealth config` entry point
│   ├── lib/                  # reusable mechanisms (registry, cache, fs, process, json, lifecycle, util, report)
│   └── plugins/              # plugin-specific configuration only
├── tests/                    # headless test suite (tests/run.sh)
└── nvim-pack-lock.json       # native vim.pack lockfile (do not edit by hand)
```

## Layers and boundaries

* **`lua/core/`** owns editor behaviour: options, keymaps, autocommands, user
  commands, highlights, project root detection, toggles, terminals, formatting
  *policy*, LSP helpers, health checks, notifications, `vim.pack` orchestration,
  the configuration watcher and soft reload.
* **`lua/lib/`** owns reusable mechanisms only. A module belongs here when it is
  genuinely shared (`lib.registry` is used by toggles, root strategies,
  formatters, tools, LSP hints and plugin specs).
* **`lua/plugins/`** owns plugin-specific configuration: it declares specs and
  registers plugin-provided extensions through `core.*` registries. Nothing in
  `core/` knows about individual plugins.

Module setup order (`lua/core/init.lua`) is explicit:

```
notify → options → highlights → autocmds → tools → keymaps → commands → root
→ toggle → terminal → format → lsp → plugins (declarations) → pack (loading)
→ reload (watcher, last)
```

Each module owns its resources through `lib.lifecycle`, which is what makes
`:ConfigReload` duplicate-free (autocommands, mappings, commands, timers,
watchers are torn down exactly).

## Configuration and precedence

Highest wins:

1. core defaults — `lua/core/defaults.lua` (single source of truth)
2. `lua/core/user.lua` — optional, user-owned overrides (return a table)
3. `require('core').setup{ ... }` — overrides passed from `init.lua`
4. plugin extensions — registries (`toggle`, `root`, `format`, `lsp`, `pack`, `tools`)
5. runtime state — toggles, buffer-local gates, terminal slots, caches

Examples:

```lua
-- lua/core/user.lua
return {
    leader = ",",
    terminal = { slots = 4, width = 0.9, sync_cwd = true },
    toggles = { keys = { diagnostics = "<leader>ux" } },
    pack = { update = { interval_days = 14 } },
    reload = { auto_reload = true, auto_restart = false },
}
```

```lua
-- lua/core/defaults.lua (excerpt of the interesting keys)
winborder              -- border of every floating window (single source; plugins inherit it)
indent                 -- enforced indent (width 4, expandtab) + tabs-only filetypes
blink_pairs            -- auto-pairs: enabled, mappings, highlights, matchparen
blink_indent           -- indent guides: enabled, static, scope, underline, char
git                    -- statusline icons + sign-column chars + place_signs
ui.statuscolumn        -- left/right layout, folds_open, mark_hl, fold_hl, git_patterns
ui_clue                -- mini.clue window delay (mini.clue default is 1000 ms)
blink                  -- completion: enabled, load_early_for_lsp, documentation_auto_show
mason                  -- LSP tool installer: enabled, UI border
picker                 -- fzf-lua: enabled, use_project_root, keymaps
ui.statusline          -- statusline sections (false hides one) + icons
ui.statuscolumn        -- sign/fold/number column: dim, separator, virt/wrap glyphs
root.default_spec      -- ordered strategy list (also settable via vim.g.root_spec)
toggles.defaults/keys  -- initial toggle state and <leader>u* mappings
terminal.*             -- shell, slots, float geometry, sync_cwd, keys
format.*               -- global gate default, format-on-save, timeout
lsp.servers            -- declarative server configs
pack.*                 -- confirm_install, plugins, update.{auto_check,interval_days}
reload.*               -- watch, debounce, auto_reload, auto_restart, ignore
```

## Commands

| Command | Purpose |
| --- | --- |
| `:Root [bufnr]` | Root inspector: resolved root, strategy, marker, cache state, evaluated strategies |
| `:RootClear` | Clear the root cache |
| `:Format` | Format buffer / selection / `[count]` line (`:1,9Format`) |
| `:FormatInfo` | Formatting gates, provider and formatter availability |
| `:LspLog` | Open the Neovim LSP log (tail) |
| `:LspInfo` | Active clients, capabilities, server/binary status, command hints |
| `:LspExec [server] <command> [json]` | Run an LSP command; without arguments an interactive picker is used (shows the command's parameter hint) |
| `:Terminal [n\|next\|close\|info]` | Toggle a terminal slot / hide all / inspect |
| `:Lazygit [root\|cwd]` | Floating lazygit in the project root or cwd |
| `:Toggles [id]` | Toggle inspector (`<CR>` flips the toggle on the line) |
| `:PackInstall [names]` | Install declared plugins without loading them |
| `:PackUpdate` | Native `vim.pack.update()`: fetch, review buffer, `:write` applies, `:quit` discards |
| `:PackCheck` | Update check only (never changes plugin state) |
| `:PackStatus` | Declared plugins, load state, triggers, last update check |
| `:ConfigReload` | Soft reload (re-sources `init.lua`, duplicate-free) |
| `:ConfigWatch [on\|off\|status]` | Control the configuration watcher |
| `:checkhealth config` | Tool/formatter/LSP/parser/pack state |

## Default keymaps

| Keys | Action |
| --- | --- |
| `<Esc>` | Clear search highlight |
| `<C-h/j/k/l>` | Window navigation (normal + terminal mode) |
| `<C-\>` | Toggle terminal slot 1 |
| `<leader>t1..t3` | Toggle terminal slot *N* |
| `<leader>tq` | Hide terminals |
| `<leader>gg` / `<leader>gG` | lazygit at the project root / at cwd |
| `<leader>ud` | Diagnostics |
| `<leader>uh` | Inlay hints (buffer) |
| `<leader>uf` / `<leader>uF` | Autoformat global / buffer gate |
| `<leader>us` | Spell (window) |
| `<leader>uw` | Wrap (window) |
| `<leader>ur` / `<leader>un` | Relative numbers / line numbers (window) |
| `<leader>uc` | Cursor word highlight (buffer) |
| `<leader>ut` | Treesitter context |
| `-` (oil) | Open parent directory (loaded lazily by oil) |
| `<leader>ff` / `fg` / `fw` | fzf-lua: files / live grep / grep word (root-aware, `fw` also visual) |
| `<leader>fb` / `fr` / `fd` / `fs` | fzf-lua: buffers / resume / buffer diagnostics / document symbols |
| `<leader>fh` / `fk` | fzf-lua: help tags / keymaps |
| `<leader>gc` / `gb` / `gs` | fzf-lua: git commits / branches / status |
| `<leader>cm` / `<leader>cM` | mason: package UI / install a missing LSP server (picker) |

Neovim 0.11+ default LSP mappings (`grn`, `gra`, `grr`, `gri`, `grt`, `gO`, …)
and the default diagnostic mappings are intentionally **not** overridden.

## Registers, registries and extension points

Everything below is data; no core file needs to be edited.

```lua
-- Add a toggle (core.toggle)
require('core.toggle').register({
    id = 'list', label = 'List chars', scope = 'window',
    get = function(ctx) return vim.wo[ctx.winid].list end,
    set = function(value, ctx) vim.wo[ctx.winid].list = value end,
})

-- Provide the implementation for a toggle you own (plugins do this)
require('core.toggle').attach('cursorword', {
    get = function(ctx) return not vim.b[ctx.bufnr].minicursorword_disable end,
    set = function(value, ctx) vim.b[ctx.bufnr].minicursorword_disable = not value end,
})

-- Add a root strategy (core.root); kinds are extensible too
require('core.root').register_strategy({ id = 'cargo', kind = 'marker', markers = { 'Cargo.toml' }, priority = 95 })
require('core.root').register_kind('env', { run = function(ctx, def) return os.getenv(def.var) end })
-- ...or declaratively, without requiring anything:
vim.g.root_spec = { '.git', { kind = 'lsp', priority = 80 }, { kind = 'cwd' } }

-- Register a formatter + filetype mapping (core.format)
require('core.format').register_formatter({ id = 'nixfmt', cmd = 'nixfmt', notes = 'Nix' })
require('core.format').set_filetype_formatters('nix', { 'nixfmt' })

-- LSP command hints for :LspExec (core.lsp). LSP exposes command *names* only --
-- parameter metadata does not exist in the protocol, so hints are data you take
-- from the server's documentation. \`params\`/\`required\` turn a hint into a guard.
require('core.lsp').register_command_hints('lua_ls', {
    ['lua.removeSpace'] = { description = 'Remove spaces around the cursor', params = {}, example = '[]' },
    -- parameterised example (positions are the JSON array elements):
    ['lua.setConfig'] = {
        description = 'Change a language server setting',
        params = { { name = 'config', type = 'table', required = true, description = 'section + value' } },
        example = '[{"Lua": {}}]',
        docs = 'https://luals.github.io/wiki/settings/',
    },
})
-- A "*" server entry acts as a global fallback hint:
require('core.lsp').register_command_hints('*', { ['my.custom'] = { description = '...', params = {} } })
-- Register a server without touching plugins/lsp.lua
require('core.lsp').register_server('my_server', { cmd = { 'my-server' }, filetypes = { 'lua' } })

-- Declarative autocommands and mappings (owned augroups, duplicate-free teardown)
require('core.autocmds').register('my-group', { 'BufWritePost' }, { callback = function() end })
require('core.keymaps').register({ id = 'my-map', mode = 'n', lhs = '<leader>q', rhs = ':q<cr>' })

-- Extend highlight groups at runtime (default = only if undefined)
require('core.highlights').define({ MyGroup = { link = 'Comment' } }, { kind = 'default' })

-- Register an external tool for health/availability checks (core.tools)
require('core.tools').register({ id = 'jq', cmd = 'jq', purpose = 'JSON formatting' })

-- Declare a plugin (core.pack); triggers: cmd / keys / ft / event, plus deps
require('core.pack').register({
    src = 'https://github.com/user/plugin',
    name = 'plugin',
    event = { 'BufReadPost' },                 -- or 'VeryLazy', { event='User', pattern='X' }
    cmd = { 'PluginCommand' },                 -- command trigger (name must be the plugin's command)
    keys = { { '<leader>x', mode = 'n' } },    -- key trigger (re-dispatched after loading)
    ft = { 'lua' },                            -- filetype trigger
    deps = { 'other-plugin' },                 -- ordered, cycle-checked
    reloadable = true,                         -- config() re-applied on :ConfigReload
    init = function() end,                     -- before loading
    config = function() end,                   -- after loading
})
require('core.pack').register_hook({ id = 'build', plugin = 'plugin', kinds = { 'install', 'update' }, fn = function(ev) end })
```

Adding a plugin module is equally direct: create `lua/plugins/<name>.lua` with a
`setup()` that calls `pack.register{...}` and register it in
`lua/plugins/init.lua`'s `ORDER`.

## Lifecycle model (setup / teardown / reload)

* Each subsystem builds its resources through `lib.lifecycle`; teardown removes
  exactly what that instance created. Re-creating a lifecycle with the same name
  tears the previous generation down first, so a repeated `setup()` cannot
  duplicate autocommands, mappings or commands.
* Core-owned registries (options, toggles, tools, root kinds) re-register in
  place, so a repeated `setup()` cannot fail with duplicate-id errors;
  non-core entries keep the strict "duplicate id is an error" behaviour.
* `:ConfigReload` performs: `User ConfigReloadPre` → ordered module teardown →
  drop `core.*`/`lib.*`/`plugins.*`/`config.*` from `package.loaded` →
  re-source `init.lua` → `User ConfigReload`.
* `:restart` (native) is the only full-process restart. `:PackUpdate` never
  applies anything unless you `:write` the review buffer, and after an update
  the notification tells you to run `:restart`. `reload.auto_restart = false` by
  default: Neovim is never restarted silently.
* Terminal slots are processes: reload terminates them (documented), and they
  are recreated on demand.

## Completion (blink.cmp)

`lua/plugins/blink_cmp.lua` configures completion from the LSP, filesystem,
snippets and buffers (keymap preset `default`, mono Nerd Font icons, automatic
documentation, Rust fuzzy matcher with a Lua fallback).

It is pinned to the stable `1.*` **release tags** (`vim.version.range("1.*")`):
the upstream default branch is the in-progress V2, which is a breaking-change
branch and additionally needs the separate `blink.lib` repository, while `1.*`
is the documented stable API and uses a prebuilt fuzzy-matching binary.

LSP capabilities are order-sensitive: a client is created with the capabilities
that are registered when it starts, and clients attach while file arguments are
opened — i.e. **before** `User VeryLazy`. The configuration therefore loads the
completion spec from the LSP module (`defaults.blink.load_early_for_lsp = true`)
so the first client already has blink's capabilities; setting it to `false`
keeps the plugin fully lazy (at the cost of the first buffer's server missing
completion capabilities). `tests/t10` verifies this end-to-end by starting
`lua_ls` and inspecting the capabilities of the resulting client.

## LSP tooling (mason.nvim)

`lua/plugins/mason.lua` installs LSP servers and other tools from inside Neovim:

* `<leader>cm` — the mason package UI (`:Mason`),
* `<leader>cM` — lists the servers that `core.lsp` reports as *missing* and
  installs the chosen one with `:MasonInstall` (the selection goes through
  `vim.ui.select`, so fzf-lua provides it).

The server→package mapping lives in the plugin module (package naming is mason's
domain) and `tests/t10` checks every entry against mason's registry. Mason
installs into `<data>/mason` and prepends its `bin` directory to `PATH`;
`core.lsp.setup_mason_path()` does the same at startup, so either order works and
`:checkhealth config` reports mason's `bin` directory plus the installed packages.
Mason fetches its package registry on first use (`:Mason`), so `:MasonInstall`
needs the registry (and the package download) to be reachable.

## Auto-pairs and indent guides

`lua/plugins/blink_pairs.lua` (auto-pairs + rainbow highlighting) and
`lua/plugins/blink_indent.lua` (indent guides) are both eager. blink.pairs needs
`saghen/blink.lib` (declared as a dependency in the same module) and its native
matcher, which is downloaded from the GitHub release at **install** time
(`require('blink.pairs').download()`), so starting Neovim never waits for it.
`defaults.blink_pairs.{mappings,highlights,matchparen}` and
`defaults.blink_indent.{static,scope,underline,char}` are the knobs.

Switching is owned by the plugins, so it is buffer-local where that matters:
`vim.b.pairs = false` (blink.pairs), `vim.b.indent_guide = false`
(blink.indent), or `require('blink.indent').enable(false)`. Command-line
highlighting for blink.pairs is left off because it needs `vim._core.ui2`.

## Statuscolumn, git signs and folds

`'statuscolumn'` is native (`lua/core/statuscolumn.lua`), modelled on
`snacks.nvim`'s statuscolumn (the one LazyVim uses):

```
[left: mark, sign][right-aligned number + gap][right: fold, git]
```

* signs come from **extmarks** (`type = "sign"`), which covers diagnostics, git and
  any plugin; extmarks without `sign_text` are skipped,
* marks are the ones that still exist in the buffer (`getmarklist()`, letters),
* the closed-fold glyph comes from `foldclosed()` + `fillchars.foldclose` with the
  `Folded` group, and `foldcolumn` is **0** because this renderer draws folds itself
  (a non-zero `foldcolumn` adds Neovim's own column, whose `fillchars.foldsep` is `│`),
* clicking the column toggles the fold under the cursor (`%@…click_fold@…%T`),
* nothing is cached: signs are read on every render (snacks uses a 50 ms refresh
  timer; extmark scans over signs only are cheap enough).

Git signs are placed by `lua/core/gitsign.lua`: mini.diff computes the hunks (its
summary reaches the statusline) but does not place its own signs here, so the module
reads `MiniDiff.get_buf_data()` and places them itself, with names that match the
statuscolumn's git pattern (`MiniDiffSign*`) and highlights linked to the original
`Added`/`Changed`/`Removed` groups. `defaults.git = { signs = { add = "│", … },
place_signs = true }`; `git.added/modified/removed` are the statusline icons.

**blink.pairs on `main`:** the prebuilt native matcher only exists for tagged
releases, so with `main` it is built from source once:
`:lua require('blink.pairs').build():pwait(900000)` (cargo required). The spec is
`main` on purpose.

## Borders

Every floating window takes its border from `vim.opt.winborder` (`defaults.options.winborder`,
`"single"` by default). Plugin configurations do not hardcode a shape: `lib.report`,
oil, the terminal float, the mason UI and the fzf-lua picker either omit `border` or pass
`vim.o.winborder`, and mini.nvim's own defaults already follow the option (mini.notify
reads it directly). Change the one value in `defaults.lua` to restyle every float at once;
`defaults.terminal.border` still exists as a *per-float* override for the terminal case,
but it is `nil` by default.

## Theme

`lua/plugins/tokyonight.lua` sets up [tokyonight](https://github.com/folke/tokyonight.nvim)
and applies it. The variant is one knob:

```lua
theme = { style = "night" }   -- night | storm | moon | day
```

The plugin derives the colorscheme name from it (`tokyonight-<style>`) and records
it in `options.colorscheme`, so health, tests and users read a single source of
truth. The spec is eager because a theme has to exist before the first redraw:
`core.setup()` applies `options.colorscheme` while plugins are not on the
runtimepath yet, so that early attempt only reports at debug level and the plugin
applies the scheme when it loads. `:checkhealth config` warns if the configured
scheme is not the active one (for example when the plugin is not installed).

Highlight groups of this configuration are registered with `default = true`, so
tokyonight's own colors always win; the managed ones only fill gaps.

## Native `lsp/` configuration

Servers can be configured with Neovim's own convention: a file named
`lsp/<config>.lua` in 'runtimepath'. `lsp/lua_ls.lua` is the single source for
`lua_ls`, and `core.lsp` enables native configs alongside the ones registered
through `register_server()` (`:LspInfo` shows the source of each).

Precedence is defined by Neovim (`:help lsp-config-merge`), from lowest to highest:

1. configuration defined for the `'*'` name (ours lives in `lua/plugins/lsp.lua`;
   the completion plugin extends its capabilities),
2. `lsp/<config>.lua` files in 'runtimepath',
3. `after/lsp/<config>.lua` files in 'runtimepath' (these override `lsp/`),
4. configurations defined anywhere else — this includes
   `require('core.lsp').register_server(name, cfg)`.

**A server must therefore be configured in exactly one place.** Because source 4
wins, registering `lua_ls` in the registry would silently shadow
`lsp/lua_ls.lua`, so it is registered there and nowhere else. The reverse also
matters: to override a config shipped by a plugin, put yours in `after/lsp/`.

Project-local LSP configs (`.nvim/lsp/*.lua` plus `set runtimepath+=.nvim`) are a
Neovim feature that requires `exrc`; this configuration keeps `exrc = false`, so
project files are not executed unless you opt in.

One caveat that follows from the protocol/loader design: `vim.lsp.config(name)`
does not resolve `lsp/` files (Neovim merges them when a client *starts*), so for
native configs `:LspInfo` and `:checkhealth config` cannot show the command in
advance and say so instead of guessing.

## LSP command hints (`:LspExec`)

`:LspExec` asks for JSON arguments and forwards them as-is. LSP deliberately has
**no parameter metadata** — `executeCommandProvider.commands` is a list of names,
with no schema and no required/optional information — so parameter hints are
opt-in data that this configuration keeps in a registry (core, user config and
plugins can all extend it):

```lua
require('core.lsp').register_command_hints('server', {
    ['server.command'] = {
        description = 'what it does',                                     -- shown in the picker
        params = { { name = 'Targets', type = 'string[]', required = true } },  -- positional
        required = { 2 },                        -- or just the required indices
        schema = '...',                          -- free-form, shown to the user
        example = '[["a"]]',                     -- default text of the JSON prompt
        docs = 'https://...',                     -- where the info comes from
    },
})
-- A '*' server entry is a global fallback; lookups are `server::command`, then `*::command`.
```

Behaviour: the interactive flow prints the hint (or, when nothing is registered,
an explanation that LSP has no schema plus how to add one) before asking for the
JSON; `:LspInfo` shows the per-client coverage (`command hints N/M documented`);
and `params`/`required` act as a guard — a command whose required arguments are
missing is rejected with a clear error and is **not executed**. Only commands
whose arguments are verifiably "none" are shipped as defaults (three entries);
everything else is meant to be added from the server's own documentation.

## Pickers (fzf-lua)

`lua/plugins/fzf_lua.lua` loads lazily from its keymaps or `:FzfLua`, then

* applies `fzf-lua.setup({})` — the module defaults (rounded float, flex preview,
  multi-select, preview scrolling keys) are used as-is, so there is no duplicated
  configuration to drift from upstream,
* registers fzf-lua as `vim.ui.select`, which the native selections of this
  configuration reuse (`:LspExec`, `:Toggles`),
* creates the keymaps from `defaults.picker.keys` (a `false` entry leaves one
  unbound; mappings are lifecycle-owned, so disabling one really removes it).

File, grep and git pickers run in the detected project root by default
(`defaults.picker.use_project_root = true`, resolved through `core.root`) and fall
back to Neovim's cwd; buffer-local pickers (resume, diagnostics, symbols, help,
keymaps) never force a cwd. `fzf-lua` needs the external `fzf` binary, reported by
`:checkhealth config` together with the optional `fd` (listing) and `bat` (preview)
helpers.

## User interface (statusline / statuscolumn)

Both are provided by `mini.nvim` modules and configured in
`lua/plugins/mini_statusline.lua` and `lua/plugins/mini_statuscolumn.lua`, which
`lua/plugins/mini.lua` applies from the `mini.nvim` pack spec (one repository =
one load = one config). `mini.git` feeds the branch section, `mini.diff` the hunk
summary, `mini.icons` the file icons.

Statusline sections, in order, each switchable through `defaults.ui.statusline`:

```
mode · git · diff · diagnostics      %<  filename  %=  lsp · fileinfo  location · searchcount
```

Inactive windows show the filename and the position only, and every section
truncates in narrow windows (mini's `trunc_width` convention).

`defaults.ui.statuscolumn` drives the column content spec
(`{ fold, sign, lnum }` + `format = "=lfs"`, `sep`, virtual/wrapped-line glyphs)
and `dim` for inactive windows. Clicks are handled by
`plugins.mini_statuscolumn.click()`: select window/line (mini's default), center
on double click, toggle the fold on the fold section, and show the line's
diagnostics on the sign section (both only when the clicked line really has a
fold/diagnostic).

## Validation

```bash
tests/run.sh                                   # 11 headless suites, ~378 assertions, isolated state dir
tests/optional-packupdate-apply.sh             # proves applying an update works (throwaway XDG tree)
tests/optional-auto-restart.sh                 # auto_restart restarts Neovim (pty; gates on :restart support)
stylua --check .                               # formatting
selene lua tests init.lua types                # linting
lua-language-server --check=. --checklevel=Warning   # static types (0 problems)
nvim --headless -c 'checkhealth config'        # tools/formatters/LSP/parsers/vim.pack
```

`lua-language-server --check` (CI mode) does not load `workspace.library`, so the
runtime surface this configuration uses (`vim.lsp.Client`, `vim.api.keyset.*`,
`vim.System*`, `uv_*`) is declared once in `types/neovim.lua` (`--- @meta`, no
executable code, not on 'runtimepath'). An editor session still gets the
authoritative definitions from `$VIMRUNTIME` and `${3rd}/luv/library`.

The suite covers startup/registry state, root detection (two project roots,
cache invalidation, `vim.g.root_spec`, custom kinds), toggle scopes and the
format-gate matrix, terminal slots/reuse/hidden-vs-visible cwd synchronization/
busy-shell protection/lazygit, soft reload (resource counts, mapping/command
sets, watcher/timer leak checks), `vim.pack` lazy loading with local fixtures,
the LSP/update surfaces (including `workspace/willRenameFiles` against a mock server that advertises file operations), completion capabilities (with a live `lua_ls` client) plus the mason mapping/commands, the picker wiring (declared triggers, provider names,
root-aware cwd policy, `vim.ui.select` registration/teardown, keymap ownership),
the UI (statusline/statuscolumn render for real
through `nvim_eval_statusline()`, including section knobs and click safety).

## Known limitations and constraints (measured, not assumed)

* **Plugin installs** happen only in interactive sessions. A headless session
  refuses to download missing plugins and reports instead (no silent network
  activity); `vim.pack.get()` itself may install lockfile entries, so health
  checks read the pack directory directly.
* **`cmd` triggers** replay the original command line after loading, so the
  declared name must be the command the plugin defines. `keys` triggers
  re-dispatch the pressed keys, so the plugin (or its configuration) must map them.
* **Plugin `plugin/` files are sourced at most once per Neovim process.**
  `reloadable = true` re-runs only `config()`; non-reloadable plugins keep the
  resources their first `config()` created. Specs registered *outside* the
  configuration files must be registered again after `:ConfigReload`, because the
  registry is rebuilt from `lua/plugins/*.lua`.
* **Terminal cwd synchronization needs `/proc`** (Linux). It also refuses to
  write to a shell that has a foreground job (`tpgid != pgrp`), so a running
  program is never fed stray input; on other platforms synchronization is
  skipped rather than guessed.
* **Error-level notifications are deferred by one tick**: Neovim treats an error
  echoed inside a command as a failure of that command (observed with `:write`
  inside `BufWritePre`), and reporting an error must not change the outcome of
  the operation that produced it.
* **Measured API facts this code relies on** (Neovim 0.12.5): `language.add()`
  returns `nil, err` for a missing parser instead of raising; `chansend()`
  returns the number of bytes written; `vim.g` tables are converted copies, so
  persistent flag tables must be written back; `exists(':Name')` also reports
  user commands (built-ins are detected through `nvim_get_commands()`);
  `nvim_get_commands{builtin=true}` is not implemented; `:restart` replaces any
  custom restart mechanism.
* `lua-language-server --check` ignores `workspace.library` (verified with
  `$VIMRUNTIME`, an absolute path and `${env:VIMRUNTIME}`); `types/neovim.lua`
  exists to keep that check meaningful instead of disabling lints.
* Completion and the LSP installer follow upstream stability: blink.cmp is pinned
  to the `1.*` release tags (V2 is a breaking-change branch requiring
  `blink.lib`), and LSP servers are not installed automatically — `<leader>cM`
  or `:MasonInstall <package>` performs that (network) action on request.
* Applying updates (`vim.pack.update()` / `:PackUpdate` then `:write`) is covered by
  `tests/optional-packupdate-apply.sh`, which runs in a throwaway XDG tree with a
  local `file://` fixture: the headless suite itself never changes plugin state.
* `vim.pack` is still marked experimental upstream; the orchestration layer
  keeps its behaviour (lockfile, review buffer, apply/discard) unchanged.
* The update check computes "newer upstream revision" from `git fetch` plus the
  spec's `version`, and is purely advisory: applying updates always goes through
  `vim.pack.update()` with its review buffer.
