vim.opt.cmdheight = 0
vim.opt.colorcolumn = "90,120"
vim.opt.showtabline = 0
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.swapfile = false
vim.opt.pumblend = 0
vim.opt.spell = true

vim.opt.spellcapcheck = ""
vim.opt.spelllang = "en"
vim.opt.spelloptions = "camel"
vim.opt.spellsuggest = "best,9"

vim.opt.gcr = {
    "i-c-ci-ve:blinkoff500-blinkon500-block-TermCursor",
    "n-v:block-Curosr/lCursor",
    "o:hor50-Curosr/lCursor",
    "r-cr:hor20-Curosr/lCursor",
}

vim.opt.backup = true
vim.opt.backupdir:remove(".")

vim.g.lazyvim_picker = "fzf"
vim.g.lazyvim_statuscolumn = {
    folds_open = false,
    folds_githl = true,
}
