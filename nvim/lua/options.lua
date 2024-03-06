local opt, g, wo, o = vim.opt, vim.g, vim.wo, vim.o

return {
	setup = function()
		opt.swapfile = false
		opt.scrolloff = 8
		opt.clipboard = "unnamedplus"
		opt.textwidth = 80
		opt.jumpoptions = "stack"
		opt.showtabline = 0
		opt.cmdheight = 0
		opt.autowrite = true
		opt.autowriteall = true
		opt.laststatus = 3
		opt.list = true
		opt.mouse = "a"
		opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
		opt.shortmess:append({ W = true, I = true, c = true, C = true })
		opt.showmode = false
		opt.sidescrolloff = 8
		opt.splitbelow = true
		opt.splitkeep = "screen"
		opt.splitright = true
		opt.termguicolors = true
		opt.undofile = true
		opt.undolevels = 9999
		opt.updatetime = 150
		opt.wildmode = "longest:full,full"
		opt.winminwidth = 5
		opt.wrap = false
		opt.fillchars = { foldopen = "", foldclose = "", fold = " ", foldsep = " ", diff = "╱", eob = " " }
		opt.smoothscroll = true
		opt.switchbuf = "useopen,uselast"
		opt.synmaxcol = 300
		opt.visualbell = true
		opt.cursorcolumn = true
		opt.guifont = { "Iosevka_NF_Medium", "Symbols_Nerd_Font", "Noto_Color_Emoji" }

		opt.foldlevel = 99
		opt.foldlevelstart = 99
		opt.foldmethod = "expr"
		opt.foldtext = "v:lua.require'utils'.fold_text()"
		opt.foldexpr = "v:lua.require'utils'.fold_expr()"

		if vim.fn.executable("rg") == 1 then
			opt.grepprg = "rg --vimgrep --no-heading --smart-case"
			opt.grepformat = "%f:%l:%c:%m,%f:%l:%m"
		end

		-- yang di prioritaskan adalah file pertama yaitu id.utf-8.add
		opt.spellfile = vim.fn.stdpath("config") .. "/spell/id.utf-8.add"
		-- opt.spellfile = vim.fn.stdpath("config") .. "/spell/en_us.utf-8.add"
		opt.spelllang = { "en_us", "id" }

		opt.ts = 4
		opt.softtabstop = 4
		opt.shiftwidth = 4
		opt.expandtab = true
		opt.smartindent = true
		opt.autoindent = true

		opt.formatoptions = "jcroqlnt" -- tcqj

		wo.cursorline = true
		wo.cursorlineopt = "both"
		wo.colorcolumn = "80,120"
		wo.conceallevel = 3
		wo.concealcursor = "nc"
		wo.number = true
		wo.relativenumber = true
		wo.signcolumn = "yes:1"

		o.timeout = true
		o.timeoutlen = 300
		o.smartcase = true
		o.shell = "/usr/bin/zsh"
		o.mousescroll = "ver:1,hor:6"
		o.ignorecase = true
		o.inccommand = "nosplit"
		o.completeopt = "menu,menuone,noinsert"
		o.confirm = true
		o.diffopt = "internal,filler,closeoff,foldcolumn:1,hiddenoff,algorithm:histogram,linematch:60"
		o.infercase = true
		o.pumblend = 0
		o.pumheight = 10
		o.viewoptions = ""
		o.virtualedit = "onemore"
		o.whichwrap = "b,h,l"

		g.markdown_recommended_style = 0
		g.border = "single"
		g.db_ui_use_nerd_fonts = 1
		g.db_ui_winwidth = 45
	end,
}
