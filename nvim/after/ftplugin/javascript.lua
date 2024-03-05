local map = vim.keymap.set

map("n", "<leader>jo", vim.cmd.TSToolsOrganizeImports, { desc = "Organize Imports" })
map("n", "<leader>js", vim.cmd.TSToolsSortImports, { desc = "Sort Imports" })
map("n", "<leader>jr", vim.cmd.TSToolsRemoveUnusedImports, { desc = "Remove Unused Imports" })
map("n", "<leader>jx", vim.cmd.TSToolsRemoveUnused, { desc = "Remove Unused" })
map("n", "<leader>jm", vim.cmd.TSToolsAddMissingImports, { desc = "Add Missing Imports" })
map("n", "<leader>jf", vim.cmd.TSToolsFixAll, { desc = "Fix All" })
map("n", "<leader>jd", vim.cmd.TSToolsGoToSourceDefinition, { desc = "GoTo Source Definition " })
map("n", "<leader>jn", vim.cmd.TSToolsRenameFile, { desc = "Rename File" })
map("n", "<leader>jr", vim.cmd.TSToolsFileReferences, { desc = "File References" })
