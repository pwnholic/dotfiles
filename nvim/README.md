return {
	{
		"<S-Tab",
		function()
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
		mode = "c",
	},
	{ "<S-Tab>" },
	["<S-Tab>"] = {
		["c"] = function() end,
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
	["<C-y>"] = cmp.mapping(utils.cmp.confirm({ select = true }), { "i" }),
	["<S-CR>"] = cmp.mapping(utils.cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace }), { "i" }),
	["<C-CR>"] = function(fallback)
		cmp.abort()
		fallback()
	end,
	["<BS>"] = cmp.mapping(utils.cmp.backspace_autoindent, { "i" }),
}
