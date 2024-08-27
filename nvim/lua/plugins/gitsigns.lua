return {
	"lewis6991/gitsigns.nvim",
	event = "BufReadPre",
	opts = function()
		local icons = require("utils.icons").misc
		return {
			current_line_blame = true,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
				delay = 1000,
				ignore_whitespace = false,
				virt_text_priority = 100,
			},
			signs = {
				add = { text = icons.vertical_bar_bold },
				change = { text = icons.vertical_bar_bold },
				delete = { text = icons.vertical_bar_bold },
				topdelete = { text = icons.vertical_bar_bold },
				changedelete = { text = icons.vertical_bar_bold },
				untracked = { text = icons.vertical_bar_bold },
			},
			signs_staged = {
				add = { text = icons.vertical_bar_bold },
				change = { text = icons.vertical_bar_bold },
				delete = { text = icons.vertical_bar_bold },
				topdelete = { text = icons.vertical_bar_bold },
				changedelete = { text = icons.vertical_bar_bold },
			},
			on_attach = function(buffer)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
				end

                    -- stylua: ignore start
					map("n", "]h", function() if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end end, "Next Hunk")
					map("n", "[h", function() if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end end, "Prev Hunk")
					map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk") map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
					map({ "n", "v" }, "<leader>hA", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
					map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
					map("n", "<leader>ha", gs.stage_buffer, "Stage Buffer")
					map("n", "<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
					map("n", "<leader>hR", gs.reset_buffer, "Reset Buffer")
					map("n", "<leader>hp", gs.preview_hunk_inline, "Preview Hunk Inline")
					map("n", "<leader>hB", function() gs.blame_line({ full = true }) end, "Blame Line") map("n", "<leader>hB", function() gs.blame() end, "Blame Buffer")
					map("n", "<leader>hd", gs.diffthis, "Diff This") map("n", "<leader>hD", function() gs.diffthis("~") end, "Diff This ~")
					map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
				-- stylua: ignore end
			end,
		}
	end,
}
