local opt, g, wo, o = vim.opt, vim.g, vim.wo, vim.o

g.root_spec = {
	"lsp",
	{
		".git",--[[add folder or filename pattern here if needed]]
		"lua",
        "Makefile"
	},
	"cwd",
}

opt.swapfile = false
opt.clipboard = "unnamedplus"
opt.list = true
opt.mouse = "a"
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.showmode = false
opt.termguicolors = true
opt.updatetime = 150
opt.cursorcolumn = true
opt.wildmode = "longest:full,full"
opt.guifont = {
	"Iosevka_NF_Medium",
	"Symbols_Nerd_Font",
	"Noto_Color_Emoji",
}
opt.sessionoptions = {
	"buffers",
	"curdir",
	"tabpages",
	"winsize",
	"help",
	"globals",
	"skiprtp",
	"folds",
}

opt.ignorecase = true
opt.smartcase = true

opt.scrolloff = 10
opt.sidescrolloff = 8
opt.smoothscroll = true

opt.autowrite = true
opt.autowriteall = true

opt.showtabline = 0
opt.cmdheight = 0
opt.laststatus = 3

-- opt.textwidth = 80
opt.winminwidth = 5
opt.wrap = false

opt.splitbelow = true
opt.splitkeep = "screen"
opt.splitright = true

opt.undofile = true
opt.undolevels = 10000

opt.fillchars = {
	foldopen = "",
	foldclose = "",
	fold = " ",
	foldsep = " ",
	diff = "╱",
	eob = " ",
}

if vim.fn.executable("rg") == 1 then
	opt.grepprg = "rg --vimgrep --no-heading --smart-case"
	opt.grepformat = "%f:%l:%c:%m,%f:%l:%m"
end

opt.spellfile = {
	vim.fn.stdpath("config") .. "/spell/en.utf-8.add",
	vim.fn.stdpath("config") .. "/spell/id.utf-8.add",
}
opt.spelllang = { "en_us", "id" }

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

opt.formatoptions = "jcroqlnt" -- tcqj

-- Cursor shape
opt.guicursor = {
	"i-c-ci-ve:blinkoff500-blinkon500-block-TermCursor",
	"n-v:block-Cursor/lCursor",
	"o:hor50-Cursor/lCursor",
	"r-cr:hor20-Cursor/lCursor",
}

local function _rshada()
	vim.cmd.set("shada&")
	vim.cmd.rshada()
	return true
end

opt.shada = ""
vim.defer_fn(_rshada, 100)
vim.api.nvim_create_autocmd("BufReadPre", { once = true, callback = _rshada })

wo.cursorline = true
wo.cursorlineopt = "both"
wo.colorcolumn = "80,120"
wo.conceallevel = 2
wo.concealcursor = "nc"
wo.number = true
wo.relativenumber = true
wo.signcolumn = "yes:1"

o.timeout = true
o.timeoutlen = 300
o.shell = "/usr/bin/zsh"
o.mousescroll = "ver:1,hor:6"
o.inccommand = "nosplit"
o.completeopt = "menu,menuone,noinsert"
o.confirm = true
o.diffopt = "internal,filler,closeoff,foldcolumn:1,hiddenoff,algorithm:histogram,linematch:60"
o.infercase = true
o.pumblend = 0
o.pumheight = 10
o.virtualedit = "block"
o.whichwrap = "b,h,l"

o.foldcolumn = "1" -- '0' is not bad
o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
o.foldlevelstart = 99
o.foldenable = true
o.foldmethod = "manual"

g.netrw_banner          = 0
g.netrw_cursor          = 5
g.netrw_keepdir         = 0
g.netrw_keepj           = ''
g.netrw_list_hide       = [[\(^\|\s\s\)\zs\.\S\+]]
g.netrw_liststyle       = 1
g.netrw_localcopydircmd = 'cp -r'

g.markdown_recommended_style = 1
g.border = "single"
g.db_ui_use_nerd_fonts = 1
g.db_ui_winwidth = 45
