vim.opt.cmdheight = 0
vim.opt.colorcolumn = "90,120"
vim.opt.showtabline = 0
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.swapfile = false
vim.opt.pumblend = 0
vim.opt.spell = true
vim.opt.smoothscroll = true

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

vim.opt.backup = true
vim.opt.backupdir:remove(".")

vim.g.bigfile_size = 1024 * 1024 * 1 -- 1.5 MB
vim.g.lazyvim_picker = "fzf"
vim.g.lazyvim_prettier_needs_config = false
vim.g.lazyvim_statuscolumn = { folds_open = false, folds_githl = true }
vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"
vim.g.lazyvim_php_lsp = "phpactor"
vim.g.border = "single"
vim.g.cmp_item_kinds = {
    Method = 1,
    Function = 2,
    Constructor = 3,
    Field = 4,
    Variable = 5,
    Class = 6,
    Interface = 7,
    Module = 8,
    Property = 9,
    Unit = 10,
    Value = 11,
    Enum = 12,
    Keyword = 13,
    Snippet = 14,
    Color = 15,
    File = 16,
    Reference = 17,
    Folder = 18,
    EnumMember = 19,
    Constant = 20,
    Struct = 21,
    Event = 22,
    Operator = 23,
    TypeParameter = 24,
}
