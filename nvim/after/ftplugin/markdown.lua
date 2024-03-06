vim.opt_local.spell = true
vim.opt_local.wrap = true
vim.opt_local.list = false
vim.opt_local.formatoptions:append("t")
vim.opt_local.statuscolumn = "%="
vim.opt_local.textwidth = 113

local map = vim.keymap.set

map({ "n", "v", "i" }, "<C-CR>", vim.cmd.MkdnEnter, { desc = "Create New Note" })
map({ "v", "n" }, "<leader>nC", vim.cmd.MkdnCreateLinkFromClipboard, { desc = "Create Link From Clipboard" })
map("n", "<leader>nl", vim.cmd.MkdnNextLink, { desc = "Next Link" })
map("n", "<leader>nL", vim.cmd.MkdnPrevLink, { desc = "Prev Link" })
map("n", "<leader>nh", vim.cmd.MkdnNextHeading, { desc = "Next Heading" })
map("n", "<leader>nH", vim.cmd.MkdnPrevHeading, { desc = "Prev Heading" })
map("n", "<leader>nb", vim.cmd.MkdnGoBack, { desc = "Go Back" })
map("n", "<leader>nf", vim.cmd.MkdnGoForward, { desc = "Go Forward" })
map("n", "<leader>nc", vim.cmd.MkdnCreateLink, { desc = "Create Link" })
map("n", "<leader>nf", vim.cmd.MkdnFollowLink, { desc = "Follow Link" })
map("n", "<leader>nF", vim.cmd.MkdnDestroyLink, { desc = "Destroy Link" })
map("n", "<leader>nt", vim.cmd.MkdnTagSpan, { desc = "Tag Span" })
map("n", "<leader>nm", vim.cmd.MkdnMoveSource, { desc = "Move Source" })
map("n", "<leader>ny", vim.cmd.MkdnYankAnchorLink, { desc = "Yank Anchor Link" })
map("n", "<leader>nY", vim.cmd.MkdnYankFileAnchorLink, { desc = "Yank File Anchor Link" })
