local M = {}

function M.keys()
	local term_exec = function(cmd, direction)
		return function()
			require("toggleterm.terminal").Terminal
				:new({ cmd = cmd, dir = require("utils.root").get_cwd(), direction = direction })
				:toggle()
		end
	end
	return {
		{ [[<C-\>]] },
		{ "<leader>hg", term_exec("lazygit", "float"), desc = "LazyGit" },
		{ "<leader>hh", term_exec("gh extension exec dash", "float"), desc = "Gtihub CLI" },
	}
end

function M.setup()
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
		on_create = function(opts)
			vim.o.signcolumn = "no"
			local map = vim.keymap.set

            -- stylua: ignore start
			map({ "n", "t" }, "<C-h>", "<cmd>wincmd h<cr>", { buffer = opts.bufnr })
			map({ "n", "t" }, "<C-j>", "<cmd>wincmd j<cr>", { buffer = opts.bufnr })
			map({ "n", "t" }, "<C-k>", "<cmd>wincmd k<cr>", { buffer = opts.bufnr })
			map({ "n", "t" }, "<C-l>", "<cmd>wincmd l<cr>", { buffer = opts.bufnr })
			map({ "n", "t" }, "<C-Up>", "<cmd>resize +2<cr>", { silent = true, buffer = opts.bufnr })
			map({ "n", "t" }, "<C-Down>", "<cmd>resize -2<cr>", { silent = true, buffer = opts.bufnr })
			map({ "n", "t" }, "<C-Left>", "<cmd>vertical resize +2<cr>", { silent = true, buffer = opts.bufnr })
			map({ "n", "t" }, "<C-Right>", "<cmd>vertical resize -2<cr>", { silent = true, buffer = opts.bufnr })
			map("t", "<esc><esc>", function() vim.notify("Back to Normal Mode", 2) vim.cmd.stopinsert() end, { buffer = opts.bufnr })
			-- stylua: ignore end
		end,
	})
end

return M
