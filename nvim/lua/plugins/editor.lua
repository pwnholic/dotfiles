return {
	{ "Bekaboo/deadcolumn.nvim", event = "BufRead", config = true },
	{ "numToStr/Comment.nvim", event = "BufRead", keys = { "gcc", "gcb", "gc", "gc$" }, config = true },
	{ "tpope/vim-dadbod", dependencies = { "kristijanhusak/vim-dadbod-ui" }, cmd = "DBUI" },
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
					prompt = "Remove Sessions : ",
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
