--- Single source of user-facing defaults.
---
--- Precedence (documented, highest wins):
---
---   1. `lua/core/defaults.lua`   -- this file (core defaults)
---   2. `lua/core/user.lua`       -- optional, user-owned overrides
---   3. `require('core').setup{...}` -- overrides passed from `init.lua`
---   4. plugin extensions         -- `core.*` registries (`toggle`, `root`, `format`, `lsp`, `pack`)
---   5. runtime state             -- toggles, buffer-local flags, terminal slots, caches
---
--- Nothing else may hard-code a default that is listed here.
---
--- @class core.defaults
local M = {}

--- Pristine defaults. Never mutated after module load.
local BASE = {
    -- Basic identity -----------------------------------------------------------
    leader = " ",
    localleader = "\\",
    colorscheme = "tokyonight-night",

    -- Notifications (see `core.notify`) ---------------------------------------
    notify = {
        --- Minimum level: 'DEBUG' | 'INFO' | 'WARN' | 'ERROR' | 'OFF'
        level = "INFO",
        --- Number of messages kept in the inspectable history ring buffer.
        history = 50,
        --- Window (ms) used by `notify.once` to deduplicate repeated messages.
        once_ms = 5000,
    },

    -- Editor options (see `core.options`) ------------------------------------
    --- Applied with `vim.opt` (set-like: local + global default for local options).
    options = {
        clipboard = "unnamedplus",
        cmdheight = 0,
        mouse = "nvi",
        breakindent = true,
        breakindentopt = "list:-1",
        number = true,
        relativenumber = true,
        signcolumn = "yes:1",
        cursorline = true,
        scrolloff = 5,
        sidescrolloff = 5,
        splitright = true,
        splitbelow = true,
        termguicolors = true,
        --- Border of every floating window that does not set its own
        --- (`:help 'winborder'`). Plugins below inherit it instead of
        --- hardcoding a shape, so this is the single place to change borders.
        winborder = "single",
        laststatus = 3,
        showmode = false,
        pumheight = 12,
        undofile = true,
        swapfile = true,
        backup = false,
        writebackup = true,
        updatetime = 250,
        timeoutlen = 400,
        ttimeoutlen = 20,
        ignorecase = true,
        smartcase = true,
        incsearch = true,
        hlsearch = true,
        inccommand = "split",
        infercase = true,
        confirm = true,
        hidden = true,
        expandtab = true,
        shiftwidth = 4,
        tabstop = 4,
        softtabstop = 4,
        autoindent = true,
        smartindent = true,
        formatoptions = "jcroqlnt",
        grepformat = "%f:%l:%c:%m",
        grepprg = "rg --vimgrep --smart-case",
        foldlevel = 99,
        fillchars = { eob = " " },
        list = false,
        listchars = { tab = "» ", trail = "·", nbsp = "␣", extends = "›", precedes = "‹" },
    },

    --- Extra `shortmess` flags appended to Neovim's default.
    shortmess_extra = "IcF",

    -- Global behavioral autocommands (see `core.autocmds`) --------------------
    autocmds = {
        --- Restore the cursor to the last known position when re-opening a file.
        last_position = true,
        --- `:checktime` when the terminal regains focus (file changed on disk).
        checktime_on_focus = true,
        --- Highlight on yank (uses the built-in `vim.hl.on_yank()`).
        highlight_yank = true,
    },

    -- Highlights (see `core.highlights`) -------------------------------------
    --- `default` groups are only applied when the colorscheme did not define
    --- them; `override` groups always win. Example:
    ---   highlights = { override = { CursorLine = { bg = '#2a2a2a' } } }
    highlights = {
        default = {},
        override = {},
    },

    -- Default keymaps (see `core.keymaps`) -----------------------------------
    --- Window navigation is intentionally conservative: only mappings that do
    --- not shadow a built-in editing motion are added by default.
    keymaps = {
        window_nav = true,
        clear_search = true,
    },

    -- User interface (see `lua/plugins/mini_statusline.lua` / `mini_statuscolumn.lua`)
    ui = {
        --- Statusline sections; `false` hides a section, `enabled = false` leaves
        --- 'statusline' untouched.
        statusline = {
            enabled = true,
            --- Icons come from mini.icons (enabled in `lua/plugins/mini.lua`).
            icons = true,
            git = true,
            diff = true,
            diagnostics = true,
            lsp = true,
            filename = true,
            fileinfo = true,
            location = true,
            searchcount = true,
        },
        --- Sign/fold/number column (content spec of mini.statuscolumn).
        statuscolumn = {
            enabled = true,
            --- Dim the column content in inactive windows.
            dim = true,
            --- Separator between the column and the buffer text, and the glyphs for
            --- virtual/wrapped lines (literals: LuaJIT string escapes are 5.1-only).
            separator = "▏",
            virt = "•",
            wrap = "↳",
        },
    },

    -- Completion (see `lua/plugins/blink_cmp.lua`) --------------------------
    blink = {
        enabled = true,
        --- Load the completion plugin during startup so the *first* LSP client
        --- starts with its capabilities: clients attach while file arguments are
        --- opened, i.e. before `User VeryLazy`. `false` keeps it fully lazy.
        load_early_for_lsp = true,
        --- Show completion documentation automatically.
        documentation_auto_show = true,
    },

    -- LSP tool installer (see `lua/plugins/mason.lua`) -----------------------
    mason = {
        enabled = true,
    },

    -- Fuzzy picker (see `lua/plugins/fzf_lua.lua`) --------------------------
    picker = {
        enabled = true,
        --- Run file/grep/git pickers in the detected project root (core.root).
        use_project_root = true,
        --- Keymaps; `false` leaves one unbound.
        keys = {
            files = "<leader>ff",
            grep = "<leader>fg",
            grep_word = "<leader>fw",
            buffers = "<leader>fb",
            resume = "<leader>fr",
            diagnostics = "<leader>fd",
            symbols = "<leader>fs",
            help = "<leader>fh",
            keymaps = "<leader>fk",
            git_commits = "<leader>gc",
            git_branches = "<leader>gb",
            git_status = "<leader>gs",
        },
    },

    -- Toggles (see `core.toggle`) -------------------------------------------
    toggles = {
        --- Notify on every toggle change.
        notify = true,
        --- Initial state applied when a toggle is registered (runtime state after
        --- that is owned by the user). `nil` = leave Neovim's own default.
        defaults = {
            diagnostics = true,
            inlay_hints = true,
            autoformat = true,
            spell = false,
            wrap = true,
            relativenumber = true,
            number = true,
            treesitter_context = false,
        },
        --- Keymaps for the toggle family. Set an entry to `false` to disable it.
        keys = {
            diagnostics = "<leader>ud",
            inlay_hints = "<leader>uh",
            autoformat = "<leader>uf",
            autoformat_buffer = "<leader>uF",
            spell = "<leader>us",
            wrap = "<leader>uw",
            relativenumber = "<leader>ur",
            number = "<leader>un",
            cursorword = "<leader>uc",
            treesitter_context = "<leader>ut",
        },
    },

    -- Project root detection (see `core.root`) ------------------------------
    root = {
        --- `vim.g.root_spec` (when set) wins over this table.
        spec = nil,
        cache = true,
        --- Default strategy list, in priority order. Shorthand strings are marker
        --- strategies; tables may be:
        ---   { id, kind = 'marker'|'fn'|'cwd'|'dirname'|'lsp', priority, ... }
        default_spec = {
            { id = "git", kind = "marker", markers = { ".git" }, priority = 100 },
            {
                id = "project",
                kind = "marker",
                priority = 90,
                markers = {
                    "package.json",
                    "go.mod",
                    "Cargo.toml",
                    "pyproject.toml",
                    "requirements.txt",
                    "setup.py",
                    "deno.json",
                    "bun.lockb",
                    "composer.json",
                    "Gemfile",
                    "Makefile",
                    "CMakeLists.txt",
                    "flake.nix",
                    "docker-compose.yml",
                    "justfile",
                },
            },
            { id = "lsp", kind = "lsp", priority = 80 },
            { id = "cwd", kind = "cwd", priority = 20 },
            { id = "file", kind = "dirname", priority = 10 },
        },
    },

    -- Terminal (see `core.terminal`) ----------------------------------------
    terminal = {
        --- nil = `$SHELL`, then 'sh'.
        shell = nil,
        --- Extra shell arguments (e.g. { '-l' } for a login shell).
        shell_args = nil,
        --- Number of reusable slots.
        slots = 3,
        --- Synchronize the cwd of *hidden* slots with the current project context.
        --- Visible terminals are never touched (see `core.terminal.sync_cwd`).
        sync_cwd = true,
        --- Optional override for the terminal float border; nil follows
        --- `vim.opt.winborder`.
        border = nil,
        --- Float size as a ratio of the editor (0..1) or an absolute integer.
        width = 0.8,
        height = 0.75,
        winblend = 0,
        title = true,
        --- Enter insert mode when a slot is opened.
        start_insert = true,
        --- Grace period (ms) after opening a slot before cwd synchronization may
        --- inject anything into the shell.
        sync_grace_ms = 500,
        --- Keymaps for slots (`false` disables). `{n}` is replaced by the slot index.
        keys = {
            toggle = "<C-\\>",
            slot = "<leader>t{n}",
            close = "<leader>tq",
        },
    },

    -- Formatting (see `core.format`) ---------------------------------------
    format = {
        --- Global autoformat gate (runtime value lives in `vim.g.core_autoformat`).
        autoformat = true,
        --- Register the `BufWritePre` autocmd that performs format-on-save.
        on_save = true,
        --- Timeout passed to the formatter provider (ms).
        timeout_ms = 1500,
        --- Formatter metadata. This is *core* data: it is registered by
        --- `core.format.setup()`, so health/`:FormatInfo` know what is declared
        --- before any provider plugin is loaded (the provider only runs them).
        formatters = {
            { id = "stylua", cmd = "stylua", notes = "Lua" },
            { id = "prettier", cmd = "prettier", notes = "JSON, YAML, Markdown, HTML, CSS, JS/TS" },
            { id = "ruff_format", cmd = "ruff", notes = "Python" },
            { id = "shfmt", cmd = "shfmt", notes = "sh, bash, zsh" },
            { id = "clang-format", cmd = "clang-format", notes = "C, C++, Objective-C" },
            { id = "rustfmt", cmd = "rustfmt", notes = "Rust" },
            { id = "goimports", cmd = "goimports", notes = "Go imports" },
            { id = "gofmt", cmd = "gofmt", notes = "Go" },
        },
        --- Filetype -> formatter ids (in order). Also the single source of truth
        --- for the provider integration.
        filetypes = {
            lua = { "stylua" },
            luau = { "stylua" },
            python = { "ruff_format" },
            go = { "goimports", "gofmt" },
            rust = { "rustfmt" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            zsh = { "shfmt" },
            c = { "clang-format" },
            cpp = { "clang-format" },
            cuda = { "clang-format" },
            objc = { "clang-format" },
            json = { "prettier" },
            jsonc = { "prettier" },
            yaml = { "prettier" },
            markdown = { "prettier" },
            html = { "prettier" },
            css = { "prettier" },
            scss = { "prettier" },
            javascript = { "prettier" },
            javascriptreact = { "prettier" },
            typescript = { "prettier" },
            typescriptreact = { "prettier" },
        },
    },

    -- Indentation (see `core/autocmds.lua`) -----------------------------------
    --- Enforced per buffer after ftplugins ran (some of Neovim's own ftplugins
    --- pick other widths, e.g. `yaml` -> 2). `tabs` lists filetypes whose
    --- toolchains mandate hard tabs; they keep the ftplugin behaviour
    --- (`expandtab` off, `shiftwidth` 0).
    indent = {
        enabled = true,
        width = 4,
        expandtab = true,
        tabs = { "make", "go", "gitcommit" },
    },

    -- Auto-pairs (see `lua/plugins/blink_pairs.lua`) -------------------------
    blink_pairs = {
        enabled = true,
        --- Insert-mode/operator mappings (switch per buffer with `vim.b.pairs`).
        mappings = true,
        --- Rainbow highlighting of pairs.
        highlights = true,
        --- Highlight the pair around the cursor.
        matchparen = true,
    },

    -- Indent guides (see `lua/plugins/blink_indent.lua`) ----------------------
    blink_indent = {
        enabled = true,
        --- Static guides on every indent level.
        static = true,
        --- Highlight the current scope's indentation.
        scope = true,
        --- Underline the line above the current scope.
        underline = false,
        --- Guide character (U+258F left one eighth block).
        char = "▏",
        --- Hide the guides in buffers that never indent more than once (the plugin
        --- has no such option, so it is applied per buffer through its API).
        --- NOTE: the detection currently also disables buffers that *do* indent
        --- twice, so it is off until that is fixed ( do not cover it yet).
    },

    -- Git indicators in the statusline (see `lua/plugins/mini.lua`) -----------
    git = {
        --- Nerd Font glyphs for `vim.b.minidiff_summary_string` (added/modified/
        --- removed), applied on `User MiniDiffUpdated` as mini.diff documents.
        added = " ", -- U+F0FE nf-fa-plus_square
        modified = " ", -- U+F044 nf-fa-pencil_square_o
        removed = " ", -- U+F1F8 nf-fa-trash_o
    },

    -- Clue window (see `lua/plugins/mini.lua`) -------------------------------
    ui_clue = {
        --- Delay (ms) before the mini.clue window appears while a sequence is
        --- pending. mini.clue defaults to 1000 (deliberately: the window should not
        --- flash for fast key sequences), which feels sluggish when you pause on
        --- `<Leader>` on purpose.
        delay = 300,
    },

    -- Theme (see `lua/plugins/tokyonight.lua`) -------------------------------
    theme = {
        --- Variant passed to `require('tokyonight').setup()`:
        --- "night" | "storm" | "moon" | "day". The plugin derives the colorscheme
        --- name from it (`tokyonight-<style>`) and records it in
        --- `options.colorscheme`, so there is a single source of truth.
        style = "night",
    },

    -- Diagnostics (see `core.lsp.setup_diagnostics()`) ------------------------
    diagnostics = {
        --- Symbols instead of the `E`/`W`/`I`/`H` letters that Neovim ships for the
        --- sign column, the statusline and `vim.diagnostic.config().signs.text`.
        --- Nerd Font glyphs (mini.icons has no "diagnostic" category, so the glyphs
        --- live here). The sign column uses the glyph alone; the statusline and the
        --- virtual text use the value as written, so the trailing space reads nicer.
        icons = true,
        signs = {
            error = " ", -- U+F057 nf-fa-times_circle
            warn = " ", -- U+F071 nf-fa-exclamation_triangle
            info = " ", -- U+F05A nf-fa-info_circle
            hint = " ", -- U+F0EB nf-fa-lightbulb_o
        },
        --- Inline messages (`vim.diagnostic.Opts.VirtualText`).
        virtual_text = true,
        --- One line per diagnostic, current line only (disables `virtual_text`).
        virtual_lines = false,
        --- Highest severity first.
        severity_sort = true,
        --- Diagnostics are updated on InsertLeave, not while typing.
        update_in_insert = false,
        --- Float: border from `winborder`, source shown, not focusable.
        float = true,
    },

    -- LSP (see `core.lsp`) ---------------------------------------------------
    lsp = {
        --- Prepend `<data>/mason/bin` to `PATH` when it exists.
        use_mason_bin = true,
        --- Server configs: `{ <name> = <vim.lsp.Config> }`.
        --- `root_strategy` is optional: 'core' (use `core.root`) or 'lsp' (default).
        servers = {},
        --- Enable servers whose executable is available.
        enable = true,
        --- Notify when a configured server is skipped because its command is missing.
        notify_missing = false,
    },

    -- Health checks (see `core.health`) -------------------------------------
    health = {
        --- Parsers reported by `:checkhealth config` (installed vs missing).
        treesitter_languages = {
            "lua",
            "luadoc",
            "vim",
            "vimdoc",
            "query",
            "markdown",
            "markdown_inline",
            "json",
            "yaml",
            "toml",
            "bash",
            "c",
            "cpp",
            "go",
            "python",
            "rust",
            "javascript",
            "typescript",
            "html",
            "css",
            "diff",
            "gitcommit",
            "regex",
        },
    },

    -- Plugin management (see `core.pack`) ----------------------------------
    pack = {
        --- Ask before installing missing plugins (`vim.pack.add()` default).
        confirm_install = true,
        --- Declared plugin specs (usually filled by `lua/plugins/*.lua`).
        plugins = {},

        update = {
            --- Check for available updates in the background at most every
            --- `interval_days`, without changing plugin state.
            auto_check = true,
            interval_days = 7,
            --- Delay after startup before the (network) check starts (ms).
            startup_delay_ms = 2000,
            --- Notify when updates are found.
            notify = true,
            --- Timeout for a single `git fetch` (ms).
            fetch_timeout_ms = 20000,
        },
    },

    -- Configuration watcher / reload (see `core.reload`) --------------------
    reload = {
        --- Watch the whole configuration tree.
        watch = true,
        --- Debounce for filesystem events (ms).
        debounce_ms = 300,
        --- Automatically reload when a watched file changes.
        auto_reload = false,
        --- Automatically run `:restart` after a plugin update. Off by default:
        --- a restart is never silent.
        auto_restart = false,

        --- Extra path patterns (Lua patterns matched against the absolute path)
        --- that must never trigger a reload.
        ignore = {},
    },
}

--- Deep copy helper that keeps the pristine table immutable.
--- @param t table
--- @return table
local function copy(t)
    return vim.deepcopy(t)
end

--- Active configuration. Mutated only through `M.setup`.
M.values = copy(BASE)

--- Replace the active values with `BASE` + `overrides`.
--- @param overrides? table
--- @return table values
function M.setup(overrides)
    M.values = vim.tbl_deep_extend("force", copy(BASE), overrides or {})
    return M.values
end

--- Read a value by dotted path, e.g. `M.get('terminal.slots')`.
--- @param path string
--- @param fallback? any
--- @return any
function M.get(path, fallback)
    local cur = M.values
    for part in tostring(path):gmatch("[^%.]+") do
        if type(cur) ~= "table" then
            return fallback
        end
        cur = cur[part]
    end
    if cur == nil then
        return fallback
    end
    return cur
end

return M
