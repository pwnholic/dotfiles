vim.opt_local.expandtab = true

local map = vim.keymap.set

local ok, cmp = pcall(require, "cmp")
if ok then
	cmp.setup.filetype({ "go" }, {
		mapping = {
			["<CR>"] = cmp.mapping(function(fb)
				if cmp.visible() then
					return cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })(fb)
				else
					return fb()
				end
			end, { "i" }),
		},
	})
end

local function input(prompt, cmd)
	return function()
		vim.ui.input({ prompt = prompt }, function(name)
			if name ~= "" then
				return vim.cmd[cmd](name)
			end
		end)
	end
end

map("n", "<leader>jw", vim.cmd.GoFillSwitch, { desc = "Fill Switch" })
map("n", "<leader>jf", vim.cmd.GoFillStruct, { desc = "Auto Sill Struct" })
map("n", "<leader>je", vim.cmd.GoIfErr, { desc = "Add If Err" })
map("n", "<leader>jd", vim.cmd.GoDebug, { desc = "Go Debug" })
map("n", "<leader>jp", vim.cmd.GoFixPlurals, { desc = "Fix Plurals Func" })
map("n", "<leader>jC", vim.cmd.GoClearname, { desc = "Clear All names" })
map("n", "<leader>jc", vim.cmd.GoCmt, { desc = "Add comment" })
map("n", "<leader>ja", vim.cmd.GoModInit, { desc = "`go mod init`" })
map("n", "<leader>jv", vim.cmd.GoModVendor, { desc = "`go mod vendor`" })
map("n", "<leader>jy", vim.cmd.GoModTidy, { desc = "`go mod tidy`" })
map("n", "<leader>jt", vim.cmd.GoAddTest, { desc = "Add New Test File" })
map({ "n", "v" }, "<leader>jt", input("Add name : ", "GoAddTag"), { desc = "Add Tags" })
map({ "n", "v" }, "<leader>jr", input("Remove name : ", "GoRmTag"), { desc = "Remove Tags" })
map("n", "<leader>ji", input("Struct -> Interface : ", "GoImpl"), { desc = "GoImpl `struct name` `interface`" })
map("n", "<leader>jn", input("New File : ", "GoNew"), { desc = "GoNew `package name` `location`" })
