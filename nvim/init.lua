require("options")

vim.env.PATH = vim.env.PATH .. ":" .. vim.fn.stdpath("data") .. "/mason/bin"

require("packages")
require("autocmds")
require("keymaps")
