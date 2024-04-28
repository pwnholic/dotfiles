local luasnip = require("luasnip")
local nvim_cmp = require("cmp")
local nvim_cmp_core = require("cmp.core")
local ts_indent = require("nvim-treesitter.indent")
local _cmp_on_change = nvim_cmp_core.on_change
local last_changed = 0

---@type string?
local last_key

vim.on_key(function(k)
	last_key = k
end)

---Improves performance when inserting in large files
function nvim_cmp_core.on_change(self, trigger_event)
	if (last_key == " " or last_key == "\t") and string.sub(vim.fn.mode(), 1, 1) ~= "c" then
		return
	end
	---@diagnostic disable-next-line: undefined-field
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

local has_words_before = function()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	if col == 0 then
		return false
	end
	local str = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
	local curr_char = str:sub(col, col)
	local next_char = str:sub(col + 0, col + 1)
	-- local starting_spaces = #(str:match("^%s+") or "")
	return col ~= -1
		and curr_char:match("%s") == nil
		and next_char ~= '"'
		and next_char ~= "'"
		and next_char ~= "}"
		and next_char ~= ")"
		and next_char ~= "]"
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
	cmp_yanky = { name = "cmp_yanky", priority = 400, option = { onlyCurrentFiletype = false, minLength = 3 } },
	nvim_lsp = { name = "nvim_lsp", max_item_count = 20, priority = 900 },
	fuzzy_path = {
		name = "fuzzy_path",
		priority = 1000,
        --stylua: ignore start
		option = { fd_cmd = { "fd", "-p", "-H", "-L", "-td", "-tf", "-tl", "--max-results=1024", "--mount", "-c=never", "-E=*.git/", "-E=*.venv/", "-E=*Cache*/", "-E=*cache*/", "-E=.*Cache*/", "-E=.*cache*/", "-E=.*wine/", "-E=.cargo/", "-E=.conda/", "-E=.dot/", "-E=.fonts/", "-E=.ipython/", "-E=.java/", "-E=.jupyter/", "-E=.luarocks/", "-E=.mozilla/", "-E=.npm/", "-E=.nvm/", "-E=.steam*/", "-E=.thunderbird/", "-E=.tmp/", "-E=__pycache__/", "-E=dosdevices/", "-E=node_modules/", "-E=vendor/", "-E=venv/", } },
		--stylua: ignore end
		entry_filter = function()
			return vim.bo.ft ~= "markdown" and vim.bo.ft ~= "tex"
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

local function follow_expandtab(fallback)
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

local function clamp_items_format(field, min_width, max_width, cmp_items)
	if not cmp_items[field] or not type(cmp_items) == "string" then
		return
	end
	if min_width > max_width then
		min_width, max_width = max_width, min_width
	end
	local field_str = cmp_items[field]
	local field_width = vim.fn.strdisplaywidth(field_str)
	if field_width > max_width then
		local former_width = math.floor(max_width * 0.6)
		local latter_width = math.max(0, max_width - former_width - 1)
		cmp_items[field] = string.format("%s...%s", field_str:sub(1, former_width), field_str:sub(-latter_width))
	elseif field_width < min_width then
		cmp_items[field] = string.format("%-" .. min_width .. "s", field_str)
	end
end

local fuzzy_path_ok, fuzzy_path_comparator = pcall(require, "cmp_fuzzy_path.compare")
if not fuzzy_path_ok then
	fuzzy_path_comparator = function() end
end

local cmp_opts = {
	completion = {
		completeopt = "menu,menuone,noselect",
		autocomplete = { "TextChanged", "TextChangedI", "TextChangedT" },
	},
	experimental = { ghost_text = { hl_group = "CmpGhostText" } },
	sorting = {
		priority_weight = 100,
		comparators = {
			fuzzy_path_comparator,
			nvim_cmp.config.compare.offset,
			nvim_cmp.config.compare.exact,
			nvim_cmp.config.compare.score,
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
			nvim_cmp.config.compare.sort_text,
			nvim_cmp.config.compare.order,
		},
	},
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
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	matching = {
		disallow_fuzzy_matching = false,
		disallow_partial_matching = false,
		disallow_prefix_unmatching = false,
	},
	window = {
		completion = nvim_cmp.config.window.bordered({
			winhighlight = "CmpMenu:CmpMenu,FloatBorder:Comment,CursorLine:PmenuSel",
			side_padding = 1,
			border = vim.g.border,
		}),
		documentation = nvim_cmp.config.disable,
	},
	mapping = {
		["<BS>"] = nvim_cmp.mapping(follow_expandtab, { "i" }),
		["<Tab>"] = {
			["c"] = function()
				if nvim_cmp.visible() then
					nvim_cmp.select_next_item()
				else
					nvim_cmp.complete()
				end
			end,
			["i"] = function(fallback)
				local cursor_row, cursor_col = table.unpack(vim.api.nvim_win_get_cursor(0))
				local current_line = vim.api.nvim_buf_get_lines(0, cursor_row - 1, cursor_row, true)[1]
				local get_indent = ts_indent.get_indent(cursor_row)

				if nvim_cmp.visible() and not vim.snippet.active() then
					nvim_cmp.select_next_item()
				elseif luasnip.expand_or_jumpable() then
					vim.fn.feedkeys(
						vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true),
						""
					)
				elseif has_words_before() then
					nvim_cmp.complete()
				elseif cursor_col < get_indent and current_line:sub(1, cursor_col):gsub("^%s+", "") == "" then
					vim.api.nvim_buf_set_lines(
						0,
						cursor_row - 1,
						cursor_row,
						true,
						{ string.rep(" ", get_indent or 0) .. current_line:sub(cursor_col) }
					)
					vim.api.nvim_win_set_cursor(0, { cursor_row, math.max(0, get_indent) })
					local client = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })[1]
					local ctx = {}
					ctx.client_id = client.id
					ctx.bufnr = vim.api.nvim_get_current_buf()
					vim.lsp.inlay_hint.on_refresh(nil, nil, ctx, nil)
				elseif cursor_col >= get_indent then
					require("tabout").tabout()
				else
					fallback()
				end
			end,
		},

		["<S-Tab>"] = {
			["c"] = function()
				if nvim_cmp.visible() then
					nvim_cmp.select_prev_item()
				else
					nvim_cmp.complete()
				end
			end,
			["i"] = function(fallback)
				if nvim_cmp.visible() then
					nvim_cmp.select_prev_item()
				elseif luasnip.jumpable(-1) then
					vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
				else
					fallback()
				end
			end,
		},
		["<C-y>"] = nvim_cmp.mapping(
			nvim_cmp.mapping.confirm({ behavior = nvim_cmp.ConfirmBehavior.Replace, select = false }),
			{ "i", "c" }
		),
		["<C-p>"] = {
			["c"] = nvim_cmp.mapping.select_prev_item(),
			["i"] = function(fallback)
				if nvim_cmp.visible() then
					return nvim_cmp.mapping.select_prev_item({ behavior = nvim_cmp.SelectBehavior.Select })(fallback)
				elseif luasnip.choice_active() then
					luasnip.change_choice(-1)
				else
					nvim_cmp.complete()
				end
			end,
		},
		["<C-n>"] = {
			["c"] = nvim_cmp.mapping.select_next_item(),
			["i"] = function(fallback)
				if nvim_cmp.visible() then
					return nvim_cmp.mapping.select_next_item({ behavior = nvim_cmp.SelectBehavior.Select })(fallback)
				elseif luasnip.choice_active() then
					luasnip.change_choice(1)
				else
					return nvim_cmp.mapping.complete({ reason = nvim_cmp.ContextReason.Auto })(fallback)
				end
			end,
		},
		["<C-f>"] = nvim_cmp.mapping(nvim_cmp.mapping.scroll_docs(4), { "i", "c" }),
		["<C-b>"] = nvim_cmp.mapping(nvim_cmp.mapping.scroll_docs(-4), { "i", "c" }),
		["<C-Space>"] = nvim_cmp.mapping.complete(),
		["<C-e>"] = nvim_cmp.mapping.abort(),
		["<CR>"] = nvim_cmp.mapping(function(fallback)
			if nvim_cmp.visible() then
				return nvim_cmp.mapping.confirm({ behavior = nvim_cmp.ConfirmBehavior.Insert, select = true })(fallback)
			else
				return fallback()
			end
		end, { "i" }),
		["<S-CR>"] = nvim_cmp.mapping.confirm({ behavior = nvim_cmp.ConfirmBehavior.Replace, select = true }),
		["<C-CR>"] = function(fallback)
			nvim_cmp.abort()
			fallback()
		end,
	},
	sources = nvim_cmp.config.sources({
		cmp_source.luasnip,
		cmp_source.calc,
		cmp_source.nvim_lsp,
		cmp_source.fuzzy_path,
		cmp_source.rg,
		cmp_source.cmp_yanky,
	}),
	formatting = {
		fields = { "kind", "abbr", "menu" },
		format = function(entry, item)
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
			clamp_items_format("abbr", vim.go.pw, math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.24)), item)
			clamp_items_format("menu", 0, math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.10)), item)
			return item
		end,
	},
}

nvim_cmp.setup.cmdline("/", {
	window = { documentation = false },
	formatting = { fields = { nvim_cmp.ItemField.Abbr } },
	sources = { cmp_source.rg, cmp_source.cmp_yanky },
})

nvim_cmp.setup.cmdline("?", {
	window = { documentation = false },
	formatting = { fields = { nvim_cmp.ItemField.Abbr } },
	sources = { cmp_source.rg, cmp_source.cmp_yanky },
})

nvim_cmp.setup.cmdline(":", {
	enabled = true,
	formatting = { fields = { nvim_cmp.ItemField.Abbr } },
	sources = {
		{ name = "cmdline" },
		cmp_source.fuzzy_path,
		cmp_source.cmp_yanky,
	},
})

nvim_cmp.setup.cmdline("@", { enabled = false })
nvim_cmp.setup.cmdline(">", { enabled = false })
nvim_cmp.setup.cmdline("-", { enabled = false })
nvim_cmp.setup.cmdline("=", { enabled = false })

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
