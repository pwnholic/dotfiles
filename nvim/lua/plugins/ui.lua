return {
	{ "MunifTanjim/nui.nvim", lazy = true },
	{ "NvChad/nvim-colorizer.lua", event = "BufRead", config = true },
	{ "https://gitlab.com/HiPhish/rainbow-delimiters.nvim", event = "BufRead" },
	{
		"nvimdev/dashboard-nvim",
		event = "VimEnter",
		opts = function()
			local logo = string.rep("\n", 2) .. require("icons").logo .. "\n\n"
			local opts = {
				theme = "doom",
				hide = { statusline = true, winbar = true },
				config = {
					header = vim.split(logo, "\n"),
					center = {
                        -- stylua: ignore start
						{ action = "lua require('fzf-lua').files({fzf_opts = {['--info'] = 'right'}})", desc = " Find Files", icon = " ", key = "f", },
						{ action = "lua require('fzf-lua').oldfiles({fzf_opts = {['--info'] = 'right'}})", desc = " Old Files", icon = "󰼨 ", key = "p" },
						{ action = "Oil", desc = " File Explorer", icon = "󱇧 ", key = "o" },
						{ action = "ToggleTerm", desc = " Open Terminal", icon = " ", key = "t" },
						{ action = "lua require'harpoon'.ui:toggle_quick_menu(require'harpoon':list('files'))", desc = " Marks", icon = "󱪾 ", key = "m", },
						{ action = "Lazy", desc = " Lazy", icon = "󰒲 ", key = "l" },
						{ action = "qa", desc = " Quit", icon = " ", key = "q" },
						-- stylua: ignore end
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
			return opts
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "BufRead",
		config = function()
			local ibl, hooks = require("ibl"), require("ibl.hooks")
			ibl.setup({
				indent = { char = "▏", tab_char = "▏" },
				scope = {
					enabled = true,
					show_exact_scope = false,
					highlight = {
						"RainbowDelimiterRed",
						"RainbowDelimiterYellow",
						"RainbowDelimiterBlue",
						"RainbowDelimiterOrange",
						"RainbowDelimiterGreen",
						"RainbowDelimiterViolet",
						"RainbowDelimiterCyan",
					},
				},
				exclude = {
					filetypes = { "help", "dashboard", "Trouble", "lazy", "mason", "notify", "toggleterm", "oil" },
				},
			})
			hooks.register(hooks.type.ACTIVE, function(bufnr)
				return vim.api.nvim_buf_line_count(bufnr) < 5000
			end)
		end,
		main = "ibl",
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			{
				"rcarriga/nvim-notify",
				init = function()
					vim.notify = require("notify")
				end,
				opts = {
					fps = 60,
					timeout = 3000,
					on_open = function(win)
						vim.api.nvim_win_set_config(win, { zindex = 100 })
					end,
					max_height = math.max(10, math.ceil(vim.go.lines * 0.6)),
					max_width = math.max(15, math.ceil(vim.go.columns * 0.35)),
					render = "wrapped-compact",
				},
			},
		},
		config = function()
			require("noice").setup({
				cmdline = { view = "cmdline" },
				popupmenu = { enabled = false },
				lsp = {
					signature = {
						enabled = true,
						auto_open = { enabled = true, trigger = false, luasnip = true, throttle = 100 },
						view = "hover",
						opts = {
							win_options = {
								concealcursor = vim.wo.concealcursor,
								conceallevel = vim.wo.conceallevel,
								wrap = true,
							},
							position = { row = 2, col = 0 },
						},
					},
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true,
					},
					documentation = {
						view = "hover",
						opts = {
							lang = "markdown",
							replace = true,
							render = "plain",
							format = { "{message}" },
							win_options = {
								concealcursor = vim.wo.concealcursor,
								conceallevel = vim.wo.conceallevel,
							},
						},
					},
				},
				markdown = {
					highlights = {
						["|%S-|"] = "@text.reference",
						["@%S+"] = "@parameter",
						["^%s*(Parameters:)"] = "@text.title",
						["^%s*(Return:)"] = "@text.title",
						["^%s*(See also:)"] = "@text.title",
						["{%S-}"] = "@parameter",
					},
				},
				routes = {
					{
						filter = {
							event = "msg_show",
							any = { { find = "%d+L, %d+B" }, { find = "; after #%d+" }, { find = "; before #%d+" } },
						},
						view = "mini",
						opts = { stop = true, skip = true },
					},
				},
				views = {
					popup = {
						border = { style = vim.g.border },
						padding = { 0, 0 },
						size = { max_width = 80, max_height = 15 },
					},
					hover = {
						border = { style = vim.g.border },
						padding = { 0, 0 },
						win_options = {
							concealcursor = vim.wo.concealcursor,
							conceallevel = vim.wo.conceallevel,
							wrap = true,
							linebreak = true,
						},
						position = { row = 2, col = 0 },
						lang = "markdown",
						size = { max_width = 80, max_height = 13 },
					},
				},
				smart_move = { enabled = true, excluded_filetypes = { "cmp_menu", "cmp_docs", "notify" } },
				presets = {
					bottom_search = true,
					command_palette = true,
					long_message_to_split = true,
					inc_rename = false,
					lsp_doc_border = true,
				},
			})
            -- stylua: ignore start
			vim.keymap.set({ "n", "s" }, "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, { silent = true, expr = true })
			vim.keymap.set({ "n", "s" }, "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, { silent = true, expr = true })
			-- stylua: ignore end
		end,
	},
	{
		"folke/which-key.nvim",
		event = "BufRead",
		config = function()
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
		end,
	},
	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
		config = function()
			local c = require("tokyonight.colors").setup()
			require("nvim-web-devicons").setup({
				override_by_filename = {
					["go.mod"] = { icon = "󰏗", color = c.green, name = "gomod_" },
					["go.sum"] = { icon = "", color = c.blue, name = "gomod_" },
				},
				override_by_extension = {
					["env"] = { icon = "", color = c.yellow1, name = "Env_" },
					["example"] = { icon = "󰺖", color = c.yellow, name = "Example_" },
					["http"] = { icon = "", color = c.orange, name = "Http_" },
				},
			})
		end,
	},
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			style = "night",
			transparent = false,
			styles = { sidebars = "normal", floats = "normal" },
			sidebars = {
				"toggleterm",
				"qf",
				"oil",
				"help",
				"terminal",
				"neotest-summary",
				"dashboard",
				"Trouble",
				"lazyterm",
			},
			on_highlights = function(hl_group, color)
				require("hl")(hl_group, color, require("tokyonight.util"))
			end,
			on_colors = function(color)
				color.green2 = "#2bff05"
				color.yellow1 = "#faf032"
				color.cyan1 = "#00ffee"
				color.purple1 = "#f242f5"
				color.red2 = "#eb0000"
				color.black1 = "#000000"
			end,
		},
		config = function(_, opts)
			require("tokyonight").setup(opts)
			vim.cmd.colorscheme("tokyonight-night")
		end,
	},
}
