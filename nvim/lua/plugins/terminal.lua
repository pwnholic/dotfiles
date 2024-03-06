return {
	{
		"akinsho/toggleterm.nvim",
		cmd = { "ToggleTerm", "ToggleTermToggleAll", "TermExec", "TermSelect", "ToggleTermSetName" },
		keys = {
			{ [[<C-\>]] },
			{
				"<leader>hg",
				function()
					require("toggleterm.terminal").Terminal
						:new({
							cmd = "lazygit",
							hidden = true,
							direction = "float",
							close_on_exit = true,
							dir = require("directory").get_root(),
						})
						:toggle()
				end,
				desc = "LazyGit",
			},
			{
				"<leader>hh",
				function()
					require("toggleterm.terminal").Terminal
						:new({
							cmd = "gh extension exec dash",
							hidden = true,
							direction = "float",
							close_on_exit = true,
							dir = require("directory").get_cwd(),
						})
						:toggle()
				end,
				desc = "Gtihub CLI",
			},
		},
		config = function()
			require("toggleterm.constants").FILETYPE = "terminal"
			require("toggleterm").setup({
				open_mapping = [[<C-\>]],
				autochdir = true,
				highlights = {
					Normal = { link = "Normal" },
					NormalFloat = { link = "NormalFloat" },
					FloatBorder = { link = "Comment" },
				},
				shade_terminals = false,
				start_in_insert = true,
				insert_mappings = true,
				terminal_mappings = true,
				persist_size = false,
				hidden = false,
				close_on_exit = true,
				direction = "horizontal",
				shell = vim.o.shell,
				auto_scroll = true,
				float_opts = { border = "solid", width = vim.o.columns, height = vim.o.lines, winblend = 0 },
				size = function(term)
					if term.direction == "horizontal" then
						return math.floor(vim.o.lines / 2)
					elseif term.direction == "vertical" then
						return math.floor(vim.o.columns * 0.4)
					end
				end,
				on_create = function(term)
					vim.bo[term.bufnr].filetype = "terminal"
					local win
					vim.keymap.set("t", "<C-h>", "<cmd>wincmd h<cr>", { buffer = term.bufnr })
					vim.keymap.set("t", "<C-j>", "<cmd>wincmd j<cr>", { buffer = term.bufnr })
					vim.keymap.set("t", "<C-k>", "<cmd>wincmd k<cr>", { buffer = term.bufnr })
					vim.keymap.set("t", "<C-l>", "<cmd>wincmd l<cr>", { buffer = term.bufnr })

					vim.api.nvim_create_autocmd("BufEnter", {
						buffer = term.bufnr,
						callback = function()
							win = vim.api.nvim_get_current_win()
						end,
					})
					vim.api.nvim_create_autocmd("TermClose", {
						buffer = term.bufnr,
						once = true,
						callback = function()
							local terms = vim.iter(vim.api.nvim_list_bufs())
								:filter(function(buf)
									return vim.bo[buf].buftype == "terminal" and buf ~= term.bufnr
								end)
								:totable()
							local win_bufs = vim.iter(vim.api.nvim_list_wins())
								:map(vim.api.nvim_win_get_buf)
								:fold({}, function(acc, v)
									acc[v] = v
									return acc
								end)
							local target
							for _, t in ipairs(terms) do
								target = target or t
								if win_bufs[t] == nil then
									target = t
									break
								end
							end
							if win and target and vim.api.nvim_buf_is_valid(target) then
								vim.api.nvim_win_set_buf(win, target)
								vim.api.nvim_create_autocmd("WinEnter", {
									once = true,
									callback = vim.schedule_wrap(function()
										if win and vim.api.nvim_win_is_valid(win) then
											vim.api.nvim_set_current_win(win)
											win = nil
										end
									end),
								})
							end
						end,
					})
				end,
			})
		end,
	},
	{
		"willothy/flatten.nvim",
		lazy = false,
		priority = 1001,
		opts = function()
			local saved_terminal
			return {
				window = { open = "alternate" },
				one_per = { kitty = false, wezterm = false },
				callbacks = {
					should_block = function(argv)
						return vim.tbl_contains(argv, "-b")
					end,
					pre_open = function()
						local term = require("toggleterm.terminal")
						saved_terminal = term.get(term.get_focused_id())
					end,
					post_open = function(bufnr, winnr, ft, is_blocking)
						if is_blocking and saved_terminal then
							saved_terminal:close()
						else
							vim.api.nvim_set_current_win(winnr)
						end
						if ft == "gitcommit" or ft == "gitrebase" then
							vim.api.nvim_create_autocmd("BufWritePost", {
								buffer = bufnr,
								once = true,
								callback = vim.schedule_wrap(function()
									vim.api.nvim_buf_delete(bufnr, {})
								end),
							})
						end
					end,
					block_end = function()
						vim.schedule(function()
							if saved_terminal then
								saved_terminal:open()
								saved_terminal = nil
							end
						end)
					end,
				},
				pipe_path = function()
					if vim.env.NVIM then
						return vim.env.NVIM
					end
					if vim.env.KITTY_PID then
						local addr = ("%s/%s"):format(vim.fn.stdpath("run"), "kitty.nvim-" .. vim.env.KITTY_PID)
						if not vim.uv.fs_stat(addr) then
							vim.fn.serverstart(addr)
						end
						return addr
					end
				end,
			}
		end,
	},
}
