local M = { "rebelot/heirline.nvim", event = "VeryLazy" }

M.dependencies = {
	"SmiteshP/nvim-navic",
	opts = { highlight = true, icons = require("icons").kinds, lazy_update_context = true },
}

M.config = function()
	local cond = require("heirline.conditions")
	local fmt, icons = string.format, require("icons")
	local space, align = { provider = " " }, { provider = "%=" }
	local c = require("tokyonight.colors").setup()
	-- local c_util = require("tokyonight.util")

	local function buf_matches()
		if
			not cond.buffer_matches({
				bufname = { "sh" },
				buftype = { "nofile", "terminal", "prompt", "help", "quickfix" },
				filetype = {
					"^harpoon$",
					"^dashboard$",
					"^fzf$",
					"^lazy$",
					"^lazyterm$",
					"^netrw$",
					"^neotest--summary$",
					"^Trouble$",
					"^dbui$",
					"^dbout$",
				},
			})
		then
			return true
		end
		return false
	end

	local mode_colors = {
		n = c.blue2,
		i = c.green,
		v = c.magenta,
		V = c.orange,
		["\22"] = c.red,
		c = c.cyan,
		s = c.yellow,
		S = c.yellow,
		["\19"] = c.yellow,
		r = c.green,
		["!"] = c.red,
		R = c.red,
		t = c.teal,
	}

	vim.api.nvim_create_autocmd("ModeChanged", {
		callback = function()
			local mode_clr = mode_colors[vim.fn.mode():sub(1, 1)]
			vim.api.nvim_set_hl(0, "Winbar", { underline = true, sp = mode_clr, bg = c.bg_statusline, italic = true })
			-- vim.api.nvim_set_hl(0, "LineNr", { fg = c_util.darken(mode_clr, 0.7), bg = c.none, bold = true })
		end,
	})

	local mode_cinit = function(self)
		self.mode = vim.fn.mode()
		self.mode_color = self.mode_colors[self.mode:sub(1, 1)]
	end

	local vim_mode = {
		init = mode_cinit,
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
			return fmt("%s%s%s", " %1(", self.mode_names[self.mode], "%) ")
		end,
		hl = function(self)
			return { bg = self.mode_color, fg = c.bg_statusline, bold = true }
		end,
	}

	local git = {
		condition = cond.is_git_repo,
		init = function(self)
			self.status_dict = vim.b.gitsigns_status_dict
		end,
		space,
		{
			provider = function(self)
				return fmt(" %s %s ", "", (self.status_dict.head == "" and "main" or self.status_dict.head))
			end,
			hl = { fg = c.blue2, bg = c.fg_gutter, bold = true },
		},
		space,
		{
			provider = function(self)
				local count = self.status_dict.added or 0
				return count > 0 and fmt("%s %d ", icons.git.added, count)
			end,
			hl = { fg = c.green2, bold = true, bg = c.bg_statusline },
		},
		{
			provider = function(self)
				local count = self.status_dict.removed or 0
				return count > 0 and fmt("%s %d ", icons.git.removed, count)
			end,
			hl = { fg = c.red, bold = true, bg = c.bg_statusline },
		},
		{
			provider = function(self)
				local count = self.status_dict.changed or 0
				return count > 0 and fmt("%s %d ", icons.git.modified, count)
			end,
			hl = { fg = c.yellow1, bold = true, bg = c.bg_statusline },
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
	}

	local filename = {
		condition = buf_matches,
		space,
		{
			init = function(self)
				self.icon, self.fg = require("nvim-web-devicons").get_icon_color_by_filetype(vim.bo.filetype)
			end,
			provider = function(self)
				return fmt("%s ", self.icon or "")
			end,
			hl = function(self)
				return { fg = self.fg, bg = c.bg_statusline }
			end,
		},
		space,
		{
			condition = function()
				return not vim.tbl_contains({ "[No Name]", "" }, vim.api.nvim_buf_get_name(0))
			end,
			init = mode_cinit,
			static = { mode_colors = mode_colors },
			{
				provider = function()
					if vim.bo.filetype == "oil" then
						return vim.fn.expand("%:f")
					end
					return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
				end,
				hl = function(self)
					return { bold = true, fg = self.mode_color, bg = c.bg_statusline }
				end,
			},
			{
				condition = function()
					return vim.bo.modified
				end,
				space,
				{ provider = "[+]", hl = { fg = c.green, bg = c.bg_statusline } },
			},
			{
				condition = function()
					return not vim.bo.modifiable or vim.bo.readonly
				end,
				space,
				{ provider = " ", hl = { fg = c.red, bg = c.bg_statusline } },
			},
		},
	}

	local diagnostics = {
		condition = cond.has_diagnostics,
		init = function(self)
			self.mode = vim.fn.mode()
			self.mode_color = self.mode_colors[self.mode:sub(1, 1)]
			self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
			self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
			self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
			self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
		end,
		static = { mode_colors = mode_colors },
		update = { "DiagnosticChanged", "BufEnter", "ModeChanged" },
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
			hl = function(self)
				return { fg = c.error, bg = c.bg_statusline, bold = true, sp = self.mode_color, underline = true }
			end,
			provider = function(self)
				return fmt("%s %d ", icons.diagnostics.Error, self.errors)
			end,
		},
		-- Warnings
		{
			condition = function(self)
				return self.warnings > 0
			end,
			hl = function(self)
				return { fg = c.warning, bg = c.bg_statusline, bold = true, sp = self.mode_color, underline = true }
			end,
			provider = function(self)
				return fmt("%s %d ", icons.diagnostics.Warn, self.warnings)
			end,
		},
		-- Hints
		{
			condition = function(self)
				return self.hints > 0
			end,
			hl = function(self)
				return { fg = c.hint, bg = c.bg_statusline, bold = true, sp = self.mode_color, underline = true }
			end,
			provider = function(self)
				return fmt("%s %d ", icons.diagnostics.Hint, self.hints)
			end,
		},
		{
			condition = function(self)
				return self.info > 0
			end,
			hl = function(self)
				return { fg = c.info, bg = c.bg_statusline, bold = true, sp = self.mode_color, underline = true }
			end,
			provider = function(self)
				return fmt("%s %d ", icons.diagnostics.Info, self.info)
			end,
		},
	}

	local plugins_update = {
		condition = function()
			return require("lazy.status").has_updates()
		end,
		init = mode_cinit,
		static = { mode_colors = mode_colors },
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
		hl = function(self)
			return { bold = true, fg = self.mode_color, bg = c.fg_gutter }
		end,
	}

	local lsp_attach = {
		condition = cond.lsp_attached,
		static = { lsp_attached = false, server_name = "", mode_colors = mode_colors },
		init = function(self)
			self.mode = vim.fn.mode()
			self.mode_color = self.mode_colors[self.mode:sub(1, 1)]
			local server_name = vim.lsp.get_clients({ bufnr = 0 })[1].name
			if server_name ~= "" then
				self.lsp_attached = true
				self.server_name = server_name
			end
		end,
		update = { "LspAttach", "LspDetach", "ModeChanged" },
		on_click = {
			callback = function()
				vim.defer_fn(function()
					vim.cmd.LspInfo()
				end, 100)
			end,
			name = "sl_lsp_click",
		},
		{
			space,
			{
				provider = function(self)
					return fmt(" %s ", string.lower(self.server_name))
				end,
				hl = function(self)
					return { bold = true, fg = self.mode_color, bg = c.fg_gutter }
				end,
			},
		},
	}

	local formatters = {
		condition = function(self)
			return not vim.tbl_contains(
				{ "", "trim_whitespace", "trim_newlines" },
				require("conform").list_formatters_for_buffer(self.bufnr)[1]
			)
		end,
		init = mode_cinit,
		static = { mode_colors = mode_colors },
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
			hl = function(self)
				return { bold = true, fg = self.mode_color, bg = c.fg_gutter }
			end,
		},
	}

	local noice_command = {
		condition = require("noice").api.status.command.has,
		init = mode_cinit,
		static = { mode_colors = mode_colors },
		space,
		{
			provider = function()
				return fmt(" %s ", require("noice").api.status.command.get())
			end,
			hl = function(self)
				return { bold = true, fg = self.mode_color, bg = c.fg_gutter }
			end,
		},
	}

	local noice_mode = {
		condition = require("noice").api.status.mode.has,
		init = mode_cinit,
		static = { mode_colors = mode_colors },
		space,
		{
			provider = function()
				return fmt(" %s ", require("noice").api.status.mode.get())
			end,
			hl = function(self)
				return { bold = true, fg = self.mode_color, bg = c.fg_gutter }
			end,
		},
	}

	local code_ruler = {
		init = mode_cinit,
		static = { mode_colors = mode_colors },
		space,
		{
			provider = " %l:%c:%L ",
			hl = function(self)
				return { bg = self.mode_color, fg = c.bg_statusline, bold = true }
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
	}

	local navic = {
		condition = function()
			return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
		end,
		update = { "CursorMoved", "ModeChanged" },
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
			mode_colors = mode_colors,
		},
		init = function(self)
			self.mode = vim.fn.mode()
			self.mode_color = self.mode_colors[self.mode:sub(1, 1)]

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
						hl = { bg = c.bg_statusline, fg = c.red, bold = true },
					})
				end
				table.insert(children, child)
			end
			self.child = self:new(children, 1)
		end,
		provider = function(self)
			return self.child:eval()
		end,
		hl = function(self)
			return {
				bg = c.bg_statusline,
				underline = true,
				sp = self.mode_color,
				italic = true,
			}
		end,
	}

	local tablist = {
		condition = function()
			return #vim.api.nvim_list_tabpages() >= 2
		end,
		space,
		init = mode_cinit,
		static = { mode_colors = mode_colors },
		require("heirline.utils").make_tablist({
			space,
			{
				provider = function(self)
					return "%" .. self.tabnr .. "T " .. self.tabpage .. " %T"
				end,
				hl = function(self)
					if self.is_active then
						return { bg = self.mode_color, bold = true, fg = c.bg_statusline }
					else
						return { bg = c.fg_gutter, fg = self.mode_color }
					end
				end,
			},
		}),
	}

	local current_path = {
		condition = buf_matches,
		init = mode_cinit,
		static = { mode_colors = mode_colors },
		space,
		{
			provider = function()
				return fmt("%s %s ", icons.kinds.Folder, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.:h"))
			end,
			hl = function(self)
				return {
					bold = true,
					fg = self.mode_color,
					bg = c.bg_statusline,
					underline = true,
					sp = self.mode_color,
				}
			end,
		},
	}

	local stc_get_extmarks = {
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
	}

	local stc_get_signs = {
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
	}

	local stc_get_lnum = {
		-- init = mode_cinit,
		-- static = { mode_colors = mode_colors },
		-- hl = function(self)
		-- 	return { fg = self.mode_color, bg = c.none, bold = false }
		-- end,
		provider = "%=%4{v:virtnum ? '' : &nu ? (&rnu && v:relnum ? v:relnum : v:lnum) . ' ' : ''}",
		on_click = {
			name = "sc_linenumber_click",
			callback = function(self, ...)
				self.handlers.Dap(self.click_args(self, ...))
			end,
		},
	}

	local stc_get_gitsign = {
		{
			condition = function()
				return cond.is_git_repo() and vim.v.virtnum == 0
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
				return not cond.is_git_repo() or vim.v.virtnum ~= 0
			end,
			provider = "",
			hl = "HeirlineStatusColumn",
		},
		space,
	}

	local disable_winbar_cb = function(args)
		return cond.buffer_matches({
			bufname = { "sh" },
			buftype = { "nofile", "terminal", "prompt", "help", "quickfix" },
			filetype = {
				"^harpoon$",
				"^dashboard$",
				"^lazy$",
				"^lazyterm$",
				"^netrw$",
				"^neotest--summary$",
				"Trouble",
				"oil",
				"mysql",
				"markdown",
				"sql",
				"json",
				"dbui",
				"dbout",
			},
		}, args.buf)
	end

	local buflist_cache = {}
	vim.api.nvim_create_autocmd({ "ModeChanged", "BufEnter", "BufLeave" }, {
		callback = function()
			vim.schedule(function()
				local items = require("harpoon"):list():display()
				for i, v in ipairs(items) do
					buflist_cache[i] = v
				end
				for i = #items + 1, #buflist_cache do
					buflist_cache[i] = nil
				end
				if #buflist_cache > 3 then
					vim.o.showtabline = 2 -- always
				elseif vim.o.showtabline ~= 1 then -- don't reset the option if it's already at default value
					vim.o.showtabline = 1 -- only when #tabpages > 1
				end
			end)
		end,
	})

	local harpoon = {
		condition = function()
			return package.loaded.harpoon and require("harpoon"):list():length() > 1
		end,
		space,
		static = { mode_colors = mode_colors },
		init = function(self)
			local children = {}
			local items = require("harpoon"):list():display()
			local bufnr = vim.api.nvim_get_current_buf()
			if not vim.api.nvim_buf_is_valid(bufnr) then
				return {}
			end
			local cur_bufname = vim.api.nvim_buf_get_name(bufnr)

			self.mode = vim.fn.mode()
			self.mode_color = self.mode_colors[self.mode:sub(1, 1)]

			for i, path in ipairs(items) do
				local child = {
					{
						provider = function()
							return fmt(" %s ", i)
						end,
						init = function()
							self.fullpath = string.len(path) < 75 and path == vim.fn.fnamemodify(cur_bufname, ":~:.")
							self.shorten_path = string.len(path) > 75
								and path == vim.fn.pathshorten(vim.fn.fnamemodify(cur_bufname, ":~:."), 3)
						end,
						hl = function()
							if self.fullpath or self.shorten_path then
								return { bg = self.mode_color, bold = true, fg = c.black }
							else
								return { bg = c.fg_gutter, fg = self.mode_color, bold = true }
							end
						end,
					},
					space,
					{
						provider = function()
							return fmt(" %s ", vim.fn.fnamemodify(path, ":t"))
						end,
						hl = function()
							if self.fullpath or self.shorten_path then
								return { bg = self.mode_color, bold = true, fg = c.black }
							else
								return { bg = c.fg_gutter, fg = self.mode_color, bold = true }
							end
						end,
					},
					space,
				}
				table.insert(children, child)
			end
			self.child = self:new(children, 1)
		end,
		provider = function(self)
			return self.child:eval()
		end,
	}

	require("heirline").setup({
		opts = { disable_winbar_cb = disable_winbar_cb, colors = c },
		tabline = { harpoon },
		winbar = { navic, align, diagnostics, current_path },
		statusline = {
			condition = buf_matches,
			vim_mode,
			git,
			filename,
			align,
			tablist,
			align,
			plugins_update,
			lsp_attach,
			formatters,
			noice_command,
			noice_mode,
			code_ruler,
		},
		statuscolumn = {
			condition = buf_matches,
			init = function(self)
				self.signs = {}
			end,
			static = stc_get_extmarks,
			stc_get_signs,
			align,
			stc_get_lnum,
			stc_get_gitsign,
		},
	})
end

return M
