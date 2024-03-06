return {
	{ "Bekaboo/deadcolumn.nvim", event = "BufRead", config = true },
	{ "numToStr/Comment.nvim", event = "BufRead", keys = { "gcc", "gcb", "gc", "gc$" }, config = true },
	{ "tpope/vim-dadbod", dependencies = { "kristijanhusak/vim-dadbod-ui" }, cmd = "DBUI" },
	{
		"chrisgrieser/nvim-early-retirement",
		event = "BufRead",
		opts = { retirementAgeMins = 5, notificationOnAutoClose = true },
	},
	{
		"folke/trouble.nvim",
		cmd = { "TroubleToggle", "Trouble" },
		opts = {
			use_diagnostic_signs = true,
			auto_jump = { "lsp_references", "lsp_implementations", "lsp_type_definitions", "lsp_definitions" },
			track_cursor = true,
			padding = false,
			win_config = { border = vim.g.border },
		},
		keys = {
            -- stylua: ignore start
			{ "<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics (Trouble)" },
			{ "<leader>xL", "<cmd>TroubleToggle loclist<cr>", desc = "Location List (Trouble)" },
			{ "<leader>xQ", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List (Trouble)" },
			{
				"[q",
				function()
					if require("trouble").is_open() then require("trouble").previous({ skip_groups = true, jump = true })
					else local ok, err = pcall(vim.cmd.cprev)
						if not ok then vim.notify(err, vim.log.levels.ERROR) end
					end
				end,
				desc = "Previous trouble/quickfix item",
			},
			{
				"]q",
				function()
					if require("trouble").is_open() then require("trouble").next({ skip_groups = true, jump = true })
					else
						local ok, err = pcall(vim.cmd.cnext)
						if not ok then vim.notify(err, vim.log.levels.ERROR) end
					end
				end,
				desc = "Next trouble/quickfix item",
			},
			-- stylua: ignore end
		},
	},

	{
		"echasnovski/mini.surround",
		keys = function(_, keys)
			local plugin = require("lazy.core.config").spec.plugins["mini.surround"]
			local opts = require("lazy.core.plugin").values(plugin, "opts", false)
			local mappings = {
				{ opts.mappings.add, desc = "Add surrounding", mode = { "n", "v" } },
				{ opts.mappings.delete, desc = "Delete surrounding" },
				{ opts.mappings.find, desc = "Find right surrounding" },
				{ opts.mappings.find_left, desc = "Find left surrounding" },
				{ opts.mappings.highlight, desc = "Highlight surrounding" },
				{ opts.mappings.replace, desc = "Replace surrounding" },
				{ opts.mappings.update_n_lines, desc = "Update 'MiniSurround.config.n_lines'" },
			}
			mappings = vim.tbl_filter(function(m)
				return m[1] and #m[1] > 0
			end, mappings)
			return vim.list_extend(mappings, keys)
		end,
		opts = {
			mappings = {
				add = "gsa",
				delete = "gsd",
				find = "gsf",
				find_left = "gsF",
				highlight = "gsh",
				replace = "gsr",
				update_n_lines = "gsn",
			},
		},
	},
	{
		"ThePrimeagen/harpoon",
		dependencies = { "nvim-lua/plenary.nvim" },
		branch = "harpoon2",
		config = function()
			local harpoon = require("harpoon")
			require("harpoon.config").DEFAULT_LIST = "files"
			local Extensions = require("harpoon.extensions")
			harpoon:setup({
				settings = {
					save_on_toggle = true,
					sync_on_ui_close = true,
					key = function()
						return vim.loop.cwd()
					end,
				},
				default = {
					display = function(list_item)
						return vim.fn.pathshorten(vim.fn.fnamemodify(list_item.value, ":~:."), 3)
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

                    -- stylua: ignore start
					map("n", "<C-v>", function() harpoon.ui:select_menu_item({ vsplit = true }) end, { buffer = bufnr })
					map("n", "<C-h>", function() harpoon.ui:select_menu_item({ split = true }) end, { buffer = bufnr })
					map("n", "<C-t>", function() harpoon.ui:select_menu_item({ tabedit = true }) end, { buffer = bufnr })
					-- stylua: ignore end
				end,
			})
		end,
		keys = function()
			local harpoon = require("harpoon")
			return {
                -- stylua: ignore start
				{ "<A-space>", function() harpoon.ui:toggle_quick_menu(harpoon:list("files"), { title = "", ui_max_width = 80 }) end, desc = "Harpoon Files", mode = { "i", "n", "v" }, },
				{ "<leader>tt", function() harpoon.ui:toggle_quick_menu(harpoon:list("terminals"), { title = "",ui_max_width = 80 }) end, desc = "Harpoon Term List", },
				{ "<A-a>", function() harpoon:list():append() end, desc = "Add to Mark", },
				{ "<A-1>", function() harpoon:list():select(1) end, desc = "Mark File 1", },
				{ "<A-2>", function() harpoon:list():select(2) end, desc = "Mark File 2", },
				{ "<A-3>", function() harpoon:list():select(3) end, desc = "Mark File 3", },
				{ "<A-4>", function() harpoon:list():select(4) end, desc = "Mark File 4", },
				{ "<A-5>", function() harpoon:list():select(5) end, desc = "Mark File 6", },
				{ "<A-6>", function() harpoon:list():select(6) end, desc = "Mark File 6", },
				{ "<A-7>", function() harpoon:list():select(7) end, desc = "Mark File 7", },
				{ "<A-8>", function() harpoon:list():select(8) end, desc = "Mark File 8", },
				{ "<A-9>", function() harpoon:list():select(9) end, desc = "Mark File 9", },
				-- stylua: ignore end
			}
		end,
	},
	{
		"altermo/ultimate-autopair.nvim",
		event = { "InsertEnter" },
		branch = "v0.6",
		config = function()
			local compltype = {}
			vim.api.nvim_create_autocmd("CmdlineChanged", {
				desc = "Record cmd compltype to determine whether to autopair.",
				group = vim.api.nvim_create_augroup("AutopairRecordCmdCompltype", {}),
				callback = function()
					local type = vim.fn.getcmdcompltype()
					if compltype[1] == type then
						return
					end
					compltype[2] = compltype[1]
					compltype[1] = type
				end,
			})

			local function get_next_two_chars()
				local col, line
				if vim.fn.mode():match("^c") then
					col = vim.fn.getcmdpos()
					line = vim.fn.getcmdline()
				else
					col = vim.fn.col(".")
					line = vim.api.nvim_get_current_line()
				end
				return line:sub(col, col + 1)
			end

			local IGNORE_REGEX = vim.regex([=[^\%(\k\|\\\?[([{]\)]=])
			require("ultimate-autopair").setup({
				extensions = {
					alpha = false,
					tsnode = false,
					utf8 = false,
					filetype = { tree = false },
					cond = {
						cond = function(f)
							return not f.in_macro()
								and not IGNORE_REGEX:match_str(get_next_two_chars())
								and (not f.in_cmdline() or compltype[1] ~= "" or compltype[2] ~= "command")
						end,
					},
				},
				{ "\\(", "\\)" },
				{ "\\[", "\\]" },
				{ "\\{", "\\}" },
				{ "/*", "*/", ft = { "c", "cpp", "go" }, newline = true, space = true },
				{ "<", ">", disable_start = true, disable_end = true },
				{ "$", "$", ft = { "markdown", "tex" }, disable_start = true, disable_end = true },
				{ "*", "*", ft = { "markdown" }, disable_start = true, disable_end = true },
			})
		end,
	},
	{
		"echasnovski/mini.bufremove",
		keys = {
			{
				"<leader>bd",
				function()
					local bd = require("mini.bufremove").delete
					if vim.bo.modified then
						local choice =
							vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
						if choice == 1 then
							vim.cmd.write()
							bd(0)
						elseif choice == 2 then
							bd(0, true)
						end
					else
						bd(0)
					end
				end,
				desc = "Delete Buffer",
			},
			{
				"<leader>bD",
				function()
					require("mini.bufremove").delete(0, true)
				end,
				desc = "Delete Buffer (Force)",
			},
		},
	},
	{
		"stevearc/resession.nvim",
		event = "VeryLazy",
		keys = { "<leader>rs", "<leader>rt", "<leader>ro", "<leader>rl", "<leader>rd", "ZZ" },
		config = function()
			local rs = require("resession")
			local visible_buffers = {}
			rs.setup({
				autosave = { enabled = true, notify = false },
				tab_buf_filter = function(tabpage, bufnr)
					local dir = vim.fn.getcwd(-1, vim.api.nvim_tabpage_get_number(tabpage))
					return vim.startswith(vim.api.nvim_buf_get_name(bufnr), dir)
				end,
				buf_filter = function(bufnr)
					if not rs.default_buf_filter(bufnr) then
						return false
					end
					return visible_buffers[bufnr]
				end,
				extensions = { quickfix = {} },
			})

			rs.add_hook("pre_save", function()
				visible_buffers = {}
				for _, winid in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_is_valid(winid) then
						visible_buffers[vim.api.nvim_win_get_buf(winid)] = winid
					end
				end
			end)

			vim.keymap.set("n", "<leader>rd", function()
				require("fzf-lua.core").fzf_exec(rs.list(), {
					actions = {
						["default"] = function(select)
							vim.notify(
								string.format("%d session has been deleted", #select),
								2,
								{ title = "Resession" }
							)
							for idx = 1, #select do
								rs.delete(select[idx])
							end
						end,
					},
				})
			end, { desc = "Resession Delete" })
			vim.keymap.set("n", "<leader>rl", function()
				rs.load(nil, { reset = false })
			end, { desc = "Resession Load without reset" })
			vim.keymap.set("n", "ZZ", function()
				vim.cmd.wall()
				rs.save("__quicksave__", { notify = false })
				vim.api.nvim_create_augroup("MySessions", {})
				vim.cmd.qall()
			end)
			vim.keymap.set("n", "<leader>rs", rs.save, { desc = "Resession Save" })
			vim.keymap.set("n", "<leader>rt", rs.save_tab, { desc = "Resession save Sab" })
			vim.keymap.set("n", "<leader>ro", rs.load, { desc = "Resession Open" })

			if vim.tbl_contains(rs.list(), "__quicksave__") then
				vim.defer_fn(function()
					rs.load("__quicksave__", { attach = false })
					local ok, err = pcall(rs.delete, "__quicksave__")
					if not ok then
						vim.notify(string.format("Error deleting quicksave session: %s", err), vim.log.levels.WARN)
					end
				end, 50)
			end

			vim.api.nvim_create_autocmd("VimLeavePre", {
				group = vim.api.nvim_create_augroup("MySessions", {}),
				callback = function()
					rs.save(string.format("%s_%s", os.date("%d%m%Y"), os.date("%H%M%S")))
				end,
			})
		end,
	},
}
