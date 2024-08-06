vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.cmdheight = 0
vim.opt.autoindent = true
vim.opt.autowrite = true -- Enable auto write
vim.opt.autowriteall = true
vim.opt.breakindent = true
vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus" -- Sync with system clipboard
vim.opt.colorcolumn = "+1"
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.conceallevel = 2
vim.opt.confirm = true -- Confirm to save changes before exiting modified buffer
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"
vim.opt.expandtab = true
vim.opt.fillchars = { foldopen = "", foldclose = "", fold = " ", foldsep = " ", diff = "╱", eob = " " }
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.smoothscroll = true
vim.opt.foldexpr = "v:lua.require'utils.stc'.foldexpr()"
vim.opt.foldmethod = "expr"
vim.opt.foldtext = ""
vim.opt.formatoptions = "jcroqlnt" -- tcqj
vim.opt.grepformat = "%f:%l:%c:%m"
vim.opt.grepprg = "rg --vimgrep"
vim.opt.helpheight = 10
vim.opt.ignorecase = true
vim.opt.inccommand = "nosplit" -- preview incremental substitute
vim.opt.jumpoptions = "stack,view"
vim.opt.laststatus = 3 -- global statusline
vim.opt.linebreak = true
vim.opt.list = true -- Show some invisible characters (tabs...
vim.opt.listchars = { tab = "▏ ", trail = "·", nbsp = "␣" }
vim.opt.mouse = "a" -- Enable mouse mode
vim.opt.mousemoveevent = true
vim.opt.number = true
vim.opt.pumblend = 0 -- Popup blend
vim.opt.pumheight = 10 -- Maximum number of entries in a popup
vim.opt.relativenumber = true -- Relative line numbers
vim.opt.ruler = true
vim.opt.scrolloff = 4
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
vim.opt.shiftround = true -- Round indent
vim.opt.shiftwidth = 4
vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
vim.opt.showmode = false
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
vim.opt.smartcase = true
vim.opt.smartindent = true -- Insert indents automatically
vim.opt.softtabstop = 4
vim.opt.spelllang = { "en" }
vim.opt.spelloptions:append("noplainbuffer")
vim.opt.splitbelow = true
vim.opt.splitkeep = "screen"
vim.opt.splitright = true
vim.opt.swapfile = false
vim.opt.tabstop = 4
vim.opt.termguicolors = true
vim.opt.timeoutlen = vim.g.vscode and 1000 or 300 -- Lower than default (1000) to quickly trigger which-key
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 200 -- Save swap file and trigger CursorHold
vim.opt.virtualedit = "block"
vim.opt.wildmode = "longest:full,full" -- Command-line completion mode
vim.opt.winminwidth = 5 -- Minimum window width
vim.opt.showtabline = 0
vim.opt.wrap = false

local function _rshada()
	vim.cmd.set("shada&")
	vim.cmd.rshada()
	return true
end

vim.opt.shada = ""
vim.defer_fn(_rshada, 100)
vim.api.nvim_create_autocmd("BufReadPre", { once = true, callback = _rshada })

vim.opt.guicursor = {
	"i-c-ci-ve:blinkoff500-blinkon500-block-TermCursor",
	"n-v:block-Curosr/lCursor",
	"o:hor50-Curosr/lCursor",
	"r-cr:hor20-Curosr/lCursor",
}

for _, provider in ipairs({ "python3", "ruby", "node", "perl" }) do
	vim.g["loaded_" .. provider .. "_provider"] = 0
end

vim.g.markdown_recommended_style = 0
vim.g.border = "rounded"
