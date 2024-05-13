local conditions = require("heirline.conditions")
local fmt = string.format
local space, align = { provider = " " }, { provider = "%=" }
local colors = require("tokyonight.colors").setup()
local icons = require("utils.icons")

local function buf_matches()
	if
		not conditions.buffer_matches({
			bufname = { "sh" },
			buftype = { "nofile", "terminal", "prompt", "quickfix" },
			filetype = {
				"^harpoon$",
				"dashboard",
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
	n = colors.blue2,
	i = colors.green,
	v = colors.magenta,
	V = colors.orange,
	["\22"] = colors.red,
	c = colors.cyan,
	s = colors.yellow,
	S = colors.yellow,
	["\19"] = colors.yellow,
	r = colors.green,
	["!"] = colors.red,
	R = colors.red,
	t = colors.teal,
}

vim.api.nvim_create_autocmd("ModeChanged", {
	callback = function()
		local mode_clr = mode_colors[vim.fn.mode():sub(1, 1)]
		vim.api.nvim_set_hl(0, "Winbar", { underline = true, sp = mode_clr, bg = colors.bg_statusline, italic = true })
		vim.api.nvim_set_hl(0, "CursorLineNr", { fg = mode_clr, bg = colors.none, bold = true })
		vim.api.nvim_set_hl(0, "TermCursor", { bg = mode_clr })
		vim.api.nvim_set_hl(0, "Cursor", { bg = mode_clr })
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
	{

		provider = function(self)
			return fmt("%s%s%s", " %1(", self.mode_names[self.mode], "%) ")
		end,
		hl = function(self)
			return { bg = self.mode_color, fg = colors.bg_statusline, bold = true }
		end,
	},
	space,
}

local git = {
	condition = conditions.is_git_repo,
	init = function(self)
		self.status_dict = vim.b.gitsigns_status_dict
	end,
	{
		{
			provider = function(self)
				return fmt(" %s %s ", "", (self.status_dict.head == "" and "main" or self.status_dict.head))
			end,
			hl = { fg = colors.blue2, bg = colors.fg_gutter, bold = true },
		},
	},
	{
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
	{
		init = function(self)
			self.icon, self.fg = require("nvim-web-devicons").get_icon_color_by_filetype(vim.bo.filetype)
		end,
		provider = function(self)
			return fmt("%s ", self.icon or "")
		end,
		hl = function(self)
			return { fg = self.fg, bg = colors.bg_statusline }
		end,
	},
	{
		{
			condition = function()
				return not vim.tbl_contains({ "[No Name]", "" }, vim.api.nvim_buf_get_name(0))
			end,
			init = mode_cinit,
			static = { mode_colors = mode_colors },
			{
				provider = function()
					-- TODO: fix oil-trash:/// error
					if vim.bo.filetype == "oil" then
						local path = vim.api
							.nvim_buf_get_name(0)
							:gsub("oil%-trash://", "[trash] ")
							:gsub("oil://", "")
							:gsub(vim.env.HOME, "~")
							:gsub("/$", "")
						return icons.kinds.Folder .. " " .. path .. "/"
					end
					return fmt(" %s", vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"))
				end,
				hl = function(self)
					return { bold = true, fg = self.mode_color, bg = colors.bg_statusline }
				end,
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
}

local diagnostics = {
	condition = conditions.has_diagnostics,
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
			return {
				fg = colors.error,
				bg = colors.bg_statusline,
				bold = true,
				sp = self.mode_color,
				underline = true,
			}
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
			return {
				fg = colors.warning,
				bg = colors.bg_statusline,
				bold = true,
				sp = self.mode_color,
				underline = true,
			}
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
			return {
				fg = colors.hint,
				bg = colors.bg_statusline,
				bold = true,
				sp = self.mode_color,
				underline = true,
			}
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
			return {
				fg = colors.info,
				bg = colors.bg_statusline,
				bold = true,
				sp = self.mode_color,
				underline = true,
			}
		end,
		provider = function(self)
			return fmt("%s %d ", icons.diagnostics.Info, self.info)
		end,
	},
}

local plugins_update = {
	condition = require("lazy.status").has_updates,
	init = mode_cinit,
	static = { mode_colors = mode_colors },
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
		return { bold = true, fg = self.mode_color, bg = colors.fg_gutter }
	end,
}

local lsp_attach = {
	condition = conditions.lsp_attached,
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
				return { bold = true, fg = self.mode_color, bg = colors.fg_gutter }
			end,
		},
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
			return { bold = true, fg = self.mode_color, bg = colors.fg_gutter }
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
			return { bold = true, fg = self.mode_color, bg = colors.fg_gutter }
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
					provider = "   ",
					hl = { bg = colors.bg_statusline, fg = self.mode_color, bold = true },
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
			bg = colors.bg_statusline,
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
					return { bg = self.mode_color, bold = true, fg = colors.bg_statusline }
				else
					return { bg = colors.fg_gutter, fg = self.mode_color }
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
			return fmt(
				"%s %s ",
				icons.kinds.Folder,
				vim.fn.fnamemodify(vim.fs.normalize(vim.fs.dirname(vim.api.nvim_buf_get_name(0))), ":~")
			)
		end,
		hl = function(self)
			return {
				bold = true,
				fg = self.mode_color,
				bg = colors.bg_statusline,
				underline = true,
				sp = self.mode_color,
			}
		end,
	},
}

local stc_get_extmarks = {
	bufnr = vim.api.nvim_win_get_buf(0),
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
		Fold = function(args)
			local line = args.mousepos.line
			if vim.fn.foldlevel(line) <= vim.fn.foldlevel(line - 1) then
				return
			end
			vim.cmd.execute("'" .. line .. "fold" .. (vim.fn.foldclosed(line) == -1 and "close" or "open") .. "'")
		end,
		GitSigns = function()
			vim.defer_fn(function()
				require("gitsigns").blame_line({ full = true })
			end, 100)
		end,
	},
}

local git_ns = vim.api.nvim_create_namespace("gitsigns_extmark_signs_")
local function get_signs(lnum)
	local signs = {}
	if vim.fn.has("nvim-0.10") > 0 then
		local extmarks = vim.api.nvim_buf_get_extmarks(
			0,
			-1,
			{ lnum - 1, 0 },
			{ lnum - 1, -1 },
			{ details = true, type = "sign" }
		)

		for _, extmark in pairs(extmarks) do
			-- Exclude gitsigns
			if extmark[4].ns_id ~= git_ns then
				signs[#signs + 1] = {
					name = extmark[4].sign_hl_group or "",
					text = extmark[4].sign_text,
					sign_hl_group = extmark[4].sign_hl_group,
					priority = extmark[4].priority,
				}
			end
		end
	else
		signs = vim.fn.sign_getplaced(vim.api.nvim_win_get_buf(0), { group = "*", lnum = vim.v.lnum })

		-- if #signs == 0 or signs[1].signs == nil then
		--   return
		-- end

		-- Filter out git signs
		signs = vim.tbl_filter(function(sign)
			return not vim.startswith(sign.group, "gitsigns")
		end, signs[1].signs)

		-- Update sign meta data
		for _, sign in ipairs(signs) do
			sign.text = vim.fn.sign_getdefined(sign.name)[1].text
			sign.sign_hl_group = sign.name
		end
	end

	table.sort(signs, function(a, b)
		return (a.priority or 0) > (b.priority or 0)
	end)

	return signs
end

local stc_get_signs = {
	init = function(self)
		local signs = get_signs(vim.v.lnum)
		self.sign = signs[1]
	end,
	provider = function(self)
		return self.sign and self.sign.text or "  "
	end,
	hl = function(self)
		return self.sign and self.sign.sign_hl_group
	end,
	on_click = {
		name = "sc_sign_click",
		update = true,
		callback = function(self, ...)
			local line = self.click_args(self, ...).mousepos.line
			local sign = get_signs(line)[1]
			if sign then
				self:resolve(sign.name)
			end
		end,
	},
}

local stc_get_lnum = {
	provider = "%=%4{v:virtnum ? '' : &nu ? (&rnu && v:relnum ? v:relnum : v:lnum) . ' ' : ''}",
	on_click = {
		name = "sc_linenumber_click",
		callback = function(self, ...)
			self.handlers.Dap(self.click_args(self, ...))
		end,
	},
}

-- local stc_get_fold = {
-- 	init = function(self)
-- 		self.can_fold = vim.fn.foldlevel(vim.v.lnum) > vim.fn.foldlevel(vim.v.lnum - 1)
-- 	end,
-- 	{
-- 		condition = function(self)
-- 			return vim.v.virtnum == 0 and self.can_fold
-- 		end,
-- 		provider = "%C",
-- 	},
-- 	{
-- 		condition = function(self)
-- 			return not self.can_fold
-- 		end,
-- 		space,
-- 	},
-- 	on_click = {
-- 		name = "sc_fold_click",
-- 		callback = function(self, ...)
-- 			self.handlers.Fold(self.click_args(self, ...))
-- 		end,
-- 	},
-- }

local stc_get_gitsign = {
	{
		condition = function()
			return conditions.is_git_repo()
		end,
		init = function(self)
			local extmark = vim.api.nvim_buf_get_extmarks(
				0,
				git_ns,
				{ vim.v.lnum - 1, 0 },
				{ vim.v.lnum - 1, -1 },
				{ limit = 1, details = true }
			)[1]

			self.sign = extmark and extmark[4]["sign_hl_group"]
		end,
		{
			provider = "│",
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
	},
	{
		condition = function()
			return not conditions.is_git_repo()
		end,
		space,
	},
}

local disable_winbar_cb = function(args)
	return conditions.buffer_matches({
		bufname = { "sh" },
		buftype = { "nofile", "terminal", "prompt", "help", "quickfix", "vim" },
		filetype = {
			"vim",
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

local harpoon_items = {}
vim.api.nvim_create_autocmd({ "ModeChanged", "BufEnter", "BufLeave" }, {
	callback = function()
		vim.schedule(function()
			local items = require("harpoon"):list():display()
			for i, path in ipairs(items) do
				harpoon_items[i] = path
			end
			for i = #items + 1, #harpoon_items do
				harpoon_items[i] = nil
			end
			if #harpoon_items > 3 then
				vim.o.showtabline = 2 -- always
			else
				vim.o.showtabline = 0 -- only when #tabpages > 1
			end
		end)
	end,
})

local harpoon = {
	condition = function()
		return package.loaded.harpoon and #harpoon_items > 1 and require("harpoon.config").DEFAULT_LIST == "files"
	end,
	space,
	static = { mode_colors = mode_colors },
	init = function(self)
		local children = {}
		local bufnr = vim.api.nvim_get_current_buf()
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return {}
		end
		local cur_bufname = vim.api.nvim_buf_get_name(bufnr)

		self.mode = vim.fn.mode()
		self.mode_color = self.mode_colors[self.mode:sub(1, 1)]

		for i, path in ipairs(harpoon_items) do
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
							return { bg = self.mode_color, bold = true, fg = colors.black }
						else
							return { bg = colors.fg_gutter, fg = self.mode_color, bold = false }
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
							return { bg = self.mode_color, bold = true, fg = colors.black }
						else
							return { bg = colors.fg_gutter, fg = self.mode_color, bold = false }
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
	opts = { disable_winbar_cb = disable_winbar_cb, colors = colors },
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
		noice_command,
		noice_mode,
		code_ruler,
	},
	statuscolumn = {
		init = function(self)
			self.signs = {}
		end,
		condition = buf_matches,
		static = stc_get_extmarks,
		stc_get_signs,
		align,
		stc_get_lnum,
		-- stc_get_fold,
		stc_get_gitsign,
	},
})
