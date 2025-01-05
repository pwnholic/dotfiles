vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.signcolumn = "no"
vim.opt_local.stc = ""
vim.opt_local.winbar = ""

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("ReplCmp", { clear = true }),
    pattern = "dap-repl",
    callback = function()
        require("dap.ext.autocompl").attach()
    end,
})
