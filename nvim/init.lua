---@diagnostic disable-next-line: duplicate-set-field
vim.validate = function() end

vim.loader.enable()

require("config.lazy")
