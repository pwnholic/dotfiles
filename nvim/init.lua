vim.pack.add({
    -- Prefer the release branch, not the bleeding-edge `main`
    { src = 'https://github.com/nvim-mini/mini.nvim', version = 'stable' },
})

---------------------------------------------------------------------------
-- 1. Options --------------------------------------------------------------
---------------------------------------------------------------------------
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = 'yes'
opt.cursorline = true

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.inccommand = 'split'
opt.splitright = true
opt.splitbelow = true

opt.termguicolors = true
opt.scrolloff = 8
opt.updatetime = 250
opt.mouse = 'a'
opt.undofile = true
opt.pumheight = 10
opt.completeopt = 'menu,menuone,noselect'

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

---------------------------------------------------------------------------
-- 2. Startup helpers ------------------------------------------------------
---------------------------------------------------------------------------
-- Run a function immediately.
local function now(fn)
    fn()
end

-- Run a function just after first screen draw to keep startup snappy.
local function later(fn)
    vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        callback = function()
            vim.schedule(fn)
        end,
    })
end

-- Now if Neovim was opened with a file (`nvim -- file`), later otherwise.
local now_if_args = vim.fn.argc(-1) > 0 and now or later

-- Thin wrapper around `nvim_create_autocmd`.
local function on(events, opts, callback, desc)
    vim.api.nvim_create_autocmd(events, vim.tbl_extend('force', opts or {}, {
        callback = callback,
        desc = desc,
    }))
end

---------------------------------------------------------------------------
-- 3. Appearance (needed before first draw) -------------------------------
---------------------------------------------------------------------------
later(function()
    vim.cmd('colorscheme miniwinter')
    -- Others bundled with mini.nvim: minispring / minisummer / miniautumn
end)

now(function()
    require('mini.basics').setup({
        options = { basic = false }, -- options live in section 1
        mappings = {
            windows = true,          -- <C-hjkl> window nav
            move_with_alt = true,    -- <M-hjkl> insert/cmdline nav
        },
    })
end)

now(function()
    require('mini.icons').setup()
    later(MiniIcons.mock_nvim_web_devicons)
    later(MiniIcons.tweak_lsp_kind)
end)

now(function() require('mini.notify').setup() end)
now(function() require('mini.sessions').setup() end)
now(function() require('mini.statusline').setup() end)
now(function() require('mini.tabline').setup() end)

---------------------------------------------------------------------------
-- 4. Startup / file workflows ---------------------------------------------
---------------------------------------------------------------------------
-- Start screen
now(function()
    require('mini.starter').setup()
end)

-- Completion + signature help (LSP-aware, with a keyword fallback)
now_if_args(function()
    local process_items = function(items, base)
        return MiniCompletion.default_process_items(items, base, {
            kind_priority = { Text = -1, Snippet = 99 },
        })
    end
    require('mini.completion').setup({
        lsp_completion = {
            source_func = 'omnifunc',
            auto_setup = false,
            process_items = process_items,
        },
    })

    on('LspAttach', nil, function(ev)
        vim.bo[ev.buf].omnifunc = 'v:lua.MiniCompletion.completefunc_lsp'
    end, "Set 'omnifunc' for LSP completion")

    vim.lsp.config('*', { capabilities = MiniCompletion.get_lsp_capabilities() })
end)

-- File explorer (Miller columns) with preview + bookmarks
now_if_args(function()
    require('mini.files').setup({ windows = { preview = true } })

    local add_marks = function()
        MiniFiles.set_bookmark('c', vim.fn.stdpath('config'), { desc = 'Config' })
        MiniFiles.set_bookmark(
            'p',
            vim.fn.stdpath('data') .. '/site/pack/core/opt',
            { desc = 'Plugins' }
        )
        MiniFiles.set_bookmark('w', vim.fn.getcwd, { desc = 'Working directory' })
    end
    on('User', { pattern = 'MiniFilesExplorerOpen' }, add_marks, 'Files bookmarks')
end)

-- Misc utilities: auto-root, restore cursor, terminal bg sync
now_if_args(function()
    require('mini.misc').setup()
    MiniMisc.setup_auto_root()
    MiniMisc.setup_restore_cursor()
    MiniMisc.setup_termbg_sync()
end)

