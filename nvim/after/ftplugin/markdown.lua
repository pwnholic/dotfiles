vim.opt_local.spell = true
vim.opt_local.wrap = true
vim.opt_local.list = false
vim.opt_local.wrapmargin = 113
vim.opt_local.statuscolumn = nil
vim.opt_local.number = false
vim.opt_local.relativenumber = false

vim.treesitter.language.register("sql", "dataview")
vim.treesitter.language.register("javascript", "dataviewjs")

local map = vim.keymap.set

local function obsidan_map(cmd, prompt)
	return function()
		if prompt == nil then
			return vim.cmd[cmd]()
		else
			vim.ui.input({ prompt = prompt .. " : " }, function(input)
				if input == "" then
					return vim.cmd[cmd]()
				else
					return vim.cmd[cmd](input)
				end
			end)
		end
	end
end

map("n", "<leader>nn", obsidan_map("ObsidianNew", "[opts] Title"), { desc = "New Note" })
map("n", "<leader>nf", obsidan_map("ObsidianFollowLink", "[vsplit|split] Link Under Cursor"), { desc = "Follow Link" })
map("n", "<leader>nx", obsidan_map("ObsidianExtractNote", "Title"), { desc = "Extract Note" })
map("n", "<leader>np", obsidan_map("ObsidianPasteImg", "Image Name"), { desc = "Paste Image" })
map("n", "<leader>nr", obsidan_map("ObsidianRename", "New Name"), { desc = "Rename Note" })
map("n", "<leader>nm", vim.cmd.ObsidianTemplate, { desc = "Template" })
map("n", "<leader>nw", vim.cmd.ObsidianWorkspace, { desc = "Workspace" })
map("n", "<leader>nT", vim.cmd.ObsidianTags, { desc = "Tags" })
map("n", "<leader>ns", vim.cmd.ObsidianQuickSwitch, { desc = "Quick Swicth" })
map("n", "<leader>nL", vim.cmd.ObsidianLinks, { desc = "Collect Link" })
map("n", "<leader>ny", vim.cmd.ObsidianYesterday, { desc = "Yesterday Note" })
map("n", "<leader>nw", vim.cmd.ObsidianTomorrow, { desc = "Tomorrow Note" })
map("n", "<leader>no", vim.cmd.ObsidianOpen, { desc = "Open App" })
map("n", "<leader>nd", vim.cmd.ObsidianDailies, { desc = "Dailies Note" })
map("n", "<leader>ns", vim.cmd.ObsidianSearch, { desc = "Search Note" })
map("v", "<leader>nl", vim.cmd.ObsidianLink, { desc = "Link" })
map("n", "<leader>nt", vim.cmd.ObsidianToday, { desc = "Today Note" })
map("n", "<leader>nb", vim.cmd.ObsidianBacklinks, { desc = "Back Link" })
map("v", "<leader>nN", vim.cmd.ObsidianLinkNew, { desc = "Create New Link" })
