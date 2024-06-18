return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			style = "night",
			light_style = "day",
			transparent = false,
			terminal_colors = true,
			sidebars = { "qf", "help", "harpoon" },
			on_highlights = function(hl, c)
				local util = require("tokyonight.util")

				hl.Visual = { bg = c.bg_visual, bold = true, italic = true }
				hl.VisualNOS = { bg = c.bg_visual, bold = true, italic = true }
				hl.WinBar = { bg = c.bg_statusline, underline = true, sp = c.blue2 }
				hl.WinBarNC = { link = "WinBar" }
				hl.PmenuSel = { bg = util.darken(c.purple, 0.4), bold = true }
				hl.StatusLine = { bg = c.bg_statusline }
				hl.TreesitterContext = { underline = true, sp = util.darken(c.purple, 0.7) }
				hl.LineNr = { fg = util.darken(c.purple, 0.6), bg = c.none, bold = true }
				hl.CursorLineNr = { fg = c.cyan, bg = c.none, bold = true }
				hl.FloatBorder = { link = "FzfLuaBorder" }
				hl.WinSeparator = { link = "Comment" }

				hl.DashboardHeader = { fg = c.cyan1, bg = c.none }
				hl.DashboardIcon = { fg = c.yellow1, bg = c.none }
				hl.DashboardFooter = { fg = c.green2, bg = c.none, bold = true }
				hl.DashboardDesc = { fg = c.grey, bg = c.none, bold = true }
				hl.DashboardKey = { fg = c.magenta2, bg = c.none, bold = true }

				hl.FzfLuaBorder = { bg = c.bg_statusline, fg = c.bg_statusline }
				-- hl.FzfLuaNormal = { link = "Normal" }

				hl.IlluminatedWordText = { italic = true, bold = true, reverse = true }
				hl.IlluminatedWordRead = { italic = true, bold = true, reverse = true }
				hl.IlluminatedWordWrite = { italic = true, bold = true, reverse = true }
				hl.LspReferenceText = { italic = true, bold = true, reverse = true }
				hl.LspReferenceRead = { italic = true, bold = true, reverse = true }
				hl.LspReferenceWrite = { italic = true, bold = true, reverse = true }
				hl.LspSignatureActiveParameter = { italic = true, bold = true, reverse = true }
				hl.LspCodeLens = { link = "DiagnosticVirtualTextHint", default = true }
				hl.LspCodeLensText = { link = "DiagnosticVirtualTextHint", default = true }
				hl.LspCodeLensSign = { link = "DiagnosticVirtualTextHint", default = true }
				hl.LspCodeLensSeparator = { link = "Boolean", default = true }
				hl.LspInlayHint = { fg = c.comment, underline = true, sp = util.darken(c.purple1, 0.8) }

				hl.OilDir = { fg = c.orange, bg = c.none, bold = true }
				hl.OilDirIcon = { fg = c.orange, bg = c.none }
				hl.OilLink = { link = "Constant" }
				hl.OilLinkTarget = { link = "Comment" }
				hl.OilCopy = { link = "DiagnosticSignHint", bold = true }
				hl.OilMove = { link = "DiagnosticSignWarn", bold = true }
				hl.OilChange = { link = "DiagnosticSignWarn", bold = true }
				hl.OilCreate = { link = "DiagnosticSignInfo", bold = true }
				hl.OilDelete = { link = "DiagnosticSignError", bold = true }
				hl.OilPermissionNone = { link = "NonText" }
				hl.OilPermissionRead = { fg = c.red1, bg = c.none, bold = true }
				hl.OilPermissionWrite = { fg = util.lighten(c.yellow, 0.5), bg = c.none, bold = true }
				hl.OilPermissionExecute = { fg = c.teal, bg = c.none, bold = true }
				hl.OilTypeDir = { link = "Directory" }
				hl.OilTypeFifo = { link = "Special" }
				hl.OilTypeFile = { link = "NonText" }
				hl.OilTypeLink = { link = "Constant" }
				hl.OilTypeSocket = { link = "OilSocket" }
			end,
			on_colors = function(c)
				c.green2 = "#2bff05"
				c.yellow1 = "#faf032"
				c.cyan1 = "#00ffee"
				c.purple1 = "#f242f5"
				c.red2 = "#eb0000"
				c.black1 = "#000000"
			end,
		},
		config = function(_, opts)
			require("tokyonight").setup(opts)
			vim.cmd.colorscheme("tokyonight")
		end,
	},

	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"rcarriga/nvim-notify",
			opts = {
				stages = "fade_in_slide_out",
				render = "wrapped-compact",
				timeout = 3000,
				max_height = function()
					return math.floor(vim.o.lines * 0.75)
				end,
				max_width = function()
					return math.floor(vim.o.columns * 0.75)
				end,
				on_open = function(win)
					vim.api.nvim_win_set_config(win, { zindex = 100 })
				end,
			},
			init = function()
				require("utils").on_very_lazy(function()
					vim.notify = require("notify")
				end)
			end,
		},
		keys = {
            -- stylua: ignore start
			{ "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline", },
			{ "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message", },
			{ "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History", },
			{ "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All", },
			{ "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All", },
			{ "<leader>snt", function() require("noice").cmd("pick") end, desc = "Noice Picker (Telescope/FzfLua)", },
			{ "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "Scroll Forward", mode = { "i", "n", "s" }, },
			{ "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "Scroll Backward", mode = { "i", "n", "s" }, },
			-- stylua: ignore end
		},
		opts = {
			cmdline = { view = "cmdline", format = { input = { view = "cmdline" } } },
			popupmenu = { enabled = false },
			lsp = {
				signature = {
					enabled = true,
					auto_open = { enabled = true, trigger = true, luasnip = true, throttle = 100 },
					view = "hover",
					opts = {
						win_options = {
							concealcursor = vim.wo.concealcursor,
							conceallevel = vim.wo.conceallevel,
						},
						position = { row = 2, col = 0 },
					},
				},
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
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
						any = {
							{ find = "%d+L, %d+B" },
							{ find = "; after #%d+" },
							{ find = "; before #%d+" },
						},
					},
					view = "mini",
				},
			},
			smart_move = { enabled = true, excluded_filetypes = { "cmp_menu", "cmp_docs", "notify" } },
			views = {
				hover = {
					border = { style = vim.g.border },
					padding = { 0, 0 },
					win_options = {
						concealcursor = vim.wo.concealcursor,
						conceallevel = vim.wo.conceallevel,
						wrap = true,
						linebreak = true,
						winhighlight = {
							FloatBorder = "FzfLuaBorder",
						},
					},
					position = { row = 2, col = 0 },
					lang = "markdown",
					size = { max_width = 80, max_height = 13 },
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				inc_rename = true,
				lsp_doc_border = false,
			},
		},
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "BufReadPre",
		opts = function()
			return {
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
					filetypes = {
						"help",
						"alpha",
						"dashboard",
						"neo-tree",
						"Trouble",
						"trouble",
						"lazy",
						"mason",
						"notify",
						"toggleterm",
						"lazyterm",
					},
				},
			}
		end,
		config = function(_, opts)
			local ibl = require("ibl")
			local hooks = require("ibl.hooks")
			ibl.setup(opts)
			hooks.register(hooks.type.ACTIVE, function(bufnr)
				return vim.api.nvim_buf_line_count(bufnr) < 5000
			end)
		end,
		main = "ibl",
	},
	{
		"nvimdev/dashboard-nvim",
		lazy = false, -- As https://github.com/nvimdev/dashboard-nvim/pull/450, dashboard-nvim shouldn't be lazy-loaded to properly handle stdin.
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
				hide = {
					-- this is taken care of by lualine
					-- enabling this messes up the actual laststatus setting after loading a file
					statusline = false,
				},
				config = {
					header = vim.split(logo, "\n"),
					center = {
                        -- stylua: ignore start
						{ action = "FzfLua files", desc = " Find Files", icon = " ", key = "f", },
						{ action = "FzfLua oldfiles", desc = " Old Files", icon = "󰼨 ", key = "p", },
						{ action = "Oil", desc = " File Explorer", icon = "󱇧 ", key = "o" },
						{ action = "ToggleTerm", desc = " Open Terminal", icon = " ", key = "t" },
						{ action = "lua require'harpoon'.ui:toggle_quick_menu(require'harpoon':list())", desc = " Marks", icon = "󱪾 ", key = "m", },
						{ action = "Lazy", desc = " Lazy", icon = "󰒲 ", key = "l" },
						{ action = "qa", desc = " Quit", icon = " ", key = "q" },
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
		"SmiteshP/nvim-navic",
		lazy = true,
		init = function()
			vim.g.navic_silence = true
			require("utils").lsp.on_attach(function(client, buffer)
				if client.supports_method("textDocument/documentSymbol") then
					require("nvim-navic").attach(client, buffer)
				end
			end)
		end,
		opts = function()
			return {
				highlight = true,
				icons = require("utils").icons.kinds,
				lazy_update_context = true,
			}
		end,
	},
	{
		"NvChad/nvim-colorizer.lua",
		event = "BufRead",
		opts = {
			user_default_options = {
				RGB = true, -- #RGB hex codes
				RRGGBB = true, -- #RRGGBB hex codes
				names = false, -- "Name" codes like Blue or blue
				RRGGBBAA = true, -- #RRGGBBAA hex codes
				AARRGGBB = true, -- 0xAARRGGBB hex codes
				css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
				css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
				mode = "virtualtext", -- Set the display mode.
				tailwind = true, -- Enable tailwind colors
				sass = { enable = false, parsers = { "css" } }, -- Enable sass colors
				virtualtext = " ",
				always_update = false,
			},
			buftypes = {},
		},
	},
	{
		"Bekaboo/deadcolumn.nvim",
		event = "InsertEnter",
		opts = {
			scope = "line", ---@type string|fun(): integer
			modes = function(mode)
				return mode:find("^[ictRss\x13]") ~= nil
			end,
		},
		config = function(_, opts)
			vim.wo.colorcolumn = "80,120"
			require("deadcolumn").setup(opts)
		end,
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,

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
}
