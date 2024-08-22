require("generals")
require("packages")
require("setup")
require("autocmds")
require("keymaps")

-- TODO: do swap variable
vim.keymap.set("n", "<A-space>", function()
	local fzf = require("fzf-lua")
	local hp = require("harpoon")

	fzf.fzf_exec(function(cb)
		for _, item in ipairs(hp:list().items) do
			cb(item.value)
		end
		cb()
	end, {
		prompt = "Harpoon : ",
		cwd_header = false,
		actions = {
			["enter"] = fzf.actions.file_edit,
			["ctrl-s"] = fzf.actions.file_split,
			["ctrl-v"] = fzf.actions.file_vsplit,
			["ctrl-x"] = function(s)
				for i, v in ipairs(s) do
					table.remove(hp:list().items, i)
					vim.notify(string.format("Remove %s from mark", v), 2, { title = "Harpoon" })
				end
			end,
		},
	})
end)
