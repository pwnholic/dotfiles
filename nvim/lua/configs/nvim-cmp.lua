local cmp_core = require("cmp.core")
local luasnip = require("luasnip")
local nvim_cmp = require("cmp")
local tabout = require("utils.tabout")
local ts_indent = require("nvim-treesitter.indent")

---@type string?
local last_key

vim.on_key(function(k)
	last_key = k
end)

---@type integer
local last_changed = 0
local _cmp_on_change = cmp_core.on_change

---Improves performance when inserting in large files
---@diagnostic disable-next-line: duplicate-set-field
function cmp_core.on_change(self, trigger_event)
	-- Don't know why but inserting spaces/tabs causes higher latency than other
	-- keys, e.g. when holding down 's' the interval between keystrokes is less
	-- than 32ms (80 repeats/s keyboard), but when holding spaces/tabs the
	-- interval increases to 100ms, guess is is due ot some other plugins that
	-- triggers on spaces/tabs
	-- Spaces/tabs are not useful in triggering completions in insert mode but can
	-- be useful in command-line autocompletion, so ignore them only when not in
	-- command-line mode
	if (last_key == " " or last_key == "\t") and string.sub(vim.fn.mode(), 1, 1) ~= "c" then
		return
	end

	local now = vim.uv.now()
	local fast_typing = now - last_changed < 32
	last_changed = now

	if not fast_typing or trigger_event ~= "TextChanged" or nvim_cmp.visible() then
		_cmp_on_change(self, trigger_event)
		return
	end

	vim.defer_fn(function()
		if last_changed == now then
			_cmp_on_change(self, trigger_event)
		end
	end, 200)
end

---Choose the closer destination between two destinations
---@param dest1 number[]?
---@param dest2 number[]?
---@return number[]|nil
local function choose_closer(dest1, dest2)
	if not dest1 then
		return dest2
	end
	if not dest2 then
		return dest1
	end

	local current_pos = vim.api.nvim_win_get_cursor(0)
	local line_width = vim.api.nvim_win_get_width(0)
	local dist1 = math.abs(dest1[2] - current_pos[2]) + math.abs(dest1[1] - current_pos[1]) * line_width
	local dist2 = math.abs(dest2[2] - current_pos[2]) + math.abs(dest2[1] - current_pos[1]) * line_width
	if dist1 <= dist2 then
		return dest1
	else
		return dest2
	end
end

---Check if a node has length larger than 0
---@param node table
---@return boolean
local function node_has_length(node)
	local start_pos, end_pos = node:get_buf_position()
	return start_pos[1] ~= end_pos[1] or start_pos[2] ~= end_pos[2]
end

---Check if range1 contains range2
---If range1 == range2, return true
---@param range1 integer[][] 0-based range
---@param range2 integer[][] 0-based range
---@return boolean
local function range_contains(range1, range2)
	return (range2[1][1] > range1[1][1] or (range2[1][1] == range1[1][1] and range2[1][2] >= range1[1][2]))
		and (range2[1][1] < range1[2][1] or (range2[1][1] == range1[2][1] and range2[1][2] <= range1[2][2]))
		and (range2[2][1] > range1[1][1] or (range2[2][1] == range1[1][1] and range2[2][2] >= range1[1][2]))
		and (range2[2][1] < range1[2][1] or (range2[2][1] == range1[2][1] and range2[2][2] <= range1[2][2]))
end

---Check if the cursor position is in the given range
---@param range integer[][] 0-based range
---@param cursor integer[] 1,0-based cursor position
---@return boolean
local function in_range(range, cursor)
	local cursor0 = { cursor[1] - 1, cursor[2] }
	return (cursor0[1] > range[1][1] or (cursor0[1] == range[1][1] and cursor0[2] >= range[1][2]))
		and (cursor0[1] < range[2][1] or (cursor0[1] == range[2][1] and cursor0[2] <= range[2][2]))
end

---Find the parent (a previous node that contains the current node) of the node
---@param node table current node
---@return table|nil
local function node_find_parent(node)
	local range_start, range_end = node:get_buf_position()
	local prev = node.parent.snippet and node.parent.snippet.prev.prev
	while prev do
		local range_start_prev, range_end_prev = prev:get_buf_position()
		if range_contains({ range_start_prev, range_end_prev }, { range_start, range_end }) then
			return prev
		end
		prev = prev.parent.snippet and prev.parent.snippet.prev.prev
	end
end

