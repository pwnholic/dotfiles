return {
	"willothy/flatten.nvim",
	lazy = false,
	priority = 1000,
	opts = function()
		---Check if a file is a git (commit, rebase, etc.) file
		---@param fpath string
		---@return boolean
		local function should_block_file(fpath)
			local fname = vim.fs.basename(fpath)
			return fname == "rebase-merge"
				or fname == "COMMIT_EDITMSG"
				or vim.startswith(vim.fs.normalize(fpath), "/tmp/")
		end

		if tonumber(vim.fn.system({ "id", "-u" })) == 0 then
			vim.env["NVIM_ROOT_" .. vim.fn.getpid()] = "1"
		end
		return {
			window = { open = "alternate" },
			block_for = { gitcommit = true, gitrebase = true },
			callbacks = {
				should_nest = function()
					local pid = vim.fn.getpid()
					local parent_pid = vim.env.NVIM and vim.env.NVIM:match("nvim%.(%d+)")
					if vim.env["NVIM_ROOT_" .. pid] and parent_pid and not vim.env["NVIM_ROOT_" .. parent_pid] then
						return true
					end
				end,
				should_block = function()
					local files = vim.fn.argv() --[=[@as string[]]=]
					for _, file in ipairs(files) do
						if should_block_file(file) then
							return true
						end
					end
					return false
				end,
				post_open = function(buf, win)
					vim.api.nvim_set_current_win(win)
					local bufname = vim.api.nvim_buf_get_name(buf)
					if should_block_file(bufname) then
						vim.bo[buf].bufhidden = "wipe"
						local keymap_utils = require("utils.keys")
						keymap_utils.command_abbrev("x", "b#", { buffer = buf })
						keymap_utils.command_abbrev("wq", "b#", { buffer = buf })
						keymap_utils.command_abbrev("bw", "b#", { buffer = buf })
						keymap_utils.command_abbrev("bd", "b#", { buffer = buf })
					end
				end,
			},
			one_per = { kitty = false, wezterm = false },
		}
	end,
}
