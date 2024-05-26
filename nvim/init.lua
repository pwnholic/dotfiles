vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.g.loaded_2html_plugin = 0
vim.g.loaded_gzip = 0
vim.g.loaded_matchit = 0
vim.g.loaded_tar = 0
vim.g.loaded_tarPlugin = 0
vim.g.loaded_tutor_mode_plugin = 0
vim.g.loaded_zip = 0
vim.g.loaded_zipPlugin = 0

vim.env.PATH = vim.fn.stdpath("data")
	.. "/mason/bin"
	.. (vim.uv.os_uname().sysname == "Windows_NT" and ";" or ":")
	.. vim.env.PATH

require("core.options")
require("core.package")

package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua"
package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua"

vim.api.nvim_create_autocmd("User", {
	group = vim.api.nvim_create_augroup("OnMales", { clear = true }),
	pattern = "VeryLazy",
	callback = function()
		require("utils.root").setup()
		require("core.autocmds")
		require("core.keymaps")
		require("core.commands")
	end,
})

-- ===================================================================== --
--                               DEFAULT
-- ===================================================================== --

-- vim.g.mapleader = " "
-- vim.g.maplocalleader = "\\"
--
-- vim.cmd.colorscheme("retrobox")
--
-- vim.opt.showtabline = 0
-- vim.opt.cmdheight = 0
-- vim.opt.autowrite = true
-- vim.opt.autowriteall = true
-- vim.opt.clipboard = "unnamedplus"
-- vim.opt.completeopt = "menu,menuone,noselect"
-- vim.opt.cursorline = true
-- vim.opt.expandtab = true
-- vim.opt.formatoptions = "jcroqlnt"
-- vim.opt.ignorecase = true
-- vim.opt.laststatus = 3
-- vim.opt.list = true
-- vim.opt.listchars = { tab = "  " }
-- vim.opt.mouse = "a"
-- vim.opt.number = true
-- vim.opt.pumblend = 0
-- vim.opt.pumheight = 10
-- vim.opt.relativenumber = true
-- vim.opt.scrolloff = 4
-- vim.opt.shiftround = true
-- vim.opt.shiftwidth = 4
-- vim.opt.showmode = false
-- vim.opt.sidescrolloff = 8
-- vim.opt.signcolumn = "yes"
-- vim.opt.smartcase = true
-- vim.opt.smartindent = true
-- vim.opt.spelllang = { "en" }
-- vim.opt.splitbelow = true
-- vim.opt.splitright = true
-- vim.opt.tabstop = 4
-- vim.opt.termguicolors = true
-- vim.opt.undofile = true
-- vim.opt.undolevels = 10000
-- vim.opt.virtualedit = "block"
-- vim.opt.wildmode = "longest:full,full"
-- vim.opt.winminwidth = 5
-- vim.opt.wrap = false
-- vim.opt.smoothscroll = true
-- vim.opt.cursorcolumn = true
--
-- vim.g.netrw_banner = 0
-- vim.g.netrw_cursor = 5
-- vim.g.netrw_keepdir = 0
-- vim.g.netrw_keepj = ""
-- vim.g.netrw_list_hide = [[\(^\|\s\s\)\zs\.\S\+]]
-- vim.g.netrw_liststyle = 1
-- vim.g.netrw_localcopydircmd = "cp -r"
--
-- local map = vim.keymap.set
--
-- map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
-- map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
-- map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
-- map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
--
-- -- Move to window using the <ctrl> hjkl keys
-- map("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
-- map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
-- map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
-- map("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })
--
-- -- Resize window using <ctrl> arrow keys
-- map("n", "<C-Up>", "<cmd>resize -2<cr>", { desc = "Increase window height" })
-- map("n", "<C-Down>", "<cmd>resize +2<cr>", { desc = "Decrease window height" })
-- map("n", "<C-Left>", "<cmd>vertical resize +2<cr>", { desc = "Decrease window width" })
-- map("n", "<C-Right>", "<cmd>vertical resize -2<cr>", { desc = "Increase window width" })
--
-- -- Move Lines
-- map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
-- map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
-- map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
-- map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
-- map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
-- map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })
--
-- -- buffers
-- map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
-- map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
-- map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
-- map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
--
-- -- Clear search with <esc>
-- map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })
--
-- -- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
-- map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next search result" })
-- map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
-- map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
-- map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev search result" })
-- map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
-- map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
--
-- -- Add undo break-points
-- map("i", ",", ",<c-g>u")
-- map("i", ".", ".<c-g>u")
-- map("i", ";", ";<c-g>u")
--
-- map("v", "<", "<gv")
-- map("v", ">", ">gv")
--
-- map("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
-- map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })
--
-- map("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" })
-- map("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })
--
-- -- highlights under cursor
-- map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
--
-- -- Terminal Mappings
-- map("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })
-- map("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to left window" })
-- map("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to lower window" })
-- map("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to upper window" })
-- map("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to right window" })
-- map("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
-- map("t", "<c-_>", "<cmd>close<cr>", { desc = "which_key_ignore" })
--
-- -- windows
-- map("n", "<leader>ww", "<C-W>p", { desc = "Other window", remap = true })
-- map("n", "<leader>wd", "<C-W>c", { desc = "Delete window", remap = true })
-- map("n", "<leader>w-", "<C-W>s", { desc = "Split window below", remap = true })
-- map("n", "<leader>w|", "<C-W>v", { desc = "Split window right", remap = true })
-- map("n", "<leader>-", "<C-W>s", { desc = "Split window below", remap = true })
-- map("n", "<leader>|", "<C-W>v", { desc = "Split window right", remap = true })
--
-- map("n", "<leader>e", "<cmd>Ex<cr>")
-- map("n", "<leader>ff", "<cmd>FZF<cr>")
-- map("n", "<leader>/", "<cmd>botright term<cr>")
--
-- map("n", "<leader><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
-- map("n", "<leader>dt", "<cmd>tabclose<cr>", { desc = "Close Tab" })
-- map("n", "<leader>1", "1gt", { desc = "Go to tab 1" })
-- map("n", "<leader>2", "2gt", { desc = "Go to tab 2" })
-- map("n", "<leader>3", "3gt", { desc = "Go to tab 3" })
-- map("n", "<leader>4", "4gt", { desc = "Go to tab 4" })
-- map("n", "<leader>5", "5gt", { desc = "Go to tab 5" })
-- map("n", "<leader>6", "6gt", { desc = "Go to tab 6" })
-- map("n", "<leader>7", "7gt", { desc = "Go to tab 7" })
-- map("n", "<leader>8", "8gt", { desc = "Go to tab 8" })
-- map("n", "<leader>9", "9gt", { desc = "Go to tab 9" })
--
-- map("n", "gQ", "mzgggqG`z<cmd>delmarks z<cr>zz")
--
-- vim.api.nvim_create_autocmd("TermOpen", {
-- 	pattern = "term://*",
-- 	callback = function()
-- 		vim.o.signcolumn = "no"
-- 		vim.o.nu = false
-- 		vim.o.rnu = false
-- 		vim.o.stc = nil
-- 	end,
-- })
