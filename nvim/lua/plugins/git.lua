return {
	{
		"lewis6991/gitsigns.nvim",
		event = "BufReadPost",
		opts = {
			current_line_blame = true,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol",
				delay = 2000,
				ignore_whitespace = false,
				virt_text_priority = 100,
			},
			watch_gitdir = { interval = 1000, follow_files = true },
			diff_opts = { algorithm = "histogram", internal = true, indent_heuristic = true },
			sign_priority = 6,
			update_debounce = 100,
			on_attach = function(buffer)
				local gs = package.loaded.gitsigns
				local function map(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
				end
                -- stylua: ignore start
				map("n", "]h", gs.next_hunk, "Next Hunk")
				map("n", "[h", gs.prev_hunk, "Prev Hunk")
				map({ "n", "v" }, "<leader>ha", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
				map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
				map("n", "<leader>hs", gs.stage_buffer, "Stage Buffer")
				map("n", "<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
				map("n", "<leader>hR", gs.reset_buffer, "Reset Buffer")
				map("n", "<leader>hp", gs.preview_hunk, "Preview Hunk")
				map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame Line")
				map("n", "<leader>hd", gs.diffthis, "Diff This")
				map("n", "<leader>hD", function() gs.diffthis("~") end, "Diff This ~")
				map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
				-- stylua: ignore end
			end,
		},
	},
	{
		"sindrets/diffview.nvim",
		cmd = {
			"DiffviewOpen",
			"DiffviewClose",
			"DiffviewToggleFiles",
			"DiffviewFocusFiles",
			"DiffviewRefresh",
			"DiffviewFileHistory",
		},
		opts = function()
			local actions = require("diffview.actions")
			return {
				diff_binaries = false,
				enhanced_diff_hl = false, -- Set up hihglights in the hooks instead
				git_cmd = { "git" },
				hg_cmd = { "chg" },
				use_icons = true,
				show_help_hints = false,
				icons = { folder_closed = " ", folder_open = " " },
				signs = { fold_closed = "", fold_open = "" },
				view = {
					default = { winbar_info = false },
					merge_tool = { layout = "diff3_mixed", disable_diagnostics = true, winbar_info = true },
					file_history = { winbar_info = false },
				},
				file_panel = {
					listing_style = "tree",
					tree_options = { flatten_dirs = true, folder_statuses = "only_folded" },
					win_config = function()
						return { position = "left", width = vim.o.columns >= 247 and 45 or 35 }
					end,
				},
				file_history_panel = {
					log_options = {
						git = {
							single_file = { diff_merges = "first-parent", follow = true },
							multi_file = { diff_merges = "first-parent" },
						},
					},
					win_config = { position = "bottom", height = 16 },
				},
				hooks = {
					diff_buf_read = function()
						vim.opt_local.wrap = false
					end,
					diff_buf_win_enter = function(_, _, ctx)
						if ctx.layout_name:match("^diff2") then
							if ctx.symbol == "a" then
								vim.opt_local.winhl = table.concat({
									"DiffAdd:DiffviewDiffAddAsDelete",
									"DiffDelete:DiffviewDiffDelete",
									"DiffChange:DiffAddAsDelete",
									"DiffText:DiffDeleteText",
								}, ",")
							elseif ctx.symbol == "b" then
								vim.opt_local.winhl = table.concat({
									"DiffDelete:DiffviewDiffDelete",
									"DiffText:DiffAddText",
									"DiffChange:DiffAdd",
								}, ",")
							end
						end
					end,
				},
				keymaps = {
					view = { { "n", "-", actions.toggle_stage_entry, { desc = "Stage / unstage the selected entry" } } },
					file_panel = {
                        -- stylua: ignore start
						{ "n", "<cr>", actions.focus_entry, { desc = "Focus the selected entry" } },
						{ "n", "s", actions.toggle_stage_entry, { desc = "Stage / unstage the selected entry" } },
						-- { "n", "cc", "<Cmd>Git commit <bar> wincmd J<CR>", { desc = "Commit staged changes" } },
						-- { "n", "ca", "<Cmd>Git commit --amend <bar> wincmd J<CR>", { desc = "Amend the last commit" } },
						-- { "n", "c<space>", ":Git commit ", { desc = 'Populate command line with ":Git commit "' } },
						-- { "n", "rr", "<Cmd>Git rebase --continue <bar> wincmd J<CR>", { desc = "Continue the current rebase" } },
						-- { "n", "re", "<Cmd>Git rebase --edit-todo <bar> wincmd J<CR>", { desc = "Edit the current rebase todo list." } },
						{ "n", "[c", actions.view_windo(function(_, sym) if sym == "b" then vim.cmd.norm({ args = { "[c" }, bang = true }) end end) },
						{ "n", "]c", actions.view_windo(function(_, sym) if sym == "b" then vim.cmd.norm({ args = { "]c" }, bang = true }) end end) },
						{ "n", "do", actions.view_windo(function(_, sym) if sym == "b" then vim.cmd.norm({ args = { "do" }, bang = true }) end end) },
						{ "n", "dp", actions.view_windo(function(_, sym) if sym == "b" then vim.cmd.norm({ args = { "dp" }, bang = true }) end end) },
						-- stylua: ignore end
					},
					file_history_panel = { { "n", "<cr>", actions.focus_entry, { desc = "Focus the selected entry" } } },
				},
			}
		end,
	},
}
