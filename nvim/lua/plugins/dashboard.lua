return {
	"nvimdev/dashboard-nvim",
	lazy = false,
	opts = function()
		local logo = [[
██████╗  ███████╗ ███╗   ███╗  ██████╗  ██╗  ██╗     ██████╗  ███████╗ ██╗   ██╗
██╔══██╗ ██╔════╝ ████╗ ████║ ██╔═══██╗ ██║ ██╔╝     ██╔══██╗ ██╔════╝ ██║   ██║
██████╔╝ █████╗   ██╔████╔██║ ██║   ██║ █████╔╝      ██║  ██║ █████╗   ██║   ██║
██╔══██╗ ██╔══╝   ██║╚██╔╝██║ ██║   ██║ ██╔═██╗      ██║  ██║ ██╔══╝   ╚██╗ ██╔╝
██║  ██║ ███████╗ ██║ ╚═╝ ██║ ╚██████╔╝ ██║  ██╗     ██████╔╝ ███████╗  ╚████╔╝ 
╚═╝  ╚═╝ ╚══════╝ ╚═╝     ╚═╝  ╚═════╝  ╚═╝  ╚═╝     ╚═════╝  ╚══════╝   ╚═══╝  
    ]]
		logo = string.rep("\n", 2) .. logo .. "\n\n"
		local opts = {
			theme = "doom",
			hide = { statusline = true, statuscolumn = true },
			config = {
				header = vim.split(logo, "\n"),
				center = {
                        -- stylua: ignore start
						{ action = "FzfLua files", desc = " Find File", icon = " ", key = "f" },
						{ action = "ene | startinsert", desc = " New File", icon = " ", key = "n" },
						{ action = "FzfLua oldfiles", desc = " Recent Files", icon = " ", key = "r" },
						{ action = "FzfLua live_grep", desc = " Find Text", icon = " ", key = "g" },
						{ action = "Lazy", desc = " Lazy", icon = "󰒲 ", key = "l" },
						{ action = [[lua vim.api.nvim_input("<cmd>qa<cr>")]], desc = " Quit", icon = " ", key = "q" },
					-- stylua: ignore end
				},
				footer = function()
					local stats = require("lazy").stats()
					local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
					return {
						"⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms",
					}
				end,
			},
		}
		for _, button in ipairs(opts.config.center) do
			button.desc = button.desc .. string.rep(" ", 43 - #button.desc)
			button.key_format = "  %s"
		end
		-- open dashboard after closing lazy
		if vim.o.filetype == "lazy" then
			vim.api.nvim_create_autocmd("WinClosed", {
				pattern = tostring(vim.api.nvim_get_current_win()),
				once = true,
				callback = function()
					vim.schedule(function()
						vim.api.nvim_exec_autocmds("UIEnter", { group = "dashboard" })
					end)
				end,
			})
		end
		return opts
	end,
}
