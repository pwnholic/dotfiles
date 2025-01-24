vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.signcolumn = "no"
vim.opt_local.stc = ""
vim.opt_local.winbar = ""

vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("ReplCmp", { clear = true }),
    pattern = "dap-repl",
    callback = function(opt)
        require("dap.ext.autocompl").attach(opt.buf)
    end,
})
