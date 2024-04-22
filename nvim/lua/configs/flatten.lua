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