---Check if the cursor is at the end of a node
---@param range table 0-based range
---@param cursor number[] 1,0-based cursor position
---@return boolean
local function cursor_at_end_of_range(range, cursor)
	return range[2][1] + 1 == cursor[1] and range[2][2] == cursor[2]
end

---Jump to the closer destination between a snippet and tabout
---@param snip_dest number[]
---@param tabout_dest number[]?
---@param direction number 1 or -1
---@return boolean true if a jump is performed
local function jump_to_closer(snip_dest, tabout_dest, direction)
	direction = direction or 1
	local dest = choose_closer(snip_dest, tabout_dest)
	if not dest then
		return false
	end
	if vim.deep_equal(dest, tabout_dest) then
		tabout.jump(direction)
	else
		luasnip.jump(direction)
	end
	return true
end

local fuzzy_path_ok, fuzzy_path_comparator = pcall(require, "cmp_fuzzy_path.compare")
if not fuzzy_path_ok then
	fuzzy_path_comparator = function() end
end

local function format(entry, item)
	local icons = require("utils.icons").kinds
	local sname = entry.source.name
	if item.kind == "Folder" then
		item.menu = item.kind
		item.menu_hl_group = "Directory"
		item.kind = icons.Folder
		item.kind_hl_group = "Directory"
	elseif item.kind == "File" then
		local icon, hl_group = require("nvim-web-devicons").get_icon(
			vim.fs.basename(item.word),
			vim.fn.fnamemodify(item.word, ":e"),
			{ default = true }
		)
		item.menu = item.kind
		item.menu_hl_group = hl_group or "CmpItemKindFile"
		item.kind = icon or icons.File
		item.kind_hl_group = hl_group or "CmpItemKindFile"
	else
		item.dup = ({ rg = 1, nvim_lsp = 0, luasnip = 1, calc = 0, fuzzy_path = 1, cmp_yanky = 1 })[sname] or 0

		if sname == "rg" then
			item.kind = "RipGrep"
		elseif sname == "cmp_yanky" then
			item.kind = "Yanky"
		elseif sname == "calc" then
			item.kind = "Calc"
		end

		item.menu = item.kind
		item.menu_hl_group = "CmpItemKind" .. item.kind
		item.kind = vim.fn.strcharpart(icons[item.kind] or "", 0, 2)
	end

	local function clamp_items_format(field, min_width, max_width)
		if not item[field] or not type(item) == "string" then
			return
		end
		if min_width > max_width then
			min_width, max_width = max_width, min_width
		end
		local field_str = item[field]
		local field_width = vim.fn.strdisplaywidth(field_str)
		if field_width > max_width then
			local former_width = math.floor(max_width * 0.6)
			local latter_width = math.max(0, max_width - former_width - 1)
			item[field] = string.format("%s...%s", field_str:sub(1, former_width), field_str:sub(-latter_width))
		elseif field_width < min_width then
			item[field] = string.format("%-" .. min_width .. "s", field_str)
		end
	end

	clamp_items_format("abbr", vim.go.pw, math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.24)))
	clamp_items_format("menu", 0, math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.10)))

	return item
end

local function follow_expandtab(fallback)
	if vim.bo.filetype == "markdown" then
		fallback()
		return
	end

	local cursor_row, cursor_col = table.unpack(vim.api.nvim_win_get_cursor(0))
	if cursor_row == 1 and cursor_col == 0 then
		return
	end
	nvim_cmp.close()
	local current_line = vim.api.nvim_buf_get_lines(0, cursor_row - 1, cursor_row, true)[1]
	local ok, get_indent = pcall(ts_indent.get_indent, cursor_row)
	if not ok then
		get_indent = 0
	end
	if vim.fn.strcharpart(current_line, get_indent - 1, cursor_col - get_indent + 1):gsub("%s+", "") == "" then
		if get_indent > 0 and cursor_col > get_indent then
			local new_line = vim.fn.strcharpart(current_line, 0, get_indent)
				.. vim.fn.strcharpart(current_line, cursor_col)

			vim.api.nvim_buf_set_lines(0, cursor_row - 1, cursor_row, true, { new_line })
			vim.api.nvim_win_set_cursor(0, { cursor_row, math.min(get_indent or 0, vim.fn.strcharlen(new_line)) })
		elseif cursor_row > 1 and (get_indent > 0 and cursor_col + 1 > get_indent) then
			local prev_line = vim.api.nvim_buf_get_lines(0, cursor_row - 2, cursor_row - 1, true)[1]
			if vim.trim(prev_line) == "" then
				local prev_indent = ts_indent.get_indent(cursor_row - 1) or 0
				local new_line = vim.fn.strcharpart(current_line, 0, prev_indent)
					.. vim.fn.strcharpart(current_line, cursor_col)

				vim.api.nvim_buf_set_lines(0, cursor_row - 2, cursor_row, true, { new_line })
				vim.api.nvim_win_set_cursor(
					0,
					{ cursor_row - 1, math.max(0, math.min(prev_indent, vim.fn.strcharlen(new_line))) }
				)
			else
				local len = vim.fn.strcharlen(prev_line)
				local new_line = prev_line .. vim.fn.strcharpart(current_line, cursor_col)

				vim.api.nvim_buf_set_lines(0, cursor_row - 2, cursor_row, true, { new_line })
				vim.api.nvim_win_set_cursor(0, { cursor_row - 1, math.max(0, len) })
			end
		else
			fallback()
		end
	else
		fallback()
	end
