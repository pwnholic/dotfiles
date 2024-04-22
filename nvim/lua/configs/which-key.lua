local wk = require("which-key")

wk.setup({
	sort_by_description = true,
	layout = { spacing = 5, align = "left" },
	plugins = { marks = false, register = false },
	icons = { breadcrumb = "  ", separator = "  ", group = "󱡠  " },
	disable = {
		buftypes = { "nofile", "terminal", "prompt", "help", "quickfix" },
		filetypes = { "dashboard", "Trouble", "lazy", "mason", "notify", "toggleterm", "oil", "harpoon" },
	},
})
-- method 3
wk.register({
	["<leader><tab>"] = { name = "󰓩  Tabs" },
	["<leader>df"] = { name = "  UI Float" },
	["<leader>hf"] = { name = "  Git Search" },
	["<leader>ds"] = { name = "  Dap Find" },
	["<leader>t"] = { name = "  Terminal &   Testing" },
	["<leader>f"] = { name = "  Fuzzy Finder" },
	["<leader>h"] = { name = "  Git" },
	["<leader>d"] = { name = "  Debugger" },
	["<leader>x"] = { name = "  Diagnostics &   TODO" },
	["<leader>u"] = { name = "⏼  Toggle Stuff" },
	["<leader>j"] = { name = "󰌝  Languages" },
	["<leader>s"] = { name = "  Search" },
	["<leader>w"] = { name = "  Windows" },
	["<leader>g"] = { name = "  Lsp" },
	["<leader>b"] = { name = "  Buffers" },
	["<leader>k"] = { name = "  Code Mod" },
	["<leader>n"] = { name = "Note" },
	["<leader>r"] = { name = "󰼧  Sessions" },
})
