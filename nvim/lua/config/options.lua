vim.g.deprecation_warnings = true

vim.opt.cmdheight = 0
vim.opt.colorcolumn = "90,120"
vim.opt.showtabline = 0
vim.opt.scrolloff = 21
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.swapfile = false
vim.opt.pumblend = 0
vim.opt.spell = true
vim.opt.smoothscroll = true
vim.opt.pumheight = 15

vim.opt.spellcapcheck = ""
vim.opt.spelllang = "en"
vim.opt.spelloptions = "camel"
vim.opt.spellsuggest = "best,9"

vim.opt.shell = "/usr/bin/fish"

vim.opt.guicursor = {
    "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50",
    "a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor",
    "sm:block-blinkwait175-blinkoff150-blinkon175",
}

vim.opt.listchars = {
    tab = "▏ ",
    trail = "·",
    nbsp = "␣",
}

vim.opt.fillchars = {
    fold = "·",
    foldsep = " ",
    eob = " ",
    foldopen = "",
    foldclose = "",
    diff = "╱",
}

vim.opt.diffopt:append({ "algorithm:histogram", "indent-heuristic" })

vim.opt.backup = true
vim.opt.backupdir:remove(".")

vim.g.lazyvim_picker = "fzf"
vim.g.border = "rounded"

vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"
vim.g.lazyvim_rust_diagnostics = "bacon-ls"

vim.g.lazyvim_prettier_needs_config = false