end

local function buffer_matches(patterns, bufnr)
	bufnr = bufnr or 0

	local buf_matchers = {
		filetype = function()
			return vim.bo[bufnr].filetype
		end,
		buftype = function()
			return vim.bo[bufnr].buftype
		end,
		bufname = function()
			return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
		end,
	}

	for kind, pattern_list in pairs(patterns) do
		for _, pattern in ipairs(pattern_list) do
			if buf_matchers[kind](bufnr):find(pattern) then
				return true
			end
		end
	end

	return false
end

local cmp_source = {
	calc = { name = "calc" },
	luasnip = { name = "luasnip", max_item_count = 3, priority = 700 },
	nvim_lsp = { name = "nvim_lsp", max_item_count = 20, priority = 900 },
	fuzzy_path = {
		name = "fuzzy_path",
		priority = 1000,
        --stylua: ignore start
		option = { fd_cmd = { vim.fn.executable('fd') == 1 and 'fd' or 'fdfind', "-p", "-H", "-L", "-td", "-tf", "-tl", "--max-results=1024", "--mount", "-c=never", "-E=*.git/", "-E=*.venv/", "-E=*Cache*/", "-E=*cache*/", "-E=.*Cache*/", "-E=.*cache*/", "-E=.*wine/", "-E=.cargo/", "-E=.conda/", "-E=.dot/", "-E=.fonts/", "-E=.ipython/", "-E=.java/", "-E=.jupyter/", "-E=.luarocks/", "-E=.mozilla/", "-E=.npm/", "-E=.nvm/", "-E=.steam*/", "-E=.thunderbird/", "-E=.tmp/", "-E=__pycache__/", "-E=dosdevices/", "-E=node_modules/", "-E=vendor/", "-E=venv/", } },
		--stylua: ignore end
		entry_filter = function(entry)
			return not vim.tbl_contains({ "Searching...", "No matches found" }, tostring(entry.completion_item.label))
		end,
	},
	rg = {
		name = "rg",
		keyword_length = 4,
		max_item_count = 6,
		priority = 500,
		option = {
			additional_arguments = table.concat(
				{ "--hidden", "--follow", "--max-filesize", "2M", "-g", "'!.git'", "--max-depth", "4" },
				" "
			),
			cwd = require("utils.root").get_root(),
		},
		entry_filter = function(entry)
			return not entry.exact
		end,
	},
}

local comparators = {
	fuzzy_path_comparator,
	function(lhs, rhs)
		lhs:get_kind()
		local _, lhs_under = lhs.completion_item.label:find("^_+")
		local _, rhs_under = rhs.completion_item.label:find("^_+")
		lhs_under = lhs_under or 0
		rhs_under = rhs_under or 0
		return lhs_under < rhs_under
	end,
	nvim_cmp.config.compare.kind,
	nvim_cmp.config.compare.locality,
	nvim_cmp.config.compare.recently_used,
	nvim_cmp.config.compare.exact,
	nvim_cmp.config.compare.score,
}

