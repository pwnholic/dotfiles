local M = { "ThePrimeagen/harpoon", dependencies = { "nvim-lua/plenary.nvim" }, branch = "harpoon2" }

M.config = function()
	local harpoon = require("harpoon")
	require("harpoon.config").DEFAULT_LIST = "files"
	local Extensions = require("harpoon.extensions")
	harpoon:setup({
		settings = {
			save_on_toggle = true,
			sync_on_ui_close = true,
			key = function()
				return vim.uv.cwd()
			end,
		},
		default = {
			display = function(list_item)
				if string.len(list_item.value) > 75 then
					return vim.fn.pathshorten(vim.fn.fnamemodify(list_item.value, ":~:."), 3)
				else
					return vim.fn.fnamemodify(list_item.value, ":~:.")
				end
			end,
		},
		terminals = {
			automated = true,
			encode = false,
			select_with_nil = true,
			prepopulate = function()
				local bufs = vim.api.nvim_list_bufs()
				return vim.iter(bufs)
					:filter(function(buf)
						return vim.bo[buf].buftype == "terminal"
					end)
					:map(function(buf)
						local term = require("toggleterm.terminal").find(function(t)
							return t.bufnr == buf
						end)
						local bufname = vim.api.nvim_buf_get_name(buf)
						if term then
							if term.display_name and (#bufname == 0 or #bufname > #term.display_name) then
								bufname = term.display_name
							else
								bufname = string.format("%s [%d]", term:_display_name(), term.id)
							end
						end
						return { value = bufname, context = { bufnr = buf } }
					end)
					:totable()
			end,
			remove = function(items)
				local bufnr = items.context.bufnr
				vim.schedule(function()
					if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
						require("mini.bufremove").delete(bufnr, true)
					end
				end)
			end,
			select = function(items, list)
				if items.context.bufnr == nil or not vim.api.nvim_buf_is_valid(items.context.bufnr) then
					-- create a new terminal if the buffer is invalid
					local term = require("toggleterm.terminal").Terminal:new({ display_name = items.value })
					term:open()
					items.context.bufnr = term.bufnr
				else
					-- jump to existing window containing the buffer
					for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
						local buf = vim.api.nvim_win_get_buf(win)
						if buf == items.context.bufnr then
							vim.api.nvim_set_current_win(win)
							return
						end
					end
				end
				-- switch to the buffer if no window was found
				vim.api.nvim_set_current_buf(items.context.bufnr)
				Extensions.extensions:emit(
					Extensions.event_names.NAVIGATE,
					{ list = list, item = items, buffer = items.context.bufnr }
				)
			end,
		},
	})

	local function notify(event, ctx)
		if not ctx then
			return
		end
		if ctx.list and ctx.list.config.automated then
			return
		end
		local path = require("plenary.path"):new(ctx.item.value)
		local display = path:make_relative(vim.uv.cwd()) or path:make_relative(vim.env.HOME) or path:normalize()
		local titles = { ADD = " Added", REMOVE = " Removed" }
		if event == "ADD" then
			vim.notify(display, vim.log.levels.HINT, { title = titles[event] })
		elseif event == "REMOVE" then
			vim.notify(display, vim.log.levels.WARN, { title = titles[event] })
		else
			vim.notify(display, vim.log.levels.INFO, { title = titles[event] })
		end
	end
	local function handler(evt)
		return function(...)
			notify(evt, ...)
		end
	end

	local function add_items(list, items)
		for _, item in ipairs(items) do
			local exists = false
			for _, list_item in ipairs(list.items) do
				if list.config.equals(item, list_item) then
					exists = true
					break
				end
			end
			if not exists then
				list:append(item)
			end
		end
	end

	local function add_new_entries(list)
		if not list.config.prepopulate then
			return
		end
		local sync_items = list.config.prepopulate(function(items)
			if type(items) ~= "table" then
				return
			end
			add_items(list, items)
			-- if ui is open, buffer needs to be updated
			-- so that items aren't removed immediately after being added
			vim.schedule(function()
				local ui_buf = harpoon.ui.bufnr
				if ui_buf and vim.api.nvim_buf_is_valid(ui_buf) then
					local lines = list:display()
					vim.api.nvim_buf_set_lines(ui_buf, 0, -1, false, lines)
				end
			end)
		end)
		if sync_items and type(sync_items) == "table" then
			add_items(list, sync_items)
		end
	end

	local function prepopulate(list)
		if list.config.prepopulate and list:length() == 0 then
			local sync_items = list.config.prepopulate(function(items)
				if type(items) ~= "table" then
					return
				end
				for _, item in ipairs(items) do
					list:append(item)
				end
				vim.schedule(function()
					local ui_buf = harpoon.ui.bufnr
					if ui_buf and vim.api.nvim_buf_is_valid(ui_buf) then
						vim.api.nvim_buf_set_lines(ui_buf, 0, -1, false, list:display())
					end
				end)
			end)
			if sync_items and type(sync_items) == "table" then
				for _, item in ipairs(sync_items) do
					list:append(item)
				end
			end
		end
	end

	harpoon:extend({
		ADD = handler("ADD"),
		REMOVE = function(ctx)
			notify("REMOVE", ctx)
			if ctx.list.config.remove then
				ctx.list.config.remove(ctx.item, ctx.list)
			end
		end,
		LIST_READ = function(list)
			if list.config.automated then
				add_new_entries(list)
			end
		end,
		LIST_CREATED = prepopulate,
		UI_CREATE = function(ctx)
			local winnr, bufnr, map = ctx.win_id, ctx.bufnr, vim.keymap.set
			vim.wo[winnr].cursorline = true
			vim.wo[winnr].signcolumn = "no"
			vim.o.wrap = true
			map("n", "<C-v>", function()
				harpoon.ui:select_menu_item({ vsplit = true })
			end, { buffer = bufnr })
			map("n", "<C-h>", function()
				harpoon.ui:select_menu_item({ split = true })
			end, { buffer = bufnr })
			map("n", "<C-t>", function()
				harpoon.ui:select_menu_item({ tabedit = true })
			end, { buffer = bufnr })
		end,
	})
end

M.keys = function()
	-- stylua: ignore start
	local harpoon = require("harpoon")
	local function toggle(list) return function() harpoon.ui:toggle_quick_menu(harpoon:list(list), { title = "", ui_max_width = 80 }) end end
	local function select(idx) return function() harpoon:list():select(idx) end end

	return {
		{ "<A-a>", function() harpoon:list():append() end, desc = "Add to Mark", },
		{ "<Tab>", function() harpoon:list():next() end, desc = "Next Harpoon", },
		{ "<S-Tab>", function() harpoon:list():prev() end, desc = "Prev Harpoon", },
		{ "<leader>1", select(1), desc = "Mark File 1" },
		{ "<leader>2", select(2), desc = "Mark File 2" },
		{ "<leader>3", select(3), desc = "Mark File 3" },
		{ "<leader>4", select(4), desc = "Mark File 4" },
		{ "<leader>5", select(5), desc = "Mark File 6" },
		{ "<leader>6", select(6), desc = "Mark File 6" },
		{ "<leader>7", select(7), desc = "Mark File 7" },
		{ "<leader>8", select(8), desc = "Mark File 8" },
		{ "<leader>9", select(9), desc = "Mark File 9" },
		{ "<A-space>", toggle("files"), desc = "Harpoon Files", mode = { "i", "n", "v" } },
		{ [[<A-\>]], toggle("terminals"), desc = "Harpoon Term List" },
	-- stylua: ignore end
	}
end
return M
