vim.opt.showtabline = 0
vim.opt.cmdheight = 0
vim.opt.colorcolumn = "90,120"
vim.opt.cursorcolumn = true
vim.opt.scrolloff = 21
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.swapfile = false
vim.opt.pumblend = 0
vim.opt.spell = true
vim.opt.smoothscroll = true
vim.opt.pumheight = 15
vim.opt.helpheight = 10
vim.opt.timeout = false
vim.opt.mousemoveevent = true
vim.opt.ruler = true
vim.opt.selection = "old"
vim.opt.tabclose = "uselast"
vim.opt.wrap = false

vim.opt.spellcapcheck = ""
vim.opt.spelllang = "en"
vim.opt.spelloptions = "camel"
vim.opt.spellsuggest = "best,9"

---@diagnostic disable-next-line: undefined-field
vim.opt.shell = vim.uv.os_uname().sysname == "Linux" and os.getenv("SHELL") or "/usr/bin/fish"

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

local shada_augroup = vim.api.nvim_create_augroup("OptShada", {})
local function rshada()
    pcall(vim.api.nvim_del_augroup_by_id, shada_augroup)
    vim.opt.shada = vim.api.nvim_get_option_info2("shada", {}).default
    pcall(vim.cmd.rshada)
end

vim.opt.shada = ""
vim.api.nvim_create_autocmd("UIEnter", { group = shada_augroup, once = true, callback = vim.schedule_wrap(rshada) })
vim.api.nvim_create_autocmd("BufReadPre", { group = shada_augroup, once = true, callback = rshada })

vim.g.border = "single"
