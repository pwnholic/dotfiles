return {
	{
		"rebelot/heirline.nvim",
		event = "UIEnter",
		opts = function(_, opts)
			local conditions = require("heirline.conditions")
			local hutils = require("heirline.utils")
			local colors = require("tokyonight.colors").setup()
			local cutil = require("tokyonight.util")
			local utils = require("utils")
			local align, space = { provider = "%=" }, { provider = " " }

			local mode_colors = {
				n = colors.blue1,
				i = colors.green,
				v = colors.magenta,
				V = colors.magenta,
				["\22"] = colors.cyan,
				c = colors.orange,
				s = colors.purple,
				S = colors.purple,
				["\19"] = colors.purple,
				R = colors.red,
				r = colors.red,
				["!"] = colors.red,
				t = colors.red,
			}

			vim.api.nvim_create_autocmd("ModeChanged", {
				pattern = "*:*",
				callback = function()
					local color = mode_colors[vim.fn.mode():sub(1, 1)]
					vim.api.nvim_set_hl(0, "WinBar", { sp = color, underline = true, bg = colors.bg_statusline })
					vim.api.nvim_set_hl(0, "WinBarNC", { sp = color, underline = true })
				end,
			})

			opts.statusline = {
				condition = function()
					return not conditions.buffer_matches({
						buftype = { "nofile", "prompt", "help", "quickfix", "terminal" },
						filetype = { "dashboard", "lspinfo", "toggleterm", "lazy", "lazyterm", "netrw" },
					})
				end,
				{
					static = {
						mode_names = {
							n = "NORMAL",
							no = "NORMAL",
							nov = "NORMAL",
							noV = "NORMAL",
							["no\22"] = "NORMAL",
							niI = "NORMAL",
							niR = "NORMAL",
							niV = "NORMAL",
							nt = "NORMAL",
							v = "VISUAL",
							vs = "VISUAL",
							V = "VISUAL",
							Vs = "VISUAL",
							["\22"] = "VISUAL",
							["\22s"] = "VISUAL",
							s = "SELECT",
							S = "SELECT",
							["\19"] = "SELECT",
							i = "INSERT",
							ic = "INSERT",
							ix = "INSERT",
							R = "REPLACE",
							Rc = "REPLACE",
							Rx = "REPLACE",
							Rv = "REPLACE",
							Rvc = "REPLACE",
							Rvx = "REPLACE",
							c = "COMMAND",
							cv = "Ex",
							r = "...",
							rm = "M",
							["r?"] = "?",
							["!"] = "!",
							t = "TERMINAL",
						},
						mode_colors = mode_colors,
					},
					update = {
						"ModeChanged",
						pattern = "*:*",
						callback = vim.schedule_wrap(function()
							vim.cmd("redrawstatus")
						end),
					},
					{
						provider = function(self)
							return string.format(" %s ", self.mode_names[vim.fn.mode(1)])
						end,
						hl = function(self)
							return { bg = self.mode_colors[vim.fn.mode(1):sub(1, 1)], bold = true, fg = colors.bg_dark }
						end,
					},
					space,
				},
				{
					condition = conditions.is_git_repo,
					init = function(self)
						self.status_dict = vim.b.gitsigns_status_dict
						self.has_changes = self.status_dict.added ~= 0
							or self.status_dict.removed ~= 0
							or self.status_dict.changed ~= 0
					end,
					{
						static = { mode_colors = mode_colors },
						provider = function(self)
							return string.format(" %s %s ", utils.icons.git.branch, self.status_dict.head)
						end,
						hl = function(self)
							return {
								fg = cutil.darken(self.mode_colors[vim.fn.mode(1):sub(1, 1)], 0.8),
								bold = true,
								bg = colors.fg_gutter,
							}
						end,
					},
					{
						provider = function(self)
							local count = self.status_dict.added or 0
							return count > 0 and string.format(" %s %s", utils.icons.git.add, count)
						end,
						hl = { fg = colors.green2, bg = colors.bg_statusline, bold = true },
					},
					{
						provider = function(self)
							local count = self.status_dict.removed or 0
							return count > 0 and string.format(" %s %s", utils.icons.git.remove, count)
						end,
						hl = { fg = colors.red, bg = colors.bg_statusline, bold = true },
					},
					{
						provider = function(self)
							local count = self.status_dict.changed or 0
							return count > 0 and string.format(" %s %s", utils.icons.git.modified, count)
						end,
						hl = { fg = colors.yellow, bg = colors.bg_statusline, bold = true },
					},
				},
				align,
				{
					condition = function()
						return #vim.api.nvim_list_tabpages() >= 2
					end,
					hutils.make_tablist({
						provider = function(self)
							return string.format(" %s ", self.tabpage)
						end,
						static = { mode_colors = mode_colors },
						hl = function(self)
							if not self.is_active then
								return {
									bg = self.mode_colors[vim.fn.mode():sub(1, 1)],
									bold = true,
									fg = colors.bg_dark,
								}
							else
								return { bg = colors.fg_gutter, bold = true, fg = colors.bg_dark }
							end
						end,
					}),
				},
				align,
				{
					condition = conditions.has_diagnostics,
					init = function(self)
						self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
						self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
						self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
						self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
					end,
					update = { "DiagnosticChanged", "BufEnter" },
					{
						{
							provider = function(self)
								return self.errors > 0
									and string.format("%s %s", utils.icons.diagnostics.ERROR, self.errors)
							end,
							hl = { fg = colors.error, bg = colors.bg_statusline, bold = true },
						},
						{
							provider = function(self)
								return self.warnings > 0
									and string.format(" %s %s", utils.icons.diagnostics.WARN, self.warnings)
							end,
							hl = { fg = colors.warning, bg = colors.bg_statusline, bold = true },
						},
						{
							provider = function(self)
								return self.info > 0
									and string.format(" %s %s", utils.icons.diagnostics.INFO, self.info)
							end,
							hl = { fg = colors.info, bg = colors.bg_statusline, bold = true },
						},
						{
							provider = function(self)
								return self.hints > 0
									and string.format(" %s %s", utils.icons.diagnostics.HINT, self.hints)
							end,
							hl = { fg = colors.hint, bg = colors.bg_statusline, bold = true },
						},
					},
					space,
				},
				{
					condition = function()
						return vim.fn.reg_recording() ~= "" and vim.o.cmdheight == 0
					end,
					{
						update = { "RecordingEnter", "RecordingLeave", "ModeChanged" },
						static = { mode_colors = mode_colors },
						provider = function()
							return string.format(" recording @%s ", vim.fn.reg_recording())
						end,
						hl = function(self)
							return {
								fg = cutil.darken(self.mode_colors[vim.fn.mode(1):sub(1, 1)], 0.8),
								bold = true,
								bg = colors.fg_gutter,
							}
						end,
					},
					space,
				},
				{
					condition = conditions.lsp_attached,
					update = { "LspAttach", "LspDetach", "ModeChanged" },
					static = { mode_colors = mode_colors },
					{
						provider = function()
							local names = {}
							for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
								table.insert(names, server.name)
							end
							return string.format(" %s ", table.concat(names, " "))
						end,
						hl = function(self)
							return {
								fg = cutil.darken(self.mode_colors[vim.fn.mode(1):sub(1, 1)], 0.8),
								bold = true,
								bg = colors.fg_gutter,
							}
						end,
					},
					space,
				},
				{
					provider = " %l:%c %P ",
					static = { mode_colors = mode_colors },
					hl = function(self)
						return { bg = self.mode_colors[vim.fn.mode():sub(1, 1)], bold = true, fg = colors.bg_dark }
					end,
				},
			}

			opts.winbar = {
				{
					init = function(self)
						self.icon, self.icon_hl = require("mini.icons").get("file", vim.api.nvim_buf_get_name(0))
					end,
					static = { mode_colors = mode_colors },
					{
						provider = function(self)
							return string.format(" %s ", self.icon)
						end,
						hl = function(self)
							return {
								fg = hutils.get_highlight(self.icon_hl).fg,
								bg = colors.bg_statusline,
								underline = true,
								sp = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
							}
						end,
					},
					space,
					{
						provider = function()
							local cwd = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
							if not conditions.width_percent_below(#cwd, 0.25) then
								cwd = vim.fn.pathshorten(cwd, 1)
							end
							return string.format("%s", cwd)
						end,
						hl = function(self)
							return {
								fg = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
								bg = colors.bg_statusline,
								underline = true,
								sp = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
								bold = true,
							}
						end,
					},
				},
				{
					condition = function()
						return require("nvim-navic").is_available()
					end,
					static = {
						type_hl = {
							File = "Directory",
							Module = "@include",
							Namespace = "@namespace",
							Package = "@include",
							Class = "@structure",
							Method = "@method",
							Property = "@property",
							Field = "@field",
							Constructor = "@constructor",
							Enum = "@field",
							Interface = "@type",
							Function = "@function",
							Variable = "@variable",
							Constant = "@constant",
							String = "@string",
							Number = "@number",
							Boolean = "@boolean",
							Array = "@field",
							Object = "@type",
							Key = "@keyword",
							Null = "@comment",
							EnumMember = "@field",
							Struct = "@structure",
							Event = "@keyword",
							Operator = "@operator",
							TypeParameter = "@type",
						},
						enc = function(line, col, winnr)
							return bit.bor(bit.lshift(line, 16), bit.lshift(col, 6), winnr)
						end,
						dec = function(c)
							return bit.rshift(c, 16), bit.band(bit.rshift(c, 6), 1023), bit.band(c, 63)
						end,
						mode_colors = mode_colors,
					},
					init = function(self)
						local data = require("nvim-navic").get_data() or {}
						local children = {}
						for i, d in ipairs(data) do
							local pos = self.enc(d.scope.start.line, d.scope.start.character, self.winnr)
							local child = {
								{
									provider = string.format("%s ", d.icon),
									hl = {
										fg = hutils.get_highlight(self.type_hl[d.type]).fg,
										bg = colors.bg_statusline,
										underline = true,
										sp = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
									},
								},
								{
									provider = d.name:gsub("%%", "%%%%"):gsub("%s*->%s*", ""),
									hl = {
										fg = hutils.get_highlight(self.type_hl[d.type]).fg,
										bg = colors.bg_statusline,
										underline = true,
										sp = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
									},
									on_click = {
										minwid = pos,
										callback = function(_, minwid)
											local line, col, winnr = self.dec(minwid)
											vim.api.nvim_win_set_cursor(vim.fn.win_getid(winnr), { line, col })
										end,
										name = "heirline_navic",
									},
								},
							}
							if #data > 1 and i < #data then
								table.insert(child, {
									provider = "   ",
									hl = {
										fg = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
										bold = true,
										underline = true,
										sp = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
										bg = colors.bg_statusline,
									},
								})
							end
							table.insert(children, child)
						end
						self.child = self:new(children, 1)
					end,
					update = { "CursorMoved", "ModeChanged" },
					{
						provider = "   ",
						hl = function(self)
							return {
								fg = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
								bold = true,
								underline = true,
								sp = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
								bg = colors.bg_statusline,
							}
						end,
					},
					{
						provider = function(self)
							return self.child:eval()
						end,
					},
				},
			}

			opts.statuscolumn = {
				condition = function()
					return not conditions.buffer_matches({
						buftype = { "nofile", "prompt", "help", "quickfix", "terminal" },
						filetype = { "dashboard", "fzf", "harpoon", "oil", "diff" },
					})
				end,
				provider = utils.stc.statuscolumn,
			}
			opts.opts = {
				disable_winbar_cb = function(args)
					return conditions.buffer_matches({
						buftype = { "nofile", "prompt", "help", "quickfix", "terminal" },
						filetype = { "dashboard", "oil", "lspinfo", "toggleterm", "fzf", "diff" },
					}, args.buf)
				end,
			}
		end,
	},
	{
		"folke/tokyonight.nvim",
		priority = 1000,
		lazy = false,
		opts = function()
			return {
				style = "night",
				transparent = false,
				terminal_colors = true,
				styles = {
					comments = { italic = false },
					keywords = { italic = true },
					functions = { bold = true },
					sidebars = "dark",
					floats = "dark",
				},
				-- on_colors = function(c) end,
				on_highlights = function(hl, c)
					hl.Visual = { bg = c.bg_visual, bold = true, italic = true }
					hl.VisualNOS = { bg = c.bg_visual, bold = true, italic = true }
					hl.WinBar = { bg = c.bg_statusline, underline = true, sp = c.blue2 }
					hl.WinBarNC = { link = "WinBar" }
					hl.StatusLine = { bg = c.bg_statusline }
					hl.CursorLineNr = { fg = c.cyan, bg = c.none, bold = true }
					hl.WinSeparator = { link = "Comment" }
					hl.FloatBorder = { fg = c.bg_statusline, bg = c.bg_statusline }
					hl.MarkIcons = { fg = c.cyan, bold = true }

					hl.DashboardHeader = { fg = c.cyan, bg = c.none }
					hl.DashboardIcon = { fg = c.yellow, bg = c.none }
					hl.DashboardFooter = { fg = c.green, bg = c.none, bold = true }
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
					hl.IlluminatedWordText = { link = "LspReferenceText" }
					hl.IlluminatedWordRead = { link = "LspReferenceRead" }
					hl.IlluminatedWordWrite = { link = "LspReferenceWrite" }

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
					hl.OilSize = { fg = c.teal, bg = c.none }
					hl.OilMtime = { fg = c.purple, bg = c.none }
				end,
				cache = true,
			}
		end,
		config = function(_, opts)
			require("tokyonight").setup(opts)
			vim.cmd.colorscheme("tokyonight")
		end,
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "BufRead",
		main = "ibl",
		opts = function()
			return {
				indent = { char = "▏", tab_char = "▏", smart_indent_cap = true },
				debounce = 200,
				scope = {
					show_exact_scope = false,
					priority = 500,
					show_start = true,
					show_end = false,
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
						"dashboard",
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
			local hooks = require("ibl.hooks")
			hooks.register(hooks.type.ACTIVE, function(bufnr)
				return vim.api.nvim_buf_line_count(bufnr) < 5000
			end)
			require("ibl").setup(opts)
		end,
	},
	{
		"SmiteshP/nvim-navic",
		lazy = true,
		init = function()
			vim.g.navic_silence = true
			require("utils.lsp").on_attach(function(client, buffer)
				if client.supports_method("textDocument/documentSymbol") then
					require("nvim-navic").attach(client, buffer)
				end
			end)
		end,
		config = true,
	},
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
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		keys = {
			{
				"<c-f>",
				function()
					if not require("noice.lsp").scroll(4) then
						return "<c-f>"
					end
				end,
				silent = true,
				expr = true,
				desc = "Scroll Forward",
				mode = { "i", "n", "s" },
			},
			{
				"<c-b>",
				function()
					if not require("noice.lsp").scroll(-4) then
						return "<c-b>"
					end
				end,
				silent = true,
				expr = true,
				desc = "Scroll Backward",
				mode = { "i", "n", "s" },
			},
		},
		opts = function()
			return {
				cmdline = { enabled = true, view = "cmdline", format = { input = { view = "cmdline" } } },
				notify = { enabled = true, view = "notify" },
				popupmenu = { enabled = true, backend = "cmp" },
				lsp = {
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true,
					},
					hover = { enabled = true, opts = {} },
					signature = {
						enabled = true,
						auto_open = { enabled = true, trigger = true, luasnip = true, throttle = 50 },
						opts = {},
					},
					documentation = {
						view = "hover",
						opts = {
							lang = "markdown",
							replace = true,
							render = "plain",
							format = { "{message}" },
							win_options = { concealcursor = "n", conceallevel = 3 },
						},
					},
				},
				markdown = {
					hover = { ["|(%S-)|"] = vim.cmd.help, ["%[.-%]%((%S-)%)"] = require("noice.util").open },
					highlights = {
						["|%S-|"] = "@text.reference",
						["@%S+"] = "@parameter",
						["^%s*(Parameters:)"] = "@text.title",
						["^%s*(Return:)"] = "@text.title",
						["^%s*(See also:)"] = "@text.title",
						["{%S-}"] = "@parameter",
					},
				},
				presets = {
					bottom_search = true,
					command_palette = true,
					long_message_to_split = true,
					lsp_doc_border = false,
				},
				routes = {
					{
						filter = {
							event = "msg_show",
							any = { { find = "%d+L, %d+B" }, { find = "; after #%d+" }, { find = "; before #%d+" } },
						},
						view = "mini",
					},
				},
			}
		end,
	},
	{
		"rcarriga/nvim-notify",
		event = "VeryLazy",
		init = vim.schedule_wrap(function()
			vim.notify = require("notify")
		end),
		opts = function()
			return {
				stages = "slide",
				timeout = 3000,
				render = "wrapped-compact",
				max_height = function()
					return math.floor(vim.o.lines * 0.75)
				end,
				max_width = function()
					return math.floor(vim.o.columns * 0.75)
				end,
				on_open = function(win)
					vim.api.nvim_win_set_config(win, { zindex = 100 })
				end,
			}
		end,
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = function()
			return {
				preset = "helix",
				spec = {
					{ "<leader>g", desc = "LSP" },
					{ "<leader>b", desc = "Buffer" },
					{ "<leader>f", desc = "Find" },
					{ "<leader>s", desc = "Search" },
					{ "<leader>d", desc = "Debug" },
					{ "<leader>h", desc = "Git" },
					{ "<leader>t", desc = "Test" },
					{ "<leader>u", desc = "Toggle" },
					{ "<leader>w", desc = "Window" },
					{ "<leader>df", desc = "Find Debug" },
				},
				icons = {
					breadcrumb = "",
					separator = "",
					group = "",
					ellipsis = "...",
					mappings = true,
					rules = false,
					colors = true,
				},
			}
		end,
	},
}
