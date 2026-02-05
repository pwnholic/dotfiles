local opt, g = vim.opt, vim.g

opt.hidden = true -- Allow buffer switch without saving
opt.confirm = true -- Ask confirmation instead of error on unsaved changes
opt.exrc = false -- Enable project-local .nvim.lua / .exrc
opt.timeout = false -- Disable mapped sequence timeout

-- ============================================================================
-- Editing Behavior
-- ============================================================================

opt.backspace = { "indent", "eol", "start" } -- Modern backspace behavior
opt.whichwrap:append("<>[]hl") -- Cursor wraps with arrow keys
opt.selection = "old" -- Preserve legacy selection behavior
opt.nrformats:append("blank") -- Smarter number increment/decrement

-- ============================================================================
-- UI & Layout
-- ============================================================================

opt.cmdheight = 0 -- Hide command line when idle (Neovim 0.9+)
opt.showtabline = 0
opt.number = true -- Show line numbers
opt.cursorline = true -- Highlight current line
opt.cursorlineopt = "both" -- Highlight only line number
opt.colorcolumn = "80" -- Visual column guide
opt.signcolumn = "yes:1" -- Always show sign column (fixed width)
opt.showmode = false -- Hide -- INSERT -- (handled by statusline)
opt.ruler = true -- Show cursor position
opt.helpheight = 10 -- Fixed help window height
opt.pumheight = 16 -- Limit popup menu height
opt.winborder = "rounded" -- Global border
opt.cursorcolumn = true

-- ============================================================================
-- Window & Split Behavior
-- ============================================================================

opt.splitright = true -- Vertical splits open to the right
opt.splitbelow = true -- Horizontal splits open below
opt.equalalways = false -- Don't auto-resize splits
opt.scrolloff = 2 -- Minimal vertical context
opt.sidescrolloff = 8 -- Horizontal scroll padding
opt.scrolljump = 5 -- Faster scrolling on large jumps
opt.wrap = false -- Disable line wrapping
opt.linebreak = true -- Wrap at word boundaries
opt.breakindent = true -- Preserve indent on wrapped lines
opt.smoothscroll = true -- Smooth scrolling (Neovim 0.10+)

-- ============================================================================
-- Search & Completion
-- ============================================================================

opt.hlsearch = true -- Highlight all search matches
opt.incsearch = true -- Incremental search
opt.ignorecase = true -- Case-insensitive search
opt.smartcase = true -- Override ignorecase if uppercase used
opt.completeopt = "menuone" -- Predictable completion menu

-- ============================================================================
-- Performance
-- ============================================================================

opt.synmaxcol = 300 -- Disable syntax highlight on very long lines

-- ============================================================================
-- Files, Backup & Undo
-- ============================================================================

opt.autoread = true -- Auto reload externally changed files
opt.swapfile = false -- Disable swap files
opt.undofile = true -- Persistent undo
opt.backup = true -- Enable backup files
opt.backupskip = { "/tmp/*", "/private/tmp/*" } -- Skip backups for temp dirs
opt.backupdir:remove(".") -- Don't create backup in current directory
opt.tabclose = "uselast" -- Close last-used tab
opt.viewoptions = { "cursor", "folds" } -- Persist cursor & folds

-- ============================================================================
-- Folding
-- ============================================================================

opt.foldmethod = "indent" -- Indentation-based folding
opt.foldlevelstart = 99 -- Open all folds by default
opt.foldtext = "" -- Clean fold text
opt.foldopen:remove("block") -- Skip folds with { }

-- ============================================================================
-- Formatting
-- ============================================================================

opt.formatoptions:append("normc") -- Continue comments & numbered lists
opt.formatoptions:remove("t") -- Disable auto-wrap on text

-- ============================================================================
-- Indentation
-- ============================================================================

opt.expandtab = true -- Use spaces instead of tabs
opt.tabstop = 4 -- Number of spaces a <Tab> counts for
opt.shiftwidth = 4 -- Spaces used for autoindent
opt.softtabstop = 4 -- Spaces inserted/deleted with <Tab>/<BS>
opt.shiftround = true -- Round indent to shiftwidth
opt.smartindent = true -- Smart autoindenting
opt.autoindent = true -- Copy indent from current line

-- ============================================================================
-- Cursor Shape
-- ============================================================================

opt.gcr = {
    "i-c-ci-ve:blinkoff500-blinkon500-block-TermCursor", -- Insert/change
    "n-v:block-Curosr/lCursor", -- Normal/visual
    "o:hor50-Curosr/lCursor", -- Operator-pending
    "r-cr:hor20-Curosr/lCursor", -- Replace modes
}

-- ============================================================================
-- Spell Checking
-- ============================================================================

opt.spellsuggest = "best,9" -- Show best spell suggestions (limit 9)
opt.spellcapcheck = "" -- Disable capitalization heuristic
opt.spelllang = "en" -- English dictionary
opt.spelloptions = "camel" -- camelCase spell checking

-- ============================================================================
-- Invisible Characters & UI Symbols
-- ============================================================================

opt.list = true -- Show invisible characters
opt.listchars = {
    tab = "▏ ",
    trail = "·", -- Highlight trailing spaces
    nbsp = "␣", -- Non-breaking space
}

opt.fillchars = {
    fold = "·", -- Fold filler
    foldsep = " ", -- No fold separator
    eob = " ", -- Hide ~ at end of buffer
    foldopen = "", -- Fold open icon
    foldclose = "", -- Fold close icon
    diff = "╱", -- Diff filler
}

-- ============================================================================
-- Messages
-- ============================================================================

opt.shortmess:append("F") -- Don't show file info message on edit

-- ============================================================================
-- LazyVim Language Overrides
-- ============================================================================

-- Snacks animations
-- Set to `false` to globally disable all snacks animations
g.snacks_animate = false

-- Python LSP
-- Use "basedpyright" instead of pyright
g.lazyvim_python_lsp = "basedpyright"

-- Use modern Ruff LSP (not legacy ruff_lsp)
g.lazyvim_python_ruff = "ruff"