---------------------------------------------------------------------------
-- 5. Editing --------------------------------------------------------------
---------------------------------------------------------------------------
later(function() require('mini.extra').setup() end)

later(function()
    local ai = require('mini.ai')
    ai.setup({
        custom_textobjects = {
            B = MiniExtra.gen_ai_spec.buffer(),
            F = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
        },
        search_method = 'cover',
    })
end)

later(function() require('mini.align').setup() end)
later(function()
    require('mini.operators').setup()
    vim.keymap.set('n', '(', 'gxiagxila', { remap = true, desc = 'Swap arg left' })
    vim.keymap.set('n', ')', 'gxiagxina', { remap = true, desc = 'Swap arg right' })
end)
later(function() require('mini.pairs').setup({ modes = { command = true } }) end)
later(function() require('mini.splitjoin').setup() end)
later(function() require('mini.surround').setup() end)
later(function() require('mini.move').setup() end)
later(function() require('mini.jump').setup() end)
later(function() require('mini.jump2d').setup() end)

-- Autopair-aware <CR> / <BS>, pmenu navigation
later(function()
    require('mini.keymap').setup()
    MiniKeymap.map_multistep('i', '<Tab>', { 'pmenu_next' })
    MiniKeymap.map_multistep('i', '<S-Tab>', { 'pmenu_prev' })
    MiniKeymap.map_multistep('i', '<CR>', { 'pmenu_accept', 'minipairs_cr' })
    MiniKeymap.map_multistep('i', '<BS>', { 'minipairs_bs' })
end)

---------------------------------------------------------------------------
-- 6. Navigation & info ----------------------------------------------------
---------------------------------------------------------------------------
later(function() require('mini.bracketed').setup() end)
later(function() require('mini.bufremove').setup() end)
later(function() require('mini.indentscope').setup() end)
later(function() require('mini.pick').setup() end)
later(function() require('mini.visits').setup() end)

-- Next-key clues
later(function()
    local clue = require('mini.clue')
    clue.setup({
        clues = {
            clue.gen_clues.builtin_completion(),
            clue.gen_clues.g(),
            clue.gen_clues.marks(),
            clue.gen_clues.registers(),
            clue.gen_clues.square_brackets(),
            clue.gen_clues.z(),
        },
        triggers = {
            { mode = { 'n', 'x' }, keys = '<Leader>' },
            { mode = 'n',          keys = '\\' },
            { mode = { 'n', 'x' }, keys = '[' },
            { mode = { 'n', 'x' }, keys = ']' },
            { mode = 'i',          keys = '<C-x>' },
            { mode = { 'n', 'x' }, keys = 'g' },
            { mode = { 'n', 'x' }, keys = "'" },
            { mode = { 'n', 'x' }, keys = '`' },
            { mode = { 'n', 'x' }, keys = '"' },
            { mode = { 'i', 'c' }, keys = '<C-r>' },
            { mode = 'n',          keys = '<C-w>' },
            { mode = { 'n', 'x' }, keys = 's' },
            { mode = { 'n', 'x' }, keys = 'z' },
        },
    })
end)

-- Buffer overview minimap
later(function()
    local map = require('mini.map')
    map.setup({
        symbols = { encode = map.gen_encode_symbols.dot('4x2') },
        integrations = {
            map.gen_integration.builtin_search(),
            map.gen_integration.diff(),
            map.gen_integration.diagnostic(),
        },
    })
    for _, key in ipairs({ 'n', 'N', '*', '#' }) do
        local rhs = key .. 'zv<Cmd>lua MiniMap.refresh({}, { lines = false, scrollbar = false })<CR>'
        vim.keymap.set('n', key, rhs)
    end
end)

---------------------------------------------------------------------------
-- 7. Command line, comments, git ------------------------------------------
---------------------------------------------------------------------------
later(function() require('mini.cmdline').setup() end)
later(function() require('mini.comment').setup() end)
later(function() require('mini.diff').setup() end)
later(function() require('mini.git').setup() end)
later(function() require('mini.input').setup() end)
later(function() require('mini.trailspace').setup() end)

