return {
	{
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

			logo = string.rep("\n", 1.5) .. logo .. "\n\n"

			local opts = {
				theme = "doom",
				hide = {
					statusline = false,
				},
				config = {
					header = vim.split(logo, "\n"),
					center = {
						{ action = "lua LazyVim.pick()()", desc = " Find File", icon = " ", key = "f" },
						{ action = "ene | startinsert", desc = " New File", icon = " ", key = "n" },
						{
							action = 'lua LazyVim.pick("oldfiles")()',
							desc = " Recent Files",
							icon = " ",
							key = "r",
						},
						{
							action = 'lua LazyVim.pick("live_grep")()',
							desc = " Find Text",
							icon = " ",
							key = "g",
						},
						{
							action = "lua LazyVim.pick.config_files()()",
							desc = " Config",
							icon = " ",
							key = "c",
						},
						{
							action = 'lua require("persistence").load()',
							desc = " Restore Session",
							icon = " ",
							key = "s",
						},
						{
							action = "LazyExtras",
							desc = " Lazy Extras",
							icon = " ",
							key = "x",
						},
						{
							action = "Lazy",
							desc = " Lazy",
							icon = "󰒲 ",
							key = "l",
						},
						{
							action = function()
								vim.api.nvim_input("<cmd>qa<cr>")
							end,
							desc = " Quit",
							icon = " ",
							key = "q",
						},
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
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "LazyFile",
		opts = function()
			return {
				indent = { char = "▏", tab_char = "▏" },
				scope = {
					enabled = true,
					show_exact_scope = false,
					highlight = {
						"@markup.heading.1.markdown",
						"@markup.heading.2.markdown",
						"@markup.heading.3.markdown",
						"@markup.heading.4.markdown",
						"@markup.heading.5.markdown",
						"@markup.heading.6.markdown",
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
				hl.WinSeparator = { link = "Comment" }
				hl.FloatBorder = { fg = c.bg_statusline, bg = c.bg_statusline }

				hl.DashboardHeader = { fg = c.cyan1, bg = c.none }
				hl.DashboardIcon = { fg = c.yellow1, bg = c.none }
				hl.DashboardFooter = { fg = c.green2, bg = c.none, bold = true }
				hl.DashboardDesc = { fg = c.grey, bg = c.none, bold = true }
				hl.DashboardKey = { fg = c.magenta2, bg = c.none, bold = true }

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
				hl.OilPermissionWrite = { fg = c.yellow, bg = c.none, bold = true }
				hl.OilPermissionExecute = { fg = c.teal, bg = c.none, bold = true }
				hl.OilTypeDir = { link = "Directory" }
				hl.OilTypeFifo = { link = "Special" }
				hl.OilTypeFile = { link = "NonText" }
				hl.OilTypeLink = { link = "Constant" }
				hl.OilTypeSocket = { link = "OilSocket" }
				hl.OilSize = { fg = c.blue2, bg = c.none }
				hl.OilMtime = { fg = c.purple, bg = c.none }
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
		opts = {
			cmdline = { view = "cmdline", format = { input = { view = "cmdline" } } },
			popupmenu = { enabled = false },
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
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
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
			},
		},
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			icons = { breadcrumb = "  ", separator = "  ", group = " 󱡠 " },
		},
	},
	{
		"NvChad/nvim-colorizer.lua",
		event = "LazyFile",
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
		event = "LazyFile",
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
}
