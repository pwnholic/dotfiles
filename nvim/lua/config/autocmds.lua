-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local session_group = vim.api.nvim_create_augroup("SessionManagement", { clear = true })
vim.api.nvim_create_autocmd("VimEnter", {
    group = session_group,
    callback = function()
        if vim.fn.argc() == 0 then
            require("persistence").load()
        end
    end,
    nested = true,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
    group = session_group,
    callback = function()
        require("persistence").save()
    end,
})

vim.api.nvim_create_autocmd("DirChanged", {
    group = session_group,
    callback = function()
        require("persistence").save()
    end,
})