local cmp_opts = {
	enabled = function()
		if
			buffer_matches({
				buftype = { "nofile", "terminal", "prompt", "help", "quickfix" },
				filetype = { "oil", "noice" },
			})
			or vim.fn.reg_recording() ~= ""
			or vim.fn.reg_executing() ~= ""
			or require("cmp.config.context").in_treesitter_capture("comment")
			or vim.b.bigfile
		then
			return false
		end
		return true
	end,
	matching = {
		disallow_fuzzy_matching = false,
		disallow_partial_matching = false,
		disallow_prefix_unmatching = false,
	},
	completion = {
		completeopt = "menu,menuone",
		autocomplete = { "TextChanged", "TextChangedI", "TextChangedT" },
	},
	performance = { async_budget = 64, max_view_entries = 64 },
	formatting = { fields = { "kind", "abbr", "menu" }, format = format },
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	mapping = {
		["<BS>"] = follow_expandtab,
		["<S-Tab>"] = {
			["c"] = function()
				if tabout.get_jump_pos(-1) then
					tabout.jump(-1)
					return
				end
				if nvim_cmp.visible() then
					nvim_cmp.select_prev_item()
				else
					nvim_cmp.complete()
				end
			end,
			["i"] = function(fallback)
				if luasnip.locally_jumpable(-1) then
					local prev = luasnip.jump_destination(-1)
					local _, snip_dest_end = prev:get_buf_position()
					snip_dest_end[1] = snip_dest_end[1] + 1 -- (1, 0) indexed
					local tabout_dest = tabout.get_jump_pos(-1)
					if not jump_to_closer(snip_dest_end, tabout_dest, -1) then
						fallback()
					end
				else
					fallback()
				end
			end,
		},
		["<Tab>"] = {
			["c"] = function()
				if tabout.get_jump_pos(1) then
					tabout.jump(1)
					return
				end
				if nvim_cmp.visible() then
					nvim_cmp.select_next_item()
				else
					nvim_cmp.complete()
				end
			end,
			["i"] = function(fallback)
				if luasnip.expandable() then
					luasnip.expand()
				elseif luasnip.locally_jumpable(1) then
					local buf = vim.api.nvim_get_current_buf()
					local cursor = vim.api.nvim_win_get_cursor(0)
					local current = luasnip.session.current_nodes[buf]
					if node_has_length(current) then
						if
							current.next_choice
							or cursor_at_end_of_range({
								current:get_buf_position(),
							}, cursor)
						then
							luasnip.jump(1)
						else
							fallback()
						end
					else -- node has zero length
						local parent = node_find_parent(current)
						local range = parent and { parent:get_buf_position() }
						local tabout_dest = tabout.get_jump_pos(1)
						if tabout_dest and range and in_range(range, tabout_dest) then
							tabout.jump(1)
						else
							luasnip.jump(1)
						end
					end
				else
					fallback()
				end
			end,
		},
		["<C-p>"] = {
			["c"] = nvim_cmp.mapping.select_prev_item(),
			["i"] = function()
				if nvim_cmp.visible() then
					nvim_cmp.select_prev_item()
				elseif luasnip.choice_active() then
					luasnip.change_choice(-1)
				else
					nvim_cmp.complete()
				end
			end,
		},
		["<C-n>"] = {
			["c"] = nvim_cmp.mapping.select_next_item(),
			["i"] = function()
				if nvim_cmp.visible() then
					nvim_cmp.select_next_item()
				elseif luasnip.choice_active() then
					luasnip.change_choice(1)
				else
					nvim_cmp.complete()
				end
			end,
		},
		["<Down>"] = nvim_cmp.mapping(nvim_cmp.mapping.select_next_item(), { "i", "c" }),
		["<Up>"] = nvim_cmp.mapping(nvim_cmp.mapping.select_prev_item(), { "i", "c" }),
		["<PageDown>"] = nvim_cmp.mapping(
			nvim_cmp.mapping.select_next_item({
				count = vim.o.pumheight ~= 0 and math.ceil(vim.o.pumheight / 2) or 8,
			}),
			{ "i", "c" }
		),
		["<PageUp>"] = nvim_cmp.mapping(
			nvim_cmp.mapping.select_prev_item({
				count = vim.o.pumheight ~= 0 and math.ceil(vim.o.pumheight / 2) or 8,
			}),
			{ "i", "c" }
		),
		["<C-u>"] = nvim_cmp.mapping(nvim_cmp.mapping.scroll_docs(-4), { "i", "c" }),
		["<C-d>"] = nvim_cmp.mapping(nvim_cmp.mapping.scroll_docs(4), { "i", "c" }),
		["<C-e>"] = nvim_cmp.mapping(function(fallback)
			if nvim_cmp.visible() then
				nvim_cmp.abort()
			else
				fallback()
			end
		end, { "i", "c" }),
		["<C-y>"] = nvim_cmp.mapping(
			nvim_cmp.mapping.confirm({
				behavior = nvim_cmp.ConfirmBehavior.Replace,
				select = false,
			}),
			{ "i", "c" }
		),
		["<CR>"] = nvim_cmp.mapping(function(fallback)
			if nvim_cmp.visible() then
				return nvim_cmp.mapping.confirm({ behavior = nvim_cmp.ConfirmBehavior.Insert, select = true })(fallback)
			else
				return fallback()
			end
		end, { "i" }),
		["<S-CR>"] = nvim_cmp.mapping.confirm({ behavior = nvim_cmp.ConfirmBehavior.Replace, select = true }),
	},
	sources = nvim_cmp.config.sources({
		cmp_source.luasnip,
		cmp_source.calc,
		cmp_source.nvim_lsp,
		cmp_source.fuzzy_path,
		cmp_source.rg,
		cmp_source.cmp_yanky,
	}),
	sorting = { priority_weight = 100, comparators = comparators },
	-- cmp floating window config
	window = {
		completion = nvim_cmp.config.window.bordered({
			winhighlight = "CmpMenu:CmpMenu,FloatBorder:Comment,CursorLine:PmenuSel",
			side_padding = 1,
			border = vim.g.border,
		}),
		documentation = nvim_cmp.config.disable,
	},
}

