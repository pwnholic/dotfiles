return {
	{
		"akinsho/toggleterm.nvim",
		cmd = { "ToggleTerm", "ToggleTermToggleAll", "TermExec", "TermSelect", "ToggleTermSetName" },
		keys = function()
			local term_exec = function(cmd, direction)
				return function()
					require("toggleterm.terminal").Terminal
						:new({ cmd = cmd, dir = require("directory").get_cwd(), direction = direction })
						:toggle()
				end
			end
			return {
				{ [[<C-\>]] },
				{ "<leader>hg", term_exec("lazygit", "float"), desc = "LazyGit" },
				{ "<leader>hh", term_exec("gh extension exec dash", "float"), desc = "Gtihub CLI" },
			}
		end,
		opts = {
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
				vim.keymap.set("t", "<C-h>", "<cmd>wincmd h<cr>", { buffer = term.bufnr })
				vim.keymap.set("t", "<C-j>", "<cmd>wincmd j<cr>", { buffer = term.bufnr })
				vim.keymap.set("t", "<C-k>", "<cmd>wincmd k<cr>", { buffer = term.bufnr })
				vim.keymap.set("t", "<C-l>", "<cmd>wincmd l<cr>", { buffer = term.bufnr })
				vim.keymap.set("t", "<esc><esc>", function()
					vim.notify("Back to Normal Mode", 2)
					vim.cmd.stopinsert()
				end, { buffer = term.bufnr })
			end,
		},
	},
	{
		"willothy/flatten.nvim",
		lazy = false,
		priority = 1001,
		config = function()
			local saved_terminal
			require("flatten").setup({
				window = { open = "alternate" },
				block_for = { gitcommit = true, gitrebase = true },
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
			})
		end,
	},
}
