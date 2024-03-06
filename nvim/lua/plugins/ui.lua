return {
	{ "MunifTanjim/nui.nvim", lazy = true },
	{ "NvChad/nvim-colorizer.lua", event = "BufRead", config = true },
	{ "https://gitlab.com/HiPhish/rainbow-delimiters.nvim", event = "BufRead" },
	{
		"nvimdev/dashboard-nvim",
		event = "VimEnter",
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
						auto_open = { enabled = true, trigger = true, luasnip = true, throttle = 100 },
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
			sidebars = { "toggleterm", "qf", "oil", "help", "terminal", "neotest-summary", "dashboard", "Trouble" },
			on_highlights = function(hl, c)
				local util = require("tokyonight.util")

				hl.Visual = { bg = c.bg_visual, bold = true, italic = true }
				hl.VisualNOS = { bg = c.bg_visual, bold = true, italic = true }
				hl.WinBar = { bg = c.bg_statusline, underline = true, sp = util.darken(c.cyan, 0.7) }
				hl.WinBarNC = { link = "WinBar" }
				hl.PmenuSel = { bg = util.darken(c.purple, 0.4), bold = true }
				hl.StatusLine = { bg = c.bg_statusline }
				hl.TreesitterContext = { underline = true, sp = util.darken(c.purple, 0.7) }
				hl.WinSeparator = { link = "Comment" }
				hl.LineNr = { fg = util.darken(c.purple, 0.6), bg = c.none, bold = true }
				hl.CursorLineNr = { fg = c.cyan, bg = c.none, bold = true, italic = true }
				hl.FloatBorder = { link = "Comment" }

				hl.WhichKey = { fg = c.cyan, bg = c.none, bold = true }
				hl.WhichKeyGroup = { fg = c.orange, bg = c.none, bold = true }

				hl.CmpGhostText = { fg = util.darken(c.yellow, 0.7), bg = c.none, bold = true }
				hl.CmpItemAbbr = { fg = "#ffffff", bg = c.none }
				hl.CmpItemAbbrMatch = { fg = c.cyan1, bg = c.none }
				hl.CmpItemAbbrMatchFuzzy = { fg = c.orange, bg = c.none }

				-- Gitsign
				hl.GitSignsAdd = { fg = c.green2, bg = c.none }
				hl.GitSignsChange = { fg = c.yellow1, bg = c.none }
				hl.GitSignsDelete = { fg = c.red1, bg = c.none }
				hl.GitSignsCurrentLineBlame = { fg = util.darken(c.purple, 0.7), bg = c.none }

				-- Mason
				hl.MasonHeader = { bg = c.red, fg = c.none }
				hl.MasonHighlight = { fg = c.blue }
				hl.MasonHighlightBlock = { fg = c.none, bg = c.green }
				hl.MasonHighlightBlockBold = { link = "MasonHighlightBlock" }
				hl.MasonHeaderSecondary = { link = "MasonHighlightBlock" }
				hl.MasonMuted = { fg = c.grey }
				hl.MasonMutedBlock = { fg = c.grey, bg = c.one_bg }

				-- Syntax
				hl.Constant = { fg = c.orange, italic = true, bold = true }
				hl.String = { fg = c.green, italic = true }
				hl.Boolean = { fg = c.blue1, italic = true }
				hl.Function = { fg = c.blue, bold = true, italic = false }
				hl.Conditional = { fg = c.cyan, italic = true }
				hl.Operator = { fg = c.blue5, bold = true }
				hl.Keyword = { fg = c.purple, italic = true }
				hl.Structure = { fg = c.magenta, italic = true }
				hl.Label = { fg = c.orange, bold = true }
				hl.Type = { fg = c.blue1, italic = true }

				-- LSP
				hl.LspReferenceText = { italic = true, bold = true, reverse = true }
				hl.LspReferenceRead = { italic = true, bold = true, reverse = true }
				hl.LspReferenceWrite = { italic = true, bold = true, reverse = true }
				hl.LspSignatureActiveParameter = { italic = true, bold = true, reverse = true }
				hl.LspCodeLens = { link = "DiagnosticVirtualTextHint", default = true }
				hl.LspCodeLensText = { link = "DiagnosticVirtualTextHint", default = true }
				hl.LspCodeLensSign = { link = "DiagnosticVirtualTextHint", default = true }
				hl.LspCodeLensSeparator = { link = "Boolean", default = true }
				hl.LspInlayHint = { fg = c.comment, underline = true, sp = util.darken(c.purple1, 0.8) }

				hl.DiagnosticFloatingError = { link = "DiagnosticError", default = true }
				hl.DiagnosticFloatingWarn = { link = "DiagnosticWarn", default = true }
				hl.DiagnosticFloatingInfo = { link = "DiagnosticInfo", default = true }
				hl.DiagnosticFloatingHint = { link = "DiagnosticHint", default = true }

				-- hl.OilFile = { link = "CmpItemAbbr" }
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

				hl.DashboardHeader = { fg = c.cyan1, bg = c.none }
				hl.DashboardIcon = { fg = c.yellow1, bg = c.none }
				hl.DashboardFooter = { fg = c.green2, bg = c.none, bold = true }
				hl.DashboardDesc = { fg = c.grey, bg = c.none, bold = true }
				hl.DashboardKey = { fg = c.magenta2, bg = c.none, bold = true }

				hl.FzfLuaBorder = { link = "Comment" }
				hl.FzfLuaTitle = { link = "DashboardIcon" }
				hl.FzfLuaHeaderText = { fg = c.cyan, bg = c.none, bold = true }
				hl.FzfLuaHeaderBind = { fg = c.orange, bg = c.none, bold = true }
				hl.FzfLuaPrompt = { fg = c.green2, bg = c.none, bold = true }
				hl.FzfLuaDirIcon = { link = "OilDirIcon" }

				hl["@task_list_marker_unchecked"] = { fg = c.error, bg = c.none, bold = true }
				hl["@task_list_marker_checked"] = { fg = c.green, bg = c.none, italic = true }
				hl["@block_quote_marker"] = { fg = c.yellow1, bg = c.none }
				hl["@strong_emphasis"] = { fg = c.orange, bold = true, underline = true }
				hl["@strikethrough"] = { fg = c.teal, italic = true }
				hl["@emphasis"] = { fg = c.cyan1, italic = true, underline = true }
				hl["@string_scalar"] = { fg = c.yellow, bold = true } -- yaml
				hl["@pipe_table_header"] = { fg = c.green, bold = true }
				hl["@markup.link.label"] = { fg = c.cyan1, italic = true, underline = true, sp = c.yellow1 }

				hl["@comment.todo"] = { bg = c.cyan1, fg = c.black, italic = true, underline = true, bold = true }
				hl["@comment.note"] = { bg = c.hint, fg = c.black, italic = true, underline = true, bold = true }
				hl["@comment.error"] = { bg = c.error, fg = c.black, italic = true, underline = true, bold = true }
				hl["@comment.hint"] = { bg = c.hint, fg = c.black, italic = true, underline = true, bold = true }
				hl["@comment.info"] = { bg = c.blue2, fg = c.black, italic = true, underline = true, bold = true }
				hl["@comment.warning"] = { bg = c.yellow, fg = c.black, italic = true, underline = true, bold = true }
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
			vim.cmd.colorscheme("tokyonight-night")
		end,
	},
}