nvim_cmp.setup.filetype({ "c", "cpp" }, {
	sorting = {
		priority_weight = 100,
		comparators = {
			function(lhs, rhs)
				lhs:get_kind()
				local _, lhs_under = lhs.completion_item.label:find("^_+")
				local _, rhs_under = rhs.completion_item.label:find("^_+")
				lhs_under = lhs_under or 0
				rhs_under = rhs_under or 0
				return lhs_under < rhs_under
			end,
			nvim_cmp.config.compare.kind,
			nvim_cmp.config.compare.locality,
			nvim_cmp.config.compare.recently_used,
			nvim_cmp.config.compare.exact,
			function(lhs, rhs) -- custom score
				local diff
				if lhs.completion_item.score and rhs.completion_item.score then
					diff = (rhs.completion_item.score * rhs.score) - (lhs.completion_item.score * lhs.score)
				else
					diff = rhs.score - lhs.score
				end
				return (diff < 0)
			end,
		},
	},
})

nvim_cmp.setup.cmdline({ "/", "?" }, {
	enabled = true,
	formatting = { fields = { nvim_cmp.ItemField.Abbr } },
	sources = { cmp_source.rg },
})

nvim_cmp.setup.cmdline(":", {
	enabled = true,
	formatting = { fields = { nvim_cmp.ItemField.Abbr } },
	sources = { { name = "cmdline" }, cmp_source.fuzzy_path },
})
nvim_cmp.setup.cmdline({ "@", ">", "-", "=" }, { enabled = false })

local Kind = nvim_cmp.lsp.CompletionItemKind
nvim_cmp.event:on("confirm_done", function(event) -- auto braket karena gk semua lsp support
	if not vim.tbl_contains({ "go", "lua", "python" } or {}, vim.bo.filetype) then
		return
	end
	local entry = event.entry
	local item = entry:get_completion_item()
	if vim.tbl_contains({ Kind.Function, Kind.Method }, item.kind) then
		local keys = vim.api.nvim_replace_termcodes("()<left>", false, false, true)
		vim.api.nvim_feedkeys(keys, "i", true)
	end
end)

local enabled, cmp_on = true, true
vim.keymap.set("n", "<leader>uk", function()
	enabled = not enabled
	if enabled then
		vim.notify("Enabled Completion", 2, { title = "Completion" })
		return nvim_cmp.setup(cmp_opts)
	else
		cmp_on = false
		vim.notify("Disabled Completion", 2, { title = "Completion" })
		return nvim_cmp.setup({ enabled = enabled })
	end
end, { desc = "Toggle Completion" })

vim.keymap.set("n", "<leader>ue", function()
	cmp_on = not cmp_on
	if cmp_on then
		vim.notify("Disabled Documentation", 2, { title = "Completion" })
		return nvim_cmp.setup(cmp_opts)
	else
		vim.notify("Enabled Documentation", 2, { title = "Completion" })
		return nvim_cmp.setup(vim.tbl_extend("force", cmp_opts, {
			documentation = {
				winhighlight = "CmpMenu:CmpMenu,FloatBorder:Comment,CursorLine:PmenuSel",
				border = vim.g.border,
				max_width = 70,
				max_height = 13,
			},
		}))
	end
end, { desc = "Toggle Documentation" })

nvim_cmp.setup(cmp_opts)
