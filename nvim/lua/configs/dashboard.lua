local logo = string.rep("\n", 2) .. require("utils.icons").logo .. "\n\n"
local opts = {
	theme = "doom",
	hide = { statusline = true, winbar = true },
	config = {
		header = vim.split(logo, "\n"),
		center = {
			{
				action = "lua require('fzf-lua').files({fzf_opts = {['--info'] = 'right'}})",
				desc = " Find Files",
				icon = " ",
				key = "f",
			},
			{
				action = "lua require('fzf-lua').oldfiles({fzf_opts = {['--info'] = 'right'}})",
				desc = " Old Files",
				icon = "󰼨 ",
				key = "p",
			},
			{ action = "Oil", desc = " File Explorer", icon = "󱇧 ", key = "o" },
			{ action = "ToggleTerm", desc = " Open Terminal", icon = " ", key = "t" },
			{
				action = "lua require'harpoon'.ui:toggle_quick_menu(require'harpoon':list('files'))",
				desc = " Marks",
				icon = "󱪾 ",
				key = "m",
			},
			{ action = "Lazy", desc = " Lazy", icon = "󰒲 ", key = "l" },
			{ action = "qa", desc = " Quit", icon = " ", key = "q" },
		},
		footer = function()
			local stats = require("lazy").stats()
			return {
				string.format(
					"⚡ Neovim loaded %s/%s plugins in %s ms",
					stats.loaded,
					stats.count,
					(math.floor(stats.startuptime * 100 + 0.5) / 100)
				),
			}
		end,
	},
}

for _, button in ipairs(opts.config.center) do
	button.desc = button.desc .. string.rep(" ", 43 - #button.desc)
	button.key_format = "  %s"
end
-- close Lazy and re-open when the dashboard is ready

if vim.o.filetype == "lazy" then
	vim.cmd.close()
	vim.api.nvim_create_autocmd("User", {
		pattern = "DashboardLoaded",
		callback = function()
			require("lazy").show()
		end,
	})
end

return require("dashboard").setup(opts)
