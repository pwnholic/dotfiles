
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

map("n", "<leader>no", obsidan_map("ObsidianOpen", "[opts] ID, path or Alias"), { desc = "Open App" })
map("n", "<leader>nn", obsidan_map("ObsidianNew", "[opts] Title"), { desc = "New Note" })
map("n", "<leader>ns", obsidan_map("ObsidianQuickSwitch"), { desc = "Quick Swicth" })
map("n", "<leader>nf", obsidan_map("ObsidianFollowLink", "[vsplit|split] Link Under Cursor"), { desc = "Follow Link" })
map("n", "<leader>nb", obsidan_map("ObsidianBacklinks"), { desc = "Back Link" })
map("n", "<leader>nT", obsidan_map("ObsidianTags", "Tags"), { desc = "Tags" })
map("n", "<leader>nt", obsidan_map("ObsidianToday", "[opts] Offset"), { desc = "Today Note" })
map("n", "<leader>ny", obsidan_map("ObsidianYesterday"), { desc = "Yesterday Note" })
map("n", "<leader>nw", obsidan_map("ObsidianTomorrow"), { desc = "Tomorrow Note" })
map("n", "<leader>nd", obsidan_map("ObsidianDailies", "[opts] Offset"), { desc = "Dailies Note" })
map("n", "<leader>nm", obsidan_map("ObsidianTemplate", "Name"), { desc = "Template" })
map("n", "<leader>ns", obsidan_map("ObsidianSearch", "Query"), { desc = "Search Note" })
map("v", "<leader>nl", obsidan_map("ObsidianLink", "Query"), { desc = "Link" })
map("v", "<leader>nN", obsidan_map("ObsidianLinkNew", "Title"), { desc = "Create New Link" })
map("n", "<leader>nL", obsidan_map("ObsidianLinks"), { desc = "Collect Link" })
map("n", "<leader>nx", obsidan_map("ObsidianExtractNote", "Title"), { desc = "Extract Note" })
map("n", "<leader>nw", obsidan_map("ObsidianWorkspace", "Name"), { desc = "Workspace" })
map("n", "<leader>np", obsidan_map("ObsidianPasteImg", "Image Name"), { desc = "Paste Image" })
map("n", "<leader>nr", obsidan_map("ObsidianRename", "New Name"), { desc = "Rename Note" })
