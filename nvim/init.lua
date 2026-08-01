vim.loader.enable(true)

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cmdheight = 0
opt.clipboard = "unnamedplus"


vim.pack.add({ 'https://github.com/saghen/blink.lib', 'https://github.com/saghen/blink.cmp' })
local cmp = require('blink.cmp')
cmp.build():pwait()
cmp.setup()


vim.lsp.config['lua_ls'] = {
	cmd = { 'lua-language-server' },
	filetypes = { 'lua' },
	root_markers = {},
	settings = {
		Lua = {
			runtime = {
				version = 'LuaJIT',
			}
		}
	}
}

vim.lsp.enable('lua_ls')


