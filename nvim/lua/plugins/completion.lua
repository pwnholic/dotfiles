return {
	{
		"hrsh7th/nvim-cmp",
		lazy = true,
		kyes = { "<leader>uk", "<leader>ue" },
		config = function()
			local luasnip, cmp, fmt, cmp_core = require("luasnip"), require("cmp"), string.format, require("cmp.core")
			local _cmp_on_change, last_changed, cmdline = cmp_core.on_change, 0, cmp.setup.cmdline
			local cmp_map, ts_indent = cmp.mapping, require("nvim-treesitter.indent")

			---@type string?
			local last_key

			vim.on_key(function(k)
				last_key = k
			end)

			---Improves performance when inserting in large files
			function cmp_core.on_change(self, trigger_event)
				if (last_key == " " or last_key == "\t") and string.sub(vim.fn.mode(), 1, 1) ~= "c" then
					return
				end
				local now = vim.uv.now()
				local fast_typing = now - last_changed < 32
				last_changed = now
				if not fast_typing or trigger_event ~= "TextChanged" or cmp.visible() then
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
				local line, col = table.unpack(vim.api.nvim_win_get_cursor(0))
				if col == 0 then
					return false
				end
				local str = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
				local curr_char = str:sub(col, col)
				local next_char = str:sub(col + 0, col + 1)
				return col ~= -1
					and curr_char:match("%s") == nil
					and not vim.tbl_contains({ '"', "'", "", ")", "]" }, next_char)
			end

			local function follow_indent_line(fb)
				local row, col = table.unpack(vim.api.nvim_win_get_cursor(0))
				if row == 1 and col == 0 then
					return
				end
				cmp.close()
				local current_line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
				local ok, get_indent = pcall(ts_indent.get_indent, row)
				if not ok then
					get_indent = 0
				end
				if vim.fn.strcharpart(current_line, get_indent - 1, col - get_indent + 1):gsub("%s+", "") == "" then
					if get_indent > 0 and col > get_indent then
						local new_line = vim.fn.strcharpart(current_line, 0, get_indent)
							.. vim.fn.strcharpart(current_line, col)
						vim.api.nvim_buf_set_lines(0, row - 1, row, true, { new_line })
						vim.api.nvim_win_set_cursor(0, { row, math.min(get_indent or 0, vim.fn.strcharlen(new_line)) })
					elseif row > 1 and (get_indent > 0 and col + 1 > get_indent) then
						local prev_line = vim.api.nvim_buf_get_lines(0, row - 2, row - 1, true)[1]
						if vim.trim(prev_line) == "" then
							local prev_indent = ts_indent.get_indent(row - 1) or 0
							local new_line = vim.fn.strcharpart(current_line, 0, prev_indent)
								.. vim.fn.strcharpart(current_line, col)
							vim.api.nvim_buf_set_lines(0, row - 2, row, true, { new_line })
							vim.api.nvim_win_set_cursor(
								0,
								{ row - 1, math.max(0, math.min(prev_indent, vim.fn.strcharlen(new_line))) }
							)
						else
							local len = vim.fn.strcharlen(prev_line)
							local new_line = prev_line .. vim.fn.strcharpart(current_line, col)
							vim.api.nvim_buf_set_lines(0, row - 2, row, true, { new_line })
							vim.api.nvim_win_set_cursor(0, { row - 1, math.max(0, len) })
						end
					else
						fb()
					end
				else
					fb()
				end
			end

			local function clamp_item(field, min_width, max_width, items)
				if not items[field] or not type(items) == "string" then
					return
				end
				if min_width > max_width then
					min_width, max_width = max_width, min_width
				end
				local field_str = items[field]
				local field_width = vim.fn.strdisplaywidth(field_str)
				if field_width > max_width then
					local former_width = math.floor(max_width * 0.6)
					local latter_width = math.max(0, max_width - former_width - 1)
					items[field] = fmt("%s...%s", field_str:sub(1, former_width), field_str:sub(-latter_width))
				elseif field_width < min_width then
					items[field] = fmt("%-" .. min_width .. "s", field_str)
				end
			end

			local cmp_opts = {
				completion = { completeopt = "menu,menuone,noinsert" },
				experimental = { ghost_text = { hl_group = "CmpGhostText" } },
				sorting = {
					priority_weight = 100,
					comparators = {
						function(lhs, rhs)
							return lhs:get_kind() > rhs:get_kind()
						end,
						cmp.config.compare.offset,
						cmp.config.compare.exact,
						cmp.config.compare.score,
						function(lhs, rhs)
							lhs:get_kind()
							local _, lhs_under = lhs.completion_item.label:find("^_+")
							local _, rhs_under = rhs.completion_item.label:find("^_+")
							lhs_under = lhs_under or 0
							rhs_under = rhs_under or 0
							return lhs_under < rhs_under
						end,
						cmp.config.compare.kind,
						cmp.config.compare.locality,
						cmp.config.compare.recently_used,
						cmp.config.compare.sort_text,
						cmp.config.compare.order,
					},
				},
				performance = { debounce = 80, throttle = 50, fetching_timeout = 200 },
				enabled = function()
					if
						vim.tbl_contains({ "prompt" }, vim.bo.buftype)
						or vim.tbl_contains({ "oil", "noice" }, vim.bo.filetype)
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
				-- matching = {
				-- 	disallow_fuzzy_matching = false,
				-- 	disallow_partial_matching = false,
				-- 	disallow_prefix_unmatching = false,
				-- },
				window = {
					completion = cmp.config.window.bordered({
						winhighlight = "CmpMenu:CmpMenu,FloatBorder:Comment,CursorLine:PmenuSel",
						side_padding = 1,
						border = vim.g.border,
					}),
					documentation = cmp.config.disable,
				},
				mapping = {
					["<BS>"] = cmp_map(follow_indent_line, { "i" }),
					["<Tab>"] = {
						["c"] = function()
							if cmp.visible() then
								cmp.select_next_item()
							else
								cmp.complete()
							end
						end,
						["i"] = function(fb)
							local row, col = table.unpack(vim.api.nvim_win_get_cursor(0))
							local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
							local get_indent = ts_indent.get_indent(row)

							if cmp.visible() then
								cmp.select_next_item()
							elseif luasnip.expand_or_jumpable() then
								luasnip.expand_or_jump()
							elseif has_words_before() then
								cmp.complete()
							elseif col < get_indent and line:sub(1, col):gsub("^%s+", "") == "" then
								vim.api.nvim_buf_set_lines(
									0,
									row - 1,
									row,
									true,
									{ string.rep(" ", get_indent or 0) .. line:sub(col) }
								)
								vim.api.nvim_win_set_cursor(0, { row, math.max(0, get_indent) })
								local client = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })[1]
								local ctx = {}
								ctx.client_id = client.id
								ctx.bufnr = vim.api.nvim_get_current_buf()
								vim.lsp.inlay_hint.on_refresh(nil, nil, ctx, nil)
							else
								fb()
							end
						end,
					},

					["<S-Tab>"] = {
						["c"] = function()
							if cmp.visible() then
								cmp.select_prev_item()
							else
								cmp.complete()
							end
						end,
						["i"] = function(fb)
							if cmp.visible() then
								cmp.select_prev_item()
							elseif luasnip.jumpable(-1) then
								luasnip.jump(-1)
							else
								fb()
							end
						end,
					},
					["<C-h>"] = {
						["i"] = function()
							if luasnip.get_active_snip() then
								luasnip.jump(-1)
							else
								local cur = vim.api.nvim_win_get_cursor(0)
								pcall(vim.api.nvim_win_set_cursor, 0, { cur[1], cur[2] - 1 })
							end
						end,
					},
					["<C-l>"] = {
						["i"] = function()
							if luasnip.get_active_snip() then
								luasnip.jump(1)
							else
								local cur = vim.api.nvim_win_get_cursor(0)
								pcall(vim.api.nvim_win_set_cursor, 0, { cur[1], cur[2] + 1 })
							end
						end,
					},
					["<C-y>"] = cmp_map(
						cmp_map.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false }),
						{ "i", "c" }
					),
					["<C-p>"] = {
						["c"] = cmp_map.select_prev_item(),
						["i"] = function(fb)
							if cmp.visible() then
								return cmp_map.select_prev_item({ behavior = cmp.SelectBehavior.Select })(fb)
							elseif luasnip.choice_active() then
								luasnip.change_choice(-1)
							else
								cmp.complete()
							end
						end,
					},
					["<C-n>"] = {
						["c"] = cmp_map.select_next_item(),
						["i"] = function(fb)
							if cmp.visible() then
								return cmp_map.select_next_item({ behavior = cmp.SelectBehavior.Select })(fb)
							elseif luasnip.choice_active() then
								luasnip.change_choice(1)
							else
								return cmp_map.complete({ reason = cmp.ContextReason.Auto })(fb)
							end
						end,
					},
					["<C-f>"] = cmp_map(cmp_map.scroll_docs(4), { "i", "c" }),
					["<C-b>"] = cmp_map(cmp_map.scroll_docs(-4), { "i", "c" }),
					["<C-Space>"] = cmp_map.complete(),
					["<C-e>"] = cmp_map.abort(),
					["<CR>"] = cmp_map(function(fb)
						if cmp.visible() then
							return cmp_map.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true })(fb)
						else
							return fb()
						end
					end, { "i" }),
					["<S-CR>"] = cmp_map.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
					["<C-CR>"] = function(fb)
						cmp.abort()
						fb()
					end,
				},
				sources = cmp.config.sources({
					{ name = "luasnip", max_item_count = 4, priority = 600 },
					{
						name = "async_path",
						priority = 1000,
						option = {
							get_cwd = function()
								return require("directory").get_cwd() --[[@as string]]
							end,
						},
					},
					{
						name = "nvim_lsp",
						max_item_count = 20,
						priority = 900,
						entry_filter = function(entry, ctx)
							if
								ctx.filetype == "go"
								and vim.tbl_contains(
									{ "ReadField", "FastRead", "WriteField", "FastWrite" },
									entry:get_completion_item().label
								)
							then
								return false
							end
							return true
						end,
					},
					{
						name = "rg",
						keyword_length = 4,
						priority = 300,
						priority_weight = 70,
						option = {
							additional_arguments = table.concat({
								"--hidden",
								"--follow",
								"--max-filesize",
								"2M",
								"-g",
								fmt("'!{%s}/'", table.concat(require("directory").ignore_folder, ",")),
								"-g",
								fmt("'!{%s}'", table.concat(require("directory").ignore_file, ",")),
								"-e",
							}, " "),
							cwd = require("directory").get_cwd(),
						},
						entry_filter = function(entry)
							return not entry.exact
						end,
					},
				}),
				formatting = {
					fields = { "kind", "abbr", "menu" },
					format = function(entry, item)
						local icons = require("icons").kinds
						if item.kind == "Folder" then
							item.kind = icons.Folder
							item.kind_hl_group = "Directory"
						elseif item.kind == "File" then
							local icon, hl = require("nvim-web-devicons").get_icon(
								vim.fs.basename(item.word),
								vim.fn.fnamemodify(item.word, ":e"),
								{ default = true }
							)
							item.kind = icon or icons.File
							item.kind_hl_group = hl or "CmpItemKindFile"
						else
							item.dup = ({ rg = 1, async_path = 1, nvim_lsp = 0, luasnip = 1 })[entry.source.name] or 0
							item.menu = item.kind
							item.menu_hl_group = "CmpItemKind" .. item.kind
							item.kind = vim.fn.strcharpart(icons[item.kind] or "", 0, 2)
						end
						clamp_item(
							"abbr",
							vim.go.pw,
							math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.24)),
							item
						)
						clamp_item("menu", 0, math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.10)), item)
						return item
					end,
				},
			}

			cmdline("/", {
				window = { documentation = false },
				formatting = {
					fields = { cmp.ItemField.Abbr },
					format = function(_, cmp_item)
						clamp_item(
							"abbr",
							vim.go.pw,
							math.max(5, math.ceil(vim.api.nvim_win_get_width(0) * 0.24)),
							cmp_item
						)
						return cmp_item
					end,
				},
				sources = { { name = "rg" } },
			})
			cmdline("?", {
				window = { documentation = false },
				formatting = {
					fields = { cmp.ItemField.Abbr },
					format = function(_, cmp_item)
						clamp_item(
							"abbr",
							vim.go.pw,
							math.max(5, math.ceil(vim.api.nvim_win_get_width(0) * 0.24)),
							cmp_item
						)
						return cmp_item
					end,
				},
				sources = { { name = "rg" } },
			})
			cmdline(":", {
				window = { documentation = false },
				formatting = {
					fields = { cmp.ItemField.Abbr },
					format = function(_, cmp_item)
						clamp_item(
							"abbr",
							vim.go.pw,
							math.max(5, math.ceil(vim.api.nvim_win_get_width(0) * 0.24)),
							cmp_item
						)
						return cmp_item
					end,
				},
				sources = { { name = "async_path", group_index = 1 }, { name = "cmdline", group_index = 2 } },
			})
			cmdline("@", { enabled = false })
			cmdline(">", { enabled = false })
			cmdline("-", { enabled = false })
			cmdline("=", { enabled = false })

			local enabled, cmp_on = true, true
			vim.keymap.set("n", "<leader>uk", function()
				enabled = not enabled
				if enabled then
					vim.notify("Enabled Completion", 2, { title = "Completion" })
					return cmp.setup(cmp_opts)
				else
					cmp_on = false
					vim.notify("Disabled Completion", 2, { title = "Completion" })
					return cmp.setup({ enabled = enabled })
				end
			end, { desc = "Toggle Completion" })

			vim.keymap.set("n", "<leader>ue", function()
				cmp_on = not cmp_on
				if cmp_on then
					vim.notify("Disabled Documentation", 2, { title = "Completion" })
					return cmp.setup(cmp_opts)
				else
					vim.notify("Enabled Documentation", 2, { title = "Completion" })
					return cmp.setup(vim.tbl_extend("force", cmp_opts, {
						documentation = {
							winhighlight = "CmpMenu:CmpMenu,FloatBorder:Comment,CursorLine:PmenuSel",
							border = vim.g.border,
							max_width = 70,
							max_height = 13,
						},
					}))
				end
			end, { desc = "Toggle Documentation" })

			cmp.setup(cmp_opts)
		end,
	},
	{ "hrsh7th/cmp-nvim-lsp", event = "LspAttach" },
	{ "saadparwaiz1/cmp_luasnip", event = "InsertEnter" },
	{ "FelipeLema/cmp-async-path", event = { "InsertEnter", "CmdlineEnter" } },
	{ "lukas-reineke/cmp-rg", event = "InsertEnter" },
	{ "hrsh7th/cmp-cmdline", event = "CmdlineEnter" },
	{
		"rafamadriz/friendly-snippets",
		event = "InsertEnter",
		config = function()
			local paths = vim.fn.stdpath("config") .. "/snippets" --[[@as string]]
			return require("luasnip.loaders.from_vscode").lazy_load({ paths = paths })
		end,
	},
	{
		"L3MON4D3/LuaSnip",
		event = "InsertEnter",
		build = "make install_jsregexp",
		config = function()
			local ls = require("luasnip")
			local ls_type = require("luasnip.util.types")
			local ls_util = require("luasnip.util.util")
			ls.setup({
				region_check_events = "CursorMoved,CursorMovedI",
				delete_check_events = "TextChanged,TextChangedI",
				ext_base_prio = 300,
				ft_func = require("luasnip.extras.filetype_functions").from_cursor_pos,
				store_selection_keys = "<Tab>",
				ext_opts = {
					[ls_type.choiceNode] = { active = { virt_text = { { "│", "DashboardKey" } } } },
					[ls_type.insertNode] = {
						unvisited = { virt_text = { { "│", "Comment" } }, virt_text_pos = "inline" },
					},
					[ls_type.exitNode] = {
						unvisited = { virt_text = { { "│", "Comment" } }, virt_text_pos = "inline" },
					},
				},
				parser_nested_assembler = function(_, snippet)
					local select = function(snip, no_move)
						snip.parent:enter_node(snip.indx)
						-- upon deletion, extmarks of inner nodes should shift to end of
						-- placeholder-text.
						for _, node in ipairs(snip.nodes) do
							node:set_mark_rgrav(true, true)
						end
						-- SELECT all text inside the snippet.
						if not no_move then
							vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
							local pos_begin, pos_end = snip.mark:pos_begin_end()
							ls_util.normal_move_on(pos_begin)
							vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("v", true, false, true), "n", true)
							ls_util.normal_move_before(pos_end)
							vim.api.nvim_feedkeys(
								vim.api.nvim_replace_termcodes("o<C-G>", true, false, true),
								"n",
								true
							)
						end
					end
					function snippet:jump_into(dir, no_move)
						if self.active then
							-- inside snippet, but not selected.
							if dir == 1 then
								self:input_leave()
								return self.next:jump_into(dir, no_move)
							else
								select(self, no_move)
								return self
							end
						else
							-- jumping in from outside snippet.
							self:input_enter()
							if dir == 1 then
								select(self, no_move)
								return self
							else
								return self.inner_last:jump_into(dir, no_move)
							end
						end
					end
					-- this is called only if the snippet is currently selected.
					function snippet:jump_from(dir, no_move)
						if dir == 1 then
							return self.inner_first:jump_into(dir, no_move)
						else
							self:input_leave()
							return self.prev:jump_into(dir, no_move)
						end
					end
					return snippet
				end,
			})
			vim.api.nvim_create_autocmd("InsertLeave", {
				group = vim.api.nvim_create_augroup("Unlink_Snippet", { clear = true }),
				desc = "Cancel the snippet session when leaving insert mode",
				callback = function(args)
					if
						ls.session
						and ls.session.current_nodes[args.buf]
						and not ls.session.jump_active
						and not ls.choice_active()
					then
						ls.unlink_current()
					end
				end,
			})
		end,
	},
}
