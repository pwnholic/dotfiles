return {
	"yioneko/nvim-cmp",
	branch = "perf",
	event = "InsertEnter",
	dependencies = {
		{ "hrsh7th/cmp-nvim-lsp" },
		{ "hrsh7th/cmp-cmdline" },
		{ "tzachar/cmp-fuzzy-path", dependencies = "tzachar/fuzzy.nvim" },
		{ "lukas-reineke/cmp-rg" },
		{ "saadparwaiz1/cmp_luasnip" },
		{ "stevearc/vim-vscode-snippets" },
	},
	keys = function()
		return {
			{ "<S-Tab>", mode = { "c", "i" } },
			{ "<Tab>", mode = { "c", "i" } },
			{ "<C-p>", mode = { "c", "i" } },
			{ "<C-n>", mode = { "c", "i" } },
			{ "<Down>", mode = { "c", "i" } },
			{ "<Up>", mode = { "c", "i" } },
			{ "<PageDown>", mode = { "c", "i" } },
			{ "<C-u>", mode = { "c", "i" } },
			{ "<C-d>", mode = { "c", "i" } },
			{ "<C-e>", mode = { "c", "i" } },
			{ "<CR>", mode = "i" },
			{ "<C-y>", mode = "i" },
		}
	end,
	opts = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")
		local utils = require("utils")
		return {
			auto_brackets = {},
			performance = { async_budget = 1, max_view_entries = 64, debounce = 1, throttle = 1 },
			completion = { completeopt = "menu,menuone,noinsert" },
			preselect = true,
			mapping = {
				["<S-Tab>"] = {
					["c"] = function()
						if utils.cmp.get_jump_pos(-1) then
							utils.cmp.jump(-1)
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
							local tabout_dest = utils.cmp.get_jump_pos(-1)
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
						if utils.cmp.get_jump_pos(1) then
							utils.cmp.jump(1)
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
								local tabout_dest = utils.cmp.get_jump_pos(1)
								if tabout_dest and range and utils.cmp.in_range(range, tabout_dest) then
									utils.cmp.jump(1)
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
				["<CR>"] = cmp.mapping(utils.cmp.confirm({ select = true }), { "i" }),
				["<C-y>"] = cmp.mapping(utils.cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace }), { "i" }),
			},
			sources = cmp.config.sources({
				{ name = "fuzzy_path", option = utils.cmp.fd_cmd },
				{ name = "nvim_lsp" },
				{ name = "luasnip", max_item_count = 3 },
			}, {
				{ name = "rg" },
			}),
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			formatting = {
				expandable_indicator = true,
				fields = { "kind", "abbr", "menu" },
				format = function(entry, items)
					local sname = entry.source.name
					if items.kind == "Folder" then
						items.menu = items.kind
						items.menu_hl_group = "Directory"
						items.kind = utils.icons.kinds.Folder
						items.kind_hl_group = "Directory"
					elseif items.kind == "File" then
						local icon, hl_group = require("mini.icons").get("file", vim.fs.basename(items.word))
						items.menu = items.kind
						items.menu_hl_group = hl_group or "CmpItemKindFile"
						items.kind = icon or utils.icons.kinds.File
						items.kind_hl_group = hl_group or "CmpItemKindFile"
					else
						items.dup = ({ buffer = 1, nvim_lsp = 0, luasnip = 1, path = 1 })[sname] or 0
						items.menu = items.kind
						items.menu_hl_group = string.format("CmpItemKind%s", items.kind)
						items.kind = vim.fn.strcharpart(utils.icons.kinds[items.kind] or "", 0, 2)
					end
					utils.cmp.clamp_cmp_item(
						"abbr",
						vim.go.pw,
						math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.24)),
						items
					)
					utils.cmp.clamp_cmp_item(
						"menu",
						0,
						math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.10)),
						items
					)
					return items
				end,
			},
			experimental = { ghost_text = { hl_group = "CmpGhostText" } },
			sorting = {
				priority_weight = 2,
				comparators = {
					require("cmp_fuzzy_path.compare") or function() end,
					cmp.config.compare.offset,
					cmp.config.compare.exact,
					cmp.config.compare.score,
					cmp.config.compare.recently_used,
					cmp.config.compare.locality,
					cmp.config.compare.kind,
					cmp.config.compare.lenght,
				},
			},
		}
	end,
	config = function(_, opts)
		local utils = require("utils")
		for _, source in ipairs(opts.sources) do
			source.group_index = source.group_index or 1
		end

		local cmp = require("cmp")
		local parse = require("cmp.utils.snippet").parse
		require("cmp.utils.snippet").parse = function(input)
			local ok, ret = pcall(parse, input)
			if ok then
				return ret
			end
			return utils.cmp.snippet_preview(input)
		end

		cmp.setup.cmdline({ "/", "?" }, {
			enabled = true,
			window = { documentation = false },
			formatting = { fields = { "abbr" } },
			sources = { { name = "rg" } },
		})

		-- Use cmdline & path source for ':'.
		cmp.setup.cmdline(":", {
			enabled = true,
			---@diagnostic disable-next-line: missing-fields
			formatting = { fields = { "abbr" } },
			sources = {
				{ name = "fuzzy_path", option = utils.cmp.fd_cmd, group_index = 2 },
				{ name = "cmdline", option = { ignore_cmds = {} }, group_index = 1 },
			},
		})

		cmp.setup.cmdline("@", { enabled = false })
		cmp.setup.cmdline(">", { enabled = false })
		cmp.setup.cmdline("-", { enabled = false })
		cmp.setup.cmdline("=", { enabled = false })

		cmp.setup.filetype({ "sql", "mysql" }, { sources = { { name = "nvim_lsp" } } })

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
}
