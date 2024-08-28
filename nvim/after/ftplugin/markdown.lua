vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.signcolumn = "no"
vim.opt_local.stc = nil

require("utils.lsp").start({
	cmd = { vim.fn.stdpath("data") .. "/mason/bin/marksman", "server" },
	name = "marksman",
	root_patterns = { ".git", ".marksman.toml" },
	single_file_support = true,
})

local function Obsidian(cmd)
	return function()
		vim.ui.input({ prompt = "Enter your " .. cmd .. " Notes: " }, function(args)
			args = args:gsub("%s+", " ")
			if args == "" then
				return vim.cmd["Obsidian" .. cmd]()
			else
				return vim.cmd["Obsidian" .. cmd](args)
			end
		end)
	end
end

vim.keymap.set("n", "<leader>nn", Obsidian("New"), { desc = "New Note [name]" })
vim.keymap.set("n", "<leader>nT", Obsidian("Tags"), { desc = "Tags [tags]" })
vim.keymap.set("n", "<leader>ns", Obsidian("Search"), { desc = "Search [query]" })
vim.keymap.set("n", "<leader>ni", Obsidian("PasteImg"), { desc = "Paste Image [name]" })
vim.keymap.set("n", "<leader>nr", Obsidian("Rename"), { desc = "Rename [new name]" })
vim.keymap.set("n", "<leader>nl", "<cmd>ObsidianFollowLink<cr>", { desc = "Follow Link" })
vim.keymap.set("n", "<leader>nb", "<cmd>ObsidianBacklinks<cr>", { desc = "Backlink" })
vim.keymap.set("n", "<leader>nt", "<cmd>ObsidianTemplate<cr>", { desc = "Tamplate" })
vim.keymap.set("n", "<leader>no", "<cmd>ObsidianNewFromTemplate<cr>", { desc = "New from Template" })
vim.keymap.set("n", "<leader>nm", "<cmd>ObsidianTOC<cr>", { desc = "ToC" })
