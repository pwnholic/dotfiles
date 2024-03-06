return {
	"rebelot/heirline.nvim",
	event = "VeryLazy",
	dependencies = {
		"SmiteshP/nvim-navic",
		opts = { highlight = true, icons = require("icons").kinds, lazy_update_context = true },
	},
	config = function()
		local space, conditions = { provider = " " }, require("heirline.conditions")
		local fmt, colors = string.format, require("tokyonight.colors").setup()
		local color_util, icons = require("tokyonight.util"), require("icons")
		local buf_matches = require("heirline.conditions").buffer_matches
		local mode_colors = {
			n = colors.blue2,
			i = colors.green,
			v = colors.magenta,
			V = colors.purple,
			["\22"] = colors.orange,
			c = colors.cyan,
			s = colors.yellow,
			S = colors.yellow,
			["\19"] = colors.yellow,
			r = colors.green,
			["!"] = colors.red,
			R = colors.red,
			t = colors.cyan,
		}
		local buftype = {
			"nofile",
			"terminal",
			"prompt",
			"help",
			"quickfix",
		}
		local filetype = {
			"^harpoon$",
			"^dashboard$",
			"^lazy$",
			"^lazyterm$",
			"^netrw$",
			"^neotest--summary$",
			"Trouble",
		}

		require("heirline").setup({
			statusline = {
				condition = function()
					return not buf_matches({ buftype = buftype, filetype = filetype })
				end,
				{
					init = function(self)
						self.mode = vim.fn.mode()
						self.mode_color = self.mode_colors[self.mode:sub(1, 1)]
					end,
					update = {
						"ModeChanged",
						pattern = "*:*",
						callback = vim.schedule_wrap(function()
							vim.cmd.redrawstatus()
						end),
					},
					static = {
						mode_names = {
							n = "NORMAL",
							no = "NORMAL-",
							nov = "NORMAL-",
							noV = "NORMAL-",
							["no\22"] = "NORMAL-",
							niI = "NORMAL-",
							niR = "NORMAL-",
							niV = "NORMAL-",
							nt = "NORMAL-",
							v = "VISUAL",
							vs = "VISUAL-",
							V = "V-LINE",
							Vs = "V-LINE-",
							["\22"] = "V-BLOCK",
							["\22s"] = "V-BLOCK-",
							s = "SELECT",
							S = "S-LINE",
							["\19"] = "S-BLOCK",
							i = "INSERT",
							ic = "INSERT-",
							ix = "INSERT-",
							R = "REPLACE",
							Rc = "REPLACE-",
							Rx = "REPLACE-",
							Rv = "REPLACE-",
							Rvc = "REPLACE-",
							Rvx = "REPLACE-",
							c = "COMMAND",
							cv = "COMMAND-",
							r = "PROMPT",
							rm = "MORE",
							["r?"] = "CONFIRM",
							["!"] = "SHELL",
							t = "TERMINAL",
						},
						mode_colors = mode_colors,
					},
					provider = function(self)
						return string.format("%s%s%s", " %1(", self.mode_names[self.mode], "%) ")
					end,
					hl = function(self)
						return { bg = self.mode_color, fg = colors.bg_statusline, bold = true }
					end,
				},
				{
					condition = conditions.is_git_repo,
					init = function(self)
						self.status_dict = vim.b.gitsigns_status_dict
					end,
					space,
					{
						provider = function(self)
							return fmt(
								" %s %s ",
								"",
								(self.status_dict.head == "" and "main" or self.status_dict.head)
							)
						end,
						hl = { fg = colors.blue2, bg = colors.fg_gutter, bold = true },
					},
					space,
					{
						provider = function(self)
							local count = self.status_dict.added or 0
							return count > 0 and fmt("%s %d ", icons.git.added, count)
						end,
						hl = { fg = colors.green2, bold = true, bg = colors.bg_statusline },
					},
					{
						provider = function(self)
							local count = self.status_dict.removed or 0
							return count > 0 and fmt("%s %d ", icons.git.removed, count)
						end,
						hl = { fg = colors.red, bold = true, bg = colors.bg_statusline },
					},
					{
						provider = function(self)
							local count = self.status_dict.changed or 0
							return count > 0 and fmt("%s %d ", icons.git.modified, count)
						end,
						hl = { fg = colors.yellow1, bold = true, bg = colors.bg_statusline },
					},
					on_click = {
						callback = function()
							vim.defer_fn(function()
								require("toggleterm.terminal").Terminal
									:new({
										cmd = "lazygit",
										hidden = true,
										direction = "float",
										close_on_exit = true,
										dir = require("directory").get_root(),
									})
									:toggle()
							end, 100)
						end,
						name = "heirline_git",
					},
				},

				{
					condition = function()
						return not buf_matches({
							buftype = { "prompt", "nofile", "terminal", "help", "quickfix" },
							filetype = { "fugitive", "qf", "dbui", "dbout", "compilation", "Trouble", "Glance" },
						}) or vim.api.nvim_win_get_config(0).relative ~= "" or vim.api.nvim_buf_get_name(0) == ""
					end,
					space,
					{
						init = function(self)
							self.icon, self.fg =
								require("nvim-web-devicons").get_icon_color_by_filetype(vim.bo.filetype)
						end,
						provider = function(self)
							return fmt("%s ", self.icon or "")
						end,
						hl = function(self)
							return { fg = self.fg, bg = colors.bg_statusline }
						end,
					},
					space,
					{
						condition = function()
							return not vim.tbl_contains({ "[No Name]", "" }, vim.api.nvim_buf_get_name(0))
						end,
						{
							provider = function()
								return vim.fn.expand("%:t") --[[@as string]]
							end,
							hl = { fg = colors.cyan, bg = colors.bg_statusline },
						},
						{
							condition = function()
								return vim.bo.modified
							end,
							space,
							{ provider = "[+]", hl = { fg = colors.green, bg = colors.bg_statusline } },
						},
						{
							condition = function()
								return not vim.bo.modifiable or vim.bo.readonly
							end,
							space,
							{ provider = " ", hl = { fg = colors.red, bg = colors.bg_statusline } },
						},
					},
				},

				-- MIDDLE --

				{ provider = "%=" },
				{
					condition = function()
						return #vim.api.nvim_list_tabpages() >= 2
					end,
					require("heirline.utils").make_tablist({
						provider = function(self)
							return "%" .. self.tabnr .. "T " .. self.tabpage .. " %T"
						end,
						hl = function(self)
							if self.is_active then
								return { bg = colors.blue1, bold = true, fg = colors.bg_statusline }
							else
								return { bg = colors.fg_gutter }
							end
						end,
					}),
				},
				{ provider = "%=" },
				-- RIGHT --
				{
					condition = conditions.has_diagnostics,
					init = function(self)
						self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
						self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
						self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
						self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
					end,
					update = { "DiagnosticChanged", "BufEnter" },
					on_click = {
						callback = function()
							require("trouble").toggle({ mode = "document_diagnostics" })
						end,
						name = "heirline_diagnostics",
					},
					space,
					{
						condition = function(self)
							return self.errors > 0
						end,
						hl = { fg = colors.error, bg = colors.bg_statusline, bold = true },
						provider = function(self)
							return fmt("%s %d ", icons.diagnostics.Error, self.errors)
						end,
					},
					-- Warnings
					{
						condition = function(self)
							return self.warnings > 0
						end,
						hl = { fg = colors.warning, bg = colors.bg_statusline, bold = true },
						provider = function(self)
							return fmt("%s %d ", icons.diagnostics.Warn, self.warnings)
						end,
					},
					-- Hints
					{
						condition = function(self)
							return self.hints > 0
						end,
						hl = { fg = colors.hint, bg = colors.bg_statusline, bold = true },
						provider = function(self)
							return fmt("%s %d ", icons.diagnostics.Hint, self.hints)
						end,
					},
					{
						condition = function(self)
							return self.info > 0
						end,
						hl = { fg = colors.info, bg = colors.bg_statusline, bold = true },
						provider = function(self)
							return fmt("%s %d ", icons.diagnostics.Info, self.info)
						end,
					},
				},
				{
					condition = function(self)
						return not conditions.buffer_matches({ filetype = self.filetypes })
							and require("lazy.status").has_updates()
					end,
					update = {
						"User",
						pattern = "LazyCheck",
						callback = vim.schedule_wrap(function()
							vim.cmd.redrawstatus()
						end),
					},
					provider = function()
						return fmt(" %s ", require("lazy.status").updates())
					end,
					on_click = {
						callback = function()
							require("lazy").update()
						end,
						name = "sl_plugins_click",
					},
					hl = { bold = true, fg = colors.blue2, bg = colors.fg_gutter },
				},
				{
					condition = conditions.lsp_attached,
					static = {
						lsp_attached = false,
						server_name = "",
					},
					init = function(self)
						local server_name = vim.lsp.get_clients({ bufnr = self.bufnr })[1].name
						if server_name ~= "" then
							self.lsp_attached = true
							self.server_name = server_name
						end
					end,
					update = { "LspAttach", "LspDetach" },
					on_click = {
						callback = function()
							vim.defer_fn(function()
								vim.cmd.LspInfo()
							end, 100)
						end,
						name = "sl_lsp_click",
					},
					{
						condition = function(self)
							return self.lsp_attached
						end,
						space,
						{
							provider = function(self)
								return fmt(" %s ", string.lower(self.server_name))
							end,
							hl = { bold = true, fg = colors.blue2, bg = colors.fg_gutter },
						},
					},
				},
				{
					condition = function(self)
						return not vim.tbl_contains(
							{ "", "trim_whitespace", "trim_newlines" },
							require("conform").list_formatters_for_buffer(self.bufnr)[1]
						)
					end,
					space,
					{
						init = function(self)
							self.formatter = require("conform").list_formatters_for_buffer(self.bufnr)[1]
						end,
						provider = function(self)
							if self.formatter ~= "" then
								return fmt(" %s ", self.formatter)
							end
						end,
						hl = { bold = true, fg = colors.blue2, bg = colors.fg_gutter },
					},
				},
				{
					condition = require("noice").api.status.command.has,
					space,
					{
						provider = function()
							return fmt(" %s ", require("noice").api.status.command.get())
						end,
						hl = { bold = true, fg = colors.blue2, bg = colors.fg_gutter },
					},
				},
				{
					condition = require("noice").api.status.mode.has,
					space,
					{
						provider = function()
							return fmt(" %s ", require("noice").api.status.mode.get())
						end,
						hl = { bold = true, fg = colors.blue2, bg = colors.fg_gutter },
					},
				},
				space,
				{
					init = function(self)
						self.mode = vim.fn.mode()
						self.mode_color = self.mode_colors[self.mode:sub(1, 1)]
					end,
					static = { mode_colors = mode_colors },
					provider = " %l:%c:%L ",
					hl = function(self)
						return { bg = self.mode_color, fg = colors.bg_statusline, bold = true }
					end,
					on_click = {
						callback = function()
							local line = vim.api.nvim_win_get_cursor(0)[1]
							local total_lines = vim.api.nvim_buf_line_count(0)
							if math.floor((line / total_lines)) > 0.5 then
								vim.cmd.normal({ args = { "gg" }, bang = true })
							else
								vim.cmd.normal({ args = { "G" }, bang = true })
							end
						end,
						name = "sl_ruler_click",
					},
				},
			},
			statuscolumn = {
				condition = function()
					return not conditions.buffer_matches({
						buftype = { "nofile", "terminal", "prompt", "help", "quickfix" },
						filetype = {
							"markdown",
							"^harpoon$",
							"^dashboard$",
							"^lazy$",
							"^lazyterm$",
							"^netrw$",
							"^neotest--summary$",
							"^toggleterm$",
							"^dbui$",
							"^dbout$",
							"^oil$",
						},
					})
				end,
				init = function(self)
					self.signs = {}
				end,
				static = {
					get_extmarks = function(self, bufnr, lnum)
						local signs = {}

						local extmarks = vim.api.nvim_buf_get_extmarks(
							0,
							bufnr,
							{ lnum - 1, 0 },
							{ lnum - 1, -1 },
							{ details = true, type = "sign" }
						)
						for _, extmark in pairs(extmarks) do
							-- Exclude gitsigns
							if extmark[4].ns_id ~= self.git_ns then
								signs[#signs + 1] = {
									name = extmark[4].sign_hl_group or "",
									text = extmark[4].sign_text,
									sign_hl_group = extmark[4].sign_hl_group,
									priority = extmark[4].priority,
								}
							end
						end
						-- Sort by priority
						table.sort(signs, function(a, b)
							return (a.priority or 0) > (b.priority or 0)
						end)

						return signs
					end,
					git_ns = vim.api.nvim_create_namespace("gitsigns_extmark_signs_"),
					click_args = function(self, minwid, clicks, button, mods)
						local args = {
							minwid = minwid,
							clicks = clicks,
							button = button,
							mods = mods,
							mousepos = vim.fn.getmousepos(),
						}
						local sign = vim.fn.screenstring(args.mousepos.screenrow, args.mousepos.screencol)
						if sign == " " then
							sign = vim.fn.screenstring(args.mousepos.screenrow, args.mousepos.screencol - 1)
						end
						args.sign = self.signs[sign]
						vim.api.nvim_set_current_win(args.mousepos.winid)
						vim.api.nvim_win_set_cursor(0, { args.mousepos.line, 0 })
						return args
					end,
					resolve = function(self, name)
						for pattern, callback in pairs(self.handlers.Signs) do
							if name:match(pattern) then
								return vim.defer_fn(callback, 100)
							end
						end
					end,
					handlers = {
						Signs = {
							["Neotest.*"] = function()
								require("neotest").run.run()
							end,
							["Debug.*"] = function()
								require("dap").continue()
							end,
							["Diagnostic.*"] = function()
								vim.diagnostic.open_float()
							end,
						},
						Dap = function()
							require("dap").toggle_breakpoint()
						end,
						GitSigns = function()
							vim.defer_fn(function()
								require("gitsigns").blame_line({ full = true })
							end, 100)
						end,
					},
				},
				{
					init = function(self)
						local signs = self.get_extmarks(self, -1, vim.v.lnum)
						self.sign = signs[1]
					end,
					provider = function(self)
						return (
							self.sign and vim.fn.strcharpart(self.sign.text or "", 0, 2)--[[@type string]]
						) or ""
					end,
					hl = function(self)
						return self.sign and self.sign.sign_hl_group
					end,
					on_click = {
						name = "sc_sign_click",
						update = true,
						callback = function(self, ...)
							local line = self.click_args(self, ...).mousepos.line
							local sign = self.get_signs(self, -1, line)[1]
							if sign then
								self:resolve(sign.name)
							end
						end,
					},
				},
				{ provider = "%=" },
				{
					provider = "%=%4{v:virtnum ? '' : &nu ? (&rnu && v:relnum ? v:relnum : v:lnum) . ' ' : ''}",
					on_click = {
						name = "sc_linenumber_click",
						callback = function(self, ...)
							self.handlers.Dap(self.click_args(self, ...))
						end,
					},
				},
				{
					{
						condition = function()
							return conditions.is_git_repo() and vim.v.virtnum == 0
						end,
						init = function(self)
							local extmark = vim.api.nvim_buf_get_extmarks(
								0,
								self.git_ns,
								{ vim.v.lnum - 1, 0 },
								{ vim.v.lnum - 1, -1 },
								{ limit = 1, details = true }
							)[1]
							self.sign = extmark and extmark[4]["sign_hl_group"]
						end,
						provider = "•",
						-- provider = "▍",
						hl = function(self)
							return self.sign or { fg = "bg" }
						end,
						on_click = {
							name = "sc_gitsigns_click",
							callback = function(self, ...)
								self.handlers.GitSigns(self.click_args(self, ...))
							end,
						},
					},
					{
						condition = function()
							return not conditions.is_git_repo() or vim.v.virtnum ~= 0
						end,
						provider = "",
						hl = "HeirlineStatusColumn",
					},
				},
				{ provider = " " },
			},
			winbar = {
				{
					condition = package.loaded["nvim-navic"] and require("nvim-navic").is_available(),
					update = "CursorMoved",
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
							Function = "Function",
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
						-- DARK MAGIC HAPPEN HERE!! wkwkwkwkkw
						enc = function(line, col, winnr)
							return bit.bor(bit.lshift(line, 16), bit.lshift(col, 6), winnr)
						end,
						-- line: 16 bit (65535); col: 10 bit (1023); winnr: 6 bit (63)
						dec = function(col)
							return bit.rshift(col, 16), bit.band(bit.rshift(col, 6), 1023), bit.band(col, 63)
						end,
					},
					init = function(self)
						local data = require("nvim-navic").get_data() or {}
						local children = {}
						for i, d in ipairs(data) do
							local child = {
								{ provider = string.format("%s ", d.icon), hl = self.type_hl[d.type] }, -- link to item kind
								{
									provider = d.name:gsub("%%", "%%%%"):gsub("%s*-->%s*", ""),
									hl = self.type_hl[d.type],
									on_click = {
										minwid = self.enc(d.scope.start.line, d.scope.start.character, self.winnr),
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
									provider = " --> ",
									hl = { bg = colors.bg_statusline, fg = colors.red, bold = true },
								})
							end
							table.insert(children, child)
						end
						self.child = self:new(children, 1)
					end,
					provider = function(self)
						return self.child:eval()
					end,
					hl = {
						bg = colors.bg_statusline,
						underline = true,
						sp = color_util.darken(colors.cyan, 0.7),
						italic = true,
					},
				},
				{ provider = "%=" },
				{
					condition = function()
						return not buf_matches({
							buftype = { "prompt", "nofile", "terminal", "help", "quickfix" },
							filetype = { "fugitive", "qf", "dbui", "dbout", "compilation", "Trouble", "Glance" },
						}) or vim.api.nvim_win_get_config(0).relative ~= "" or vim.api.nvim_buf_get_name(0) == ""
					end,
					provider = function()
						return fmt(" %s %s ", icons.kinds.Folder, vim.fn.expand("%:h"))
					end,
					hl = {
						fg = colors.cyan,
						bg = colors.bg_statusline,
						underline = true,
						sp = color_util.darken(colors.cyan, 0.7),
					},
				},
			},
			opts = {
				disable_winbar_cb = function(args)
					return buf_matches({
						buftype = buftype,
						filetype = vim.tbl_deep_extend(
							"force",
							filetype,
							{ "oil", "mysql", "markdown", "sql", "json", "dbui", "dbout" }
						),
					}, args.buf)
				end,
				colors = colors,
			},
		})
	end,
}
