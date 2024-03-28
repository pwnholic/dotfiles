return {
	setup = function()
		local keymap, utils = vim.keymap.set, require("utils")

		-- better scroll
		keymap("n", "<C-d>", "<C-d>zz")
		keymap("n", "<C-u>", "<C-u>zz")

		-- better up/down
		keymap({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
		keymap({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
		keymap({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
		keymap({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

		-- Move to window using the <ctrl> hjkl keys
		keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window", remap = true })
		keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window", remap = true })
		keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window", remap = true })
		keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window", remap = true })

		-- Resize window using <ctrl> arrow keys
		keymap("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height", silent = true })
		keymap("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height", silent = true })
		keymap("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width", silent = true })
		keymap("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width", silent = true })

		-- Move Lines
		keymap("n", "<A-u>", "<cmd>m .-2<cr>==", { desc = "Move up", silent = true })
		keymap("i", "<A-u>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up", silent = true })
		keymap("v", "<A-u>", ":m '<-2<cr>gv=gv", { desc = "Move up", silent = true })
		keymap("i", "<A-d>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down", silent = true })
		keymap("v", "<A-d>", ":m '>+1<cr>gv=gv", { desc = "Move down", silent = true })
		keymap("n", "<A-d>", "<cmd>m .+1<cr>==", { desc = "Move down", silent = true })

		-- buffers
		keymap("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
		keymap("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

		-- Clear search with <esc>
		keymap({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

		-- Clear search, diff update and redraw
		-- taken from runtime/lua/_editor.lua
		keymap(
			"n",
			"<leader>ur",
			"<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
			{ desc = "Redraw / clear hlsearch / diff update" }
		)

		-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
		keymap("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next search result" })
		keymap("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev search result" })
		keymap({ "x", "o" }, "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
		keymap({ "x", "o" }, "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })

		-- Add undo break-points
		keymap("i", ",", ",<c-g>u")
		keymap("i", ".", ".<c-g>u")
		keymap("i", ";", ";<c-g>u")

		-- save file
		keymap({ "i", "v", "n" }, "<C-s>", function()
			if vim.bo.filetype == "oil" and vim.bo.modified then
				return require("oil").save()
			end
			return "<esc>:wall<cr>"
		end, { desc = "Save file", silent = true, expr = true })

		-- better indenting
		keymap("v", "<", "<gv")
		keymap("v", ">", ">gv")

		keymap("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
		keymap("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })

		keymap("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" })
		keymap("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })

		-- highlights under cursor
		keymap("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })

		keymap("n", "<leader>ww", "<C-W>p", { desc = "Other window", remap = true })
		keymap("n", "<leader>wd", "<C-W>c", { desc = "Delete window", remap = true })
		keymap("n", "<leader>w-", "<C-W>s", { desc = "Split window below", remap = true })
		keymap("n", "<leader>w|", "<C-W>v", { desc = "Split window right", remap = true })
		keymap("n", "<leader>-", "<C-W>s", { desc = "Split window below", remap = true })
		keymap("n", "<leader>|", "<C-W>v", { desc = "Split window right", remap = true })

		-- tabs
		keymap("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
		keymap("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
		keymap("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
		keymap("n", "<leader><tab>", "<cmd>tabnext<cr>", { desc = "Next Tab" })
		keymap("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
		keymap("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
		keymap("n", "<leader><tab>1", "1gt", { desc = "Go to tab 1" })
		keymap("n", "<leader><tab>2", "2gt", { desc = "Go to tab 2" })
		keymap("n", "<leader><tab>3", "3gt", { desc = "Go to tab 3" })
		keymap("n", "<leader><tab>4", "4gt", { desc = "Go to tab 4" })
		keymap("n", "<leader><tab>5", "5gt", { desc = "Go to tab 5" })
		keymap("n", "<leader><tab>6", "6gt", { desc = "Go to tab 6" })
		keymap("n", "<leader><tab>7", "7gt", { desc = "Go to tab 7" })
		keymap("n", "<leader><tab>8", "8gt", { desc = "Go to tab 8" })
		keymap("n", "<leader><tab>9", "9gt", { desc = "Go to tab 9" })
		keymap("t", "<esc><esc>", "<c-\\><c-n>", { buffer = true })

		keymap("n", "]z", function()
			local cur_line = vim.fn.line(".")
			local line_count = vim.fn.line("$")
			while vim.fn.foldclosed(cur_line) > 0 do
				cur_line = cur_line + 1
				if cur_line > line_count then
					break
				end
			end
			for i = cur_line, line_count do
				if vim.fn.foldclosed(i) > 0 then
					vim.cmd(tostring(i))
					return
				end
			end
		end, { desc = "Go to Next Fold" })

		keymap("n", "[z", function()
			local cur_line = vim.fn.line(".")
			while vim.fn.foldclosed(cur_line) > 0 do
				cur_line = cur_line - 1
				if cur_line < 1 then
					return
				end
			end
			local in_closed_fold = false
			for i = cur_line, 1, -1 do
				if vim.fn.foldclosed(i) > 0 then
					in_closed_fold = true
				elseif in_closed_fold then
					vim.cmd(tostring(i + 1))
					return
				end
			end
		end, { desc = "Go to Prev Fold" })

		keymap("n", "<leader>bx", function()
			local visible_bufs = {}
			for _, w in pairs(vim.api.nvim_list_wins()) do
				local buf = vim.api.nvim_win_get_buf(w)
				table.insert(visible_bufs, buf)
			end
			local deleted_count = 0
			for _, bufnr in pairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(bufnr) and not vim.tbl_contains(visible_bufs, bufnr) then
					local force = vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == "terminal"
					local ok = pcall(vim.api.nvim_buf_delete, bufnr, { force = force })
					if ok then
						deleted_count = deleted_count + 1
					end
				end
			end
			vim.notify(string.format("%s %d %s", "Deleted", deleted_count, "buffers"), 2)
		end, { desc = "Close Non-Visible Buffers" })

		local conceallevel = vim.o.conceallevel > 0 and vim.o.conceallevel or 3
		local showtabline = vim.o.showtabline > 0 and vim.o.showtabline or 2
        -- stylua: ignore start
        keymap("n", "<leader>us", function() utils.toggle_option("spell") end, { desc = "Toggle Spelling" })
		keymap("n", "<leader>uw", function() utils.toggle_option("wrap") end, { desc = "Toggle Word Wrap" })
		keymap("n", "<leader>uL", function() utils.toggle_option("relativenumber") end, { desc = "Toggle Relative Line Numbers" })
		keymap("n", "<leader>ul", function() utils.toggle_number() end, { desc = "Toggle Line Numbers" })
		keymap("n", "<leader>ud", function() utils.toggle_diagnostics() end, { desc = "Toggle Diagnostics" })
		keymap("n", "<leader>uc", function() utils.toggle_option("conceallevel", false, { 0, conceallevel }) end, { desc = "Toggle Conceal Level" })
		keymap("n", "<leader>um", function() utils.toggle_option("showtabline", false, { 0, showtabline }) end, { desc = "Toggle Tabline" })
		keymap("n", "<leader>uT", function() if vim.b.ts_highlight then vim.treesitter.stop() else vim.treesitter.start() end end, { desc = "Toggle Treesitter Highlight" })
		keymap({ "n", "x" }, "q", function() require("utils").close_float_window() end, { desc = "close floating window" })

        -- auto indent
		keymap("n", "i", function() if #vim.fn.getline(".") == 0 then return [["_cc]] else return "i" end end, { expr = true })
		-- stylua: ignore end

		local function diagnostic_goto(next, severity)
			local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
			severity = severity and vim.diagnostic.severity[severity] or nil
			return function()
				go({ severity = severity })
			end
		end
		keymap("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
		keymap("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
		keymap("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
		keymap("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
		keymap("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warn" })
		keymap("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warn" })
		keymap("n", "[i", diagnostic_goto(false, "INFO"), { desc = "Prev Info" })
		keymap("n", "]i", diagnostic_goto(true, "INFO"), { desc = "Next Info" })
		keymap("n", "[h", diagnostic_goto(false, "HINT"), { desc = "Prev Hint" })
		keymap("n", "]h", diagnostic_goto(true, "HINT"), { desc = "Next Hint" })

		keymap("x", "@", function()
			return ":norm @" .. vim.fn.getcharstr() .. "<cr>"
		end, { expr = true, silent = true })

		keymap("n", "gQ", "mzgggqG`z<cmd>delmarks z<cr>zz", { desc = "Format buffer", silent = true })

		vim.g.mc = vim.api.nvim_replace_termcodes([[y/\V<C-r>=escape(@", '/')<CR><CR>]], true, true, true)
		function SetupMultipleCursors()
			keymap(
				"n",
				"<Enter>",
				[[:nnoremap <lt>Enter> n@z<CR>q:<C-u>let @z=strpart(@z,0,strlen(@z)-1)<CR>n@z]],
				{ remap = true, silent = true }
			)
		end

		keymap("n", "cq", [[:\<C-u>call v:lua.SetupMultipleCursors()<CR>*``qz]], { desc = "Inititiate with macros" })
		keymap(
			"x",
			"cq",
			[[":\<C-u>call v:lua.SetupMultipleCursors()<CR>gv" . g:mc . "``qz"]],
			{ expr = true, desc = "Inititiate with macros" }
		)

		keymap(
			"n",
			"cQ",
			[[:\<C-ucall v:lua.SetupMultipleCursors()<CR>#``qz]],
			{ desc = "Inititiate with macros (in backwards direction)" }
		)
		keymap(
			"x",
			"cQ",
			[[":\<C-u>call v:lua.SetupMultipleCursors()<CR>gv" . substitute(g:mc, '/', '?', 'g') . "``qz"]],
			{ desc = "Inititiate with macros (in backwards direction)", expr = true }
		)
	end,
}
