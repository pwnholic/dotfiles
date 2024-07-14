return {
	{
		"hrsh7th/nvim-cmp",
		version = false,
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-path",
		},
		opts = function()
			vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local utils = require("utils")
			local auto_select = true

			cmp.setup.cmdline({ "/", "?" }, {
				enabled = true,
				---@diagnostic disable-next-line: missing-fields
				formatting = { fields = { "abbr" } },
				sources = { { name = "buffer" } },
			})

			-- Use cmdline & path source for ':'.
			cmp.setup.cmdline(":", {
				enabled = true,
				---@diagnostic disable-next-line: missing-fields
				formatting = { fields = { "abbr" } },
				sources = {
					{ name = "path", group_index = 1 },
					{ name = "cmdline", option = { ignore_cmds = {} }, group_index = 2 },
				},
			})

			cmp.setup.cmdline("@", { enabled = false })
			cmp.setup.cmdline(">", { enabled = false })
			cmp.setup.cmdline("-", { enabled = false })
			cmp.setup.cmdline("=", { enabled = false })

			cmp.setup.filetype({ "sql", "mysql" }, {
				sources = { { name = "nvim_lsp" } },
			})

			return {
				auto_brackets = {}, -- configure any filetype to auto add brackets
				completion = {
					completeopt = "menu,menuone,noinsert" .. (auto_select and "" or ",noselect"),
				},
				preselect = auto_select and cmp.PreselectMode.Item or cmp.PreselectMode.None,
				sources = cmp.config.sources({
					{ name = "nvim_lsp", priority = 800 },
					{ name = "luasnip", priority = 600 },
					{ name = "path", priority = 1000 },
				}, {
					{
						name = "buffer",
						option = {
							get_bufnrs = function()
								local bufs = {}
								for _, win in ipairs(vim.api.nvim_list_wins()) do
									bufs[vim.api.nvim_win_get_buf(win)] = true
								end
								return vim.tbl_keys(bufs)
							end,
						},
						priority = 100,
					},
				}),
				formatting = {
					fields = { "kind", "abbr", "menu" },
					format = function(entry, items)
						local sname = entry.source.name
						if items.kind == "Folder" then
							items.menu = items.kind
							items.menu_hl_group = "Directory"
							items.kind = LazyVim.config.icons.kinds.Folder
							items.kind_hl_group = "Directory"
						elseif items.kind == "File" then
							local icon, hl_group = require("mini.icons").get("file", vim.fs.basename(items.word))
							items.menu = items.kind
							items.menu_hl_group = hl_group or "CmpItemKindFile"
							items.kind = icon or LazyVim.config.icons.kinds.File
							items.kind_hl_group = hl_group or "CmpItemKindFile"
						else
							items.dup = ({ buffer = 1, nvim_lsp = 0, luasnip = 1, path = 1 })[sname] or 0
							items.menu = items.kind
							items.menu_hl_group = "CmpItemKind" .. items.kind
							items.kind = vim.fn.strcharpart(LazyVim.config.icons.kinds[items.kind] or "", 0, 2)
						end
                        -- stylua: ignore start
                        utils.cmp.clamp_format_items( "abbr", vim.go.pw, math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.24)), items)
                        utils.cmp.clamp_format_items( "menu", 0, math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.10)), items)
						-- stylua: ignore end
						return items
					end,
				},
				experimental = {
					ghost_text = {
						hl_group = "CmpGhostText",
					},
				},
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				sorting = {

					priority_weight = 100,
					comparators = {
						cmp.config.compare.exact,
						cmp.config.compare.offset,
						function(lhs, rhs)
							-- Gua gak yakin ini pattern yang bagus in "GENERAL" but is work well on rust
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
				},
				mapping = {
					-- ["<BS>"] = utils.cmp.backspace_autoindent,
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
					["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i" }),
					["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i" }),
					["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i" }),
					["<CR>"] = cmp.mapping(LazyVim.cmp.confirm({ select = auto_select }), { "i" }),
					["<C-y>"] = cmp.mapping(LazyVim.cmp.confirm({ select = true }), { "i" }),
					["<S-CR>"] = cmp.mapping(LazyVim.cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace }), { "i" }),
				},
			}
		end,
	},
	{
		"L3MON4D3/LuaSnip",
		build = (not LazyVim.is_win())
				and "echo 'NOTE: jsregexp is optional, so not a big deal if it fails to build'; make install_jsregexp"
			or nil,
		dependencies = {
			"rafamadriz/friendly-snippets",
			config = function()
				local paths = vim.fn.stdpath("config") .. "/snippets" --[[@as string]]
				require("luasnip.loaders.from_vscode").lazy_load({ paths = paths })
			end,
		},
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
			return {
				history = true,
				delete_check_events = "TextChanged",
				keep_roots = true,
				link_roots = false,
				link_children = true,
				region_check_events = "CursorMoved,CursorMovedI",
				enable_autosnippets = true,
				store_selection_keys = "<Tab>",
				ext_opts = {
					[ls_types.choiceNode] = {
						active = {
							virt_text = { { LazyVim.config.icons.kinds, "Number" } },
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
		"kristijanhusak/vim-dadbod-ui",
		dependencies = { "tpope/vim-dadbod", lazy = true },
		cmd = "DBUI",
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
		end,
	},
}