-- Highlight TODO/FIXME/etc. and hex colors
later(function()
    local hip = require('mini.hipatterns')
    local words = MiniExtra.gen_highlighter.words
    hip.setup({
        highlighters = {
            fixme = words({ 'FIXME', 'Fixme', 'fixme' }, 'MiniHipatternsFixme'),
            hack = words({ 'HACK', 'Hack', 'hack' }, 'MiniHipatternsHack'),
            todo = words({ 'TODO', 'Todo', 'todo' }, 'MiniHipatternsTodo'),
            note = words({ 'NOTE', 'Note', 'note' }, 'MiniHipatternsNote'),
            hex_color = hip.gen_highlighter.hex_color(),
        },
    })
end)

---------------------------------------------------------------------------
-- 8. Snippets -------------------------------------------------------------
---------------------------------------------------------------------------
later(function()
    local snippets = require('mini.snippets')
    snippets.setup({
        snippets = {
            -- Drop `snippets/global.json` next to this file to enable global snippets.
            -- snippets.gen_loader.from_file(vim.fn.stdpath('config') .. '/snippets/global.json'),
            -- Install 'rafamadriz/friendly-snippets' and load language snippets:
            -- snippets.gen_loader.from_lang(),
        },
    })
end)

---------------------------------------------------------------------------
-- 9. Keymaps --------------------------------------------------------------
---------------------------------------------------------------------------
local map = vim.keymap.set

-- Window navigation (also provided by mini.basics with <C-hjkl>)
map('n', '<Space>wh', '<C-w>h', { desc = 'Window left' })
map('n', '<Space>wj', '<C-w>j', { desc = 'Window down' })
map('n', '<Space>wk', '<C-w>k', { desc = 'Window up' })
map('n', '<Space>wl', '<C-w>l', { desc = 'Window right' })

-- Buffer navigation
map('n', '<Space>bb', '<Cmd>Pick buffers<CR>', { desc = 'Pick buffer' })
map('n', '<Space>bn', '<Cmd>enew<CR>', { desc = 'New buffer' })
map('n', '<Space>bd', '<Cmd>lua MiniBufremove.delete()<CR>', { desc = 'Delete buffer' })

-- Files
map('n', '<Space>ff', '<Cmd>Pick files<CR>', { desc = 'Find files' })
map('n', '<Space>fg', '<Cmd>Pick grep_live<CR>', { desc = 'Live grep' })
map('n', '<Space>fh', '<Cmd>Pick help<CR>', { desc = 'Help tags' })
map('n', '<Space>fr', '<Cmd>Pick resume<CR>', { desc = 'Resume picker' })
map('n', '<Space>ed', '<Cmd>lua MiniFiles.open(vim.fn.getcwd())<CR>', { desc = 'Explorer cwd' })
map('n', '<Space>ef', '<Cmd>lua MiniFiles.open(vim.fn.expand("%:p:h"))<CR>', { desc = 'Explorer file' })

-- Search / global
map('n', 'gs', '<Cmd>Pick grep_live<CR>', { desc = 'Live grep' })

-- Git
map('n', '<Space>gs', '<Cmd>lua MiniGit.show_at_cursor()<CR>', { desc = 'Git info at cursor' })
map('n', '<Space>gd', '<Cmd>lua MiniGit.show_at_cursor({scope = "diff"})<CR>', { desc = 'Git diff at cursor' })

-- Misc
map('n', '<Space>zo', '<Cmd>lua MiniMisc.zoom()<CR>', { desc = 'Zoom toggle' })
map('n', '<Space>ot', '<Cmd>lua MiniTrailspace.trim()<CR>', { desc = 'Trim trailspace' })

-- Move lines / selections (Alt-based)
map('n', '<M-j>', '<Cmd>m+<CR>==', { desc = 'Move line down' })
map('n', '<M-k>', '<Cmd>m-2<CR>==', { desc = 'Move line up' })
map('v', '<M-j>', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
map('v', '<M-k>', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- Escape to clear search highlight
map('n', '<Esc>', '<Cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
