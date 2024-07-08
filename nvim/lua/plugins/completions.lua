local utils = require("utils")
local fd_cmd = {
	vim.fn.executable("fd") == 1 and "fd" or "fdfind",
	"-p",
	"-H",
	"-L",
	"-td",
	"-tf",
	"-tl",
	"--max-results=1024",
	"--mount",
	"-c=never",
	"-E=*.git/",
	"-E=*.venv/",
	"-E=*cache*/",
	"-E=.*cache*/",
	"-E=.cargo/",
	"-E=.dot/",
	"-E=.luarocks/",
	"-E=.npm/",
	"-E=.nvm/",
	"-E=.thunderbird/",
	"-E=.tmp/",
	"-E=__pycache__/",
	"-E=node_modules/",
	"-E=vendor/",
	"-E=venv/",
}

return {
	{ "hrsh7th/cmp-nvim-lsp", event = "LspAttach" },
	{ "hrsh7th/cmp-cmdline", event = "CmdlineEnter" },
	{ "lukas-reineke/cmp-rg", event = "BufReadPre" },
	{ "tzachar/cmp-fuzzy-path", dependencies = "tzachar/fuzzy.nvim", event = "CmdlineEnter" },
	{ "saadparwaiz1/cmp_luasnip", event = "InsertEnter" },
	{
		"L3MON4D3/LuaSnip",
		build = "make install_jsregexp",
		event = "ModeChanged *:[iRss\x13vV\x16]*",
		keys = function()
			local ls = require("luasnip")
			return {
                -- stylua: ignore start
				{ "<Tab>", function() ls.jump(1) end, mode = "s", },
				{ "<S-Tab>", function() ls.jump(-1) end, mode = "s", },
				{ "<C-n>", function() return ls.choice_active() and "<Plug>luasnip-next-choice" or "<C-n>" end, mode = "s", expr = true, },
				{ "<C-p>", function() return ls.choice_active() and "<Plug>luasnip-prev-choice" or "<C-p>" end, mode = "s", expr = true, },
				-- stylua: ignore end
			}
		end,
		opts = function()
			local ls_types = require("luasnip.util.types")
			local paths = vim.fn.stdpath("config") .. "/snippets" --[[@as string]]
			require("luasnip.loaders.from_vscode").lazy_load({ paths = paths })
			return {
				keep_roots = true,
				link_roots = false,
				link_children = true,
				region_check_events = "CursorMoved,CursorMovedI",
				delete_check_events = "TextChanged,TextChangedI",
				enable_autosnippets = true,
				store_selection_keys = "<Tab>",
				ext_opts = {
					[ls_types.choiceNode] = {
						active = {
							virt_text = { { utils.icons.kinds.Enum, "Number" } },
						},
					},
					[ls_types.insertNode] = {
						unvisited = {
							virt_text = { { "│", "NonText" } },
							virt_text_pos = "inline",
						},
					},
					[ls_types.exitNode] = {
						unvisited = {
							virt_text = { { "│", "NonText" } },
							virt_text_pos = "inline",
						},
					},
				},
			}
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		version = false, -- last release is way too old
		event = "InsertEnter",
		opts = function(_, opts)
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			local function clamp(field, min_width, max_width, items)
				if not items[field] or not type(items) == "string" then
					return
				end
				-- In case that min_width > max_width
				if min_width > max_width then
					min_width, max_width = max_width, min_width
				end
				local field_str = items[field]
				local field_width = vim.fn.strdisplaywidth(field_str)
				if field_width > max_width then
					local former_width = math.floor(max_width * 0.6)
					local latter_width = math.max(0, max_width - former_width - 1)
					items[field] =
						string.format("%s...%s", field_str:sub(1, former_width), field_str:sub(-latter_width))
				elseif field_width < min_width then
					items[field] = string.format("%-" .. min_width .. "s", field_str)
				end
			end

			opts.formatting = {
				fields = { "kind", "abbr", "menu" },
				format = function(entry, items)
					local sname = entry.source.name
					if items.kind == "Folder" then
						items.menu = items.kind
						items.menu_hl_group = "Directory"
						items.kind = utils.icons.kinds.Folder
						items.kind_hl_group = "Directory"
					elseif items.kind == "File" then
						local icon, hl_group = require("nvim-web-devicons").get_icon(
							vim.fs.basename(items.word),
							vim.fn.fnamemodify(items.word, ":e"),
							{ default = true }
						)
						items.menu = items.kind
						items.menu_hl_group = hl_group or "CmpItemKindFile"
						items.kind = icon or utils.icons.kinds.File
						items.kind_hl_group = hl_group or "CmpItemKindFile"
					else
						items.dup = ({ rg = 1, nvim_lsp = 0, luasnip = 1, fuzzy_path = 1 })[sname] or 0
						if sname == "rg" then
							items.kind = "RipGrep"
						end
						items.menu = items.kind
						items.menu_hl_group = "CmpItemKind" .. items.kind
						items.kind = vim.fn.strcharpart(utils.icons.kinds[items.kind] or "", 0, 2)
					end
					clamp("abbr", vim.go.pw, math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.24)), items)
					clamp("menu", 0, math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.10)), items)
					return items
				end,
			}

			local fuzzy_path_ok, fuzzy_path = pcall(require, "cmp_fuzzy_path.compare")
			if not fuzzy_path_ok then
				fuzzy_path = function() end
			end

			opts.sorting = {
				priority_weight = 100,
				comparators = {
					fuzzy_path,
					cmp.config.compare.exact,
					cmp.config.compare.offset,
					function(lhs, rhs)
						-- Gua gak yakin ini pattern yang bagus ini "GENERAL"
						local _, lhs_under = lhs.completion_item.label:find("^_+")
						local _, rhs_under = rhs.completion_item.label:find("^_+")
						lhs_under = lhs_under or 0
						rhs_under = rhs_under or 0
						if lhs_under > rhs_under then
							return false
						elseif lhs_under < rhs_under then
							return true
						end
					end,
					cmp.config.compare.kind,
					cmp.config.compare.locality,
					cmp.config.compare.recently_used,
				},
			}
			opts.snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			}

			-- opts.matching = {
			-- 	disallow_fuzzy_matching = false,
			-- 	disallow_partial_matching = false,
			-- 	disallow_prefix_unmatching = false,
			-- }

			opts.completion = {
				completeopt = "menu,menuone,noinsert",
			}

			opts.window = {
				completion = cmp.config.window.bordered({
					winhighlight = "CmpMenu:CmpMenu,FloatBorder:FzfLuaBorder,CursorLine:PmenuSel",
					side_padding = 1,
					border = vim.g.border,
				}),
				documentation = cmp.config.disable,
			}

			opts.enabled = function()
				return vim.bo.ft ~= "" and not vim.b.bigfile
			end

			opts.performance = {
				async_budget = 64,
				max_view_entries = 64,
			}

			opts.sources = {
				{ name = "luasnip", max_item_count = 3, priority = 700 },
				{ name = "fuzzy_path", priority = 1000, option = { fd_cmd = fd_cmd } },
				{
					name = "nvim_lsp",
					max_item_count = 20,
					priority = 900,
				},
				{
					name = "rg",
					keyword_length = 4,
					max_item_count = 6,
					priority = 500,
					option = {
						additional_arguments = [[--hidden --follow --max-filesize 2M -g '!.git' --max-depth 4]],
						cwd = utils.root(),
					},
					entry_filter = function(entry)
						return not entry.exact
					end,
				},
			}

			opts.mapping = {
				["<S-Tab>"] = {
					["c"] = function()
						if utils.tabout.get_jump_pos(-1) then
							utils.tabout.jump(-1)
							return
						end

						if cmp.visible() then
							cmp.select_prev_item()
						else
							cmp.complete()
						end
					end,
					["i"] = function(fallback)
						if luasnip.locally_jumpable(-1) then
							local prev = luasnip.jump_destination(-1)
							local _, snip_dest_end = prev:get_buf_position()
							snip_dest_end[1] = snip_dest_end[1] + 1 -- (1, 0) indexed
							local tabout_dest = utils.tabout.get_jump_pos(-1)
							if not utils.cmp.jump_to_closer(snip_dest_end, tabout_dest, -1) then
								fallback()
							end
						else
							fallback()
						end
					end,
				},
				["<Tab>"] = {
					["c"] = function()
						if utils.tabout.get_jump_pos(1) then
							utils.tabout.jump(1)
							return
						end
						if cmp.visible() then
							cmp.select_next_item()
						else
							cmp.complete()
						end
					end,
					["i"] = function(fallback)
						if luasnip.expandable() then
							luasnip.expand()
						elseif luasnip.locally_jumpable(1) then
							local buf = vim.api.nvim_get_current_buf()
							local cursor = vim.api.nvim_win_get_cursor(0)
							local current = luasnip.session.current_nodes[buf]
							if utils.cmp.node_has_length(current) then
								if
									current.next_choice
									or utils.cmp.cursor_at_end_of_range({ current:get_buf_position() }, cursor)
								then
									luasnip.jump(1)
								else
									fallback()
								end
							else -- node has zero length
								local parent = utils.cmp.node_find_parent(current)
								local range = parent and { parent:get_buf_position() }
								local tabout_dest = utils.tabout.get_jump_pos(1)
								if tabout_dest and range and utils.cmp.in_range(range, tabout_dest) then
									utils.tabout.jump(1)
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
					["c"] = cmp.mapping.select_prev_item(),
					["i"] = function()
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.choice_active() then
							luasnip.change_choice(-1)
						else
							cmp.complete()
						end
					end,
				},
				["<C-n>"] = {
					["c"] = cmp.mapping.select_next_item(),
					["i"] = function()
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.choice_active() then
							luasnip.change_choice(1)
						else
							cmp.complete()
						end
					end,
				},
				["<Down>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "c" }),
				["<Up>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "i", "c" }),
				["<PageDown>"] = cmp.mapping(
					cmp.mapping.select_next_item({
						count = vim.o.pumheight ~= 0 and math.ceil(vim.o.pumheight / 2) or 8,
					}),
					{ "i", "c" }
				),
				["<PageUp>"] = cmp.mapping(
					cmp.mapping.select_prev_item({
						count = vim.o.pumheight ~= 0 and math.ceil(vim.o.pumheight / 2) or 8,
					}),
					{ "i", "c" }
				),
				["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
				["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
				["<C-e>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.abort()
					else
						fallback()
					end
				end, { "i", "c" }),
				["<CR>"] = cmp.mapping(utils.cmp.confirm(), { "i" }),
				["<S-CR>"] = cmp.mapping(utils.cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace }), { "i" }),
				["<C-CR>"] = {
					i = function(fallback)
						cmp.abort()
						fallback()
					end,
				},
				["<BS>"] = function(fallback)
					local ts_indent = require("nvim-treesitter.indent")
					---@diagnostic disable-next-line: deprecated
					local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
					if cursor_row == 1 and cursor_col == 0 then
						return
					end
					cmp.close()
					local current_line = vim.api.nvim_buf_get_lines(0, cursor_row - 1, cursor_row, true)[1]
					local ok, get_indent = pcall(ts_indent.get_indent, cursor_row)
					if not ok then
						get_indent = 0
					end
					if
						vim.fn.strcharpart(current_line, get_indent - 1, cursor_col - get_indent + 1):gsub("%s+", "")
						== ""
					then
						if get_indent > 0 and cursor_col > get_indent then
							local new_line = vim.fn.strcharpart(current_line, 0, get_indent)
								.. vim.fn.strcharpart(current_line, cursor_col)

							vim.api.nvim_buf_set_lines(0, cursor_row - 1, cursor_row, true, { new_line })
							vim.api.nvim_win_set_cursor(
								0,
								{ cursor_row, math.min(get_indent or 0, vim.fn.strcharlen(new_line)) }
							)
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
				end,
			}

			return opts
		end,
		---@param opts cmp.ConfigSchema | {auto_brackets?: string[]}
		config = function(_, opts)
			for _, source in ipairs(opts.sources) do
				source.group_index = source.group_index or 1
			end

			local parse = require("cmp.utils.snippet").parse
			require("cmp.utils.snippet").parse = function(input)
				local ok, ret = pcall(parse, input)
				if ok then
					return ret
				end
				return utils.cmp.snippet_preview(input)
			end

			local cmp = require("cmp")
			-- Use buffer source for `/`.
			cmp.setup.cmdline({ "/", "?" }, {
				enabled = true,
				sources = {
					{
						name = "rg",
						keyword_length = 4,
						max_item_count = 6,
						priority = 500,
						option = {
							additional_arguments = [[--hidden --follow --max-filesize 2M -g '!.git' --max-depth 4]],
							cwd = utils.root(),
						},
						entry_filter = function(entry)
							return not entry.exact
						end,
					},
				},
			})

			-- Use cmdline & path source for ':'.
			cmp.setup.cmdline(":", {
				enabled = true,
				formatting = { fields = { "abbr" } },
				sources = {
					{ name = "fuzzy_path", group_index = 1, priority = 1000, option = { fd_cmd = fd_cmd } },
					{ name = "cmdline", option = { ignore_cmds = {} }, group_index = 2 },
				},
			})

			-- cmp does not work with cmdline with type other than `:`, '/', and '?', e.g.
			-- it does not respect the completion option of `input()`/`vim.ui.input()`, see
			-- https://github.com/hrsh7th/nvim-cmp/issues/1690
			-- https://github.com/hrsh7th/nvim-cmp/discussions/1073
			cmp.setup.cmdline("@", { enabled = false })
			cmp.setup.cmdline(">", { enabled = false })
			cmp.setup.cmdline("-", { enabled = false })
			cmp.setup.cmdline("=", { enabled = false })

			cmp.setup(opts)
			cmp.event:on("confirm_done", function(event)
				if vim.tbl_contains(opts.auto_brackets or {}, vim.bo.filetype) then
					utils.cmp.auto_brackets(event.entry)
				end
			end)
			cmp.event:on("menu_opened", function(event)
				utils.cmp.add_missing_snippet_docs(event.window)
			end)
		end,
	},
}
