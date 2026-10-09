-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-quieten LSP chrome while typing: inlay hints and codelens virtual
-- text shift code as you type, which is noisy mid-keystroke. Both come back
-- on InsertLeave -- but only if they were on before (a manual `<leader>uh`
-- toggle-off, or codelens disabled in the LazyVim LSP opts, stays off).
local typing_group = vim.api.nvim_create_augroup("user_lsp_insert_toggle", { clear = true })
vim.api.nvim_create_autocmd("InsertEnter", {
    group = typing_group,
    desc = "Hide inlay hints and codelens while typing",
    callback = function(args)
        if vim.lsp.inlay_hint and vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }) then
            vim.b[args.buf].user_inlay_was_enabled = true
            vim.lsp.inlay_hint.enable(false, { bufnr = args.buf })
        end
        if vim.lsp.codelens and vim.lsp.codelens.is_enabled({ bufnr = args.buf }) then
            vim.b[args.buf].user_codelens_was_enabled = true
            vim.lsp.codelens.enable(false, { bufnr = args.buf })
        end
    end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
    group = typing_group,
    desc = "Restore inlay hints and codelens after typing",
    callback = function(args)
        if vim.b[args.buf].user_inlay_was_enabled then
            vim.b[args.buf].user_inlay_was_enabled = nil
            if vim.lsp.inlay_hint then
                vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
            end
        end
        if vim.b[args.buf].user_codelens_was_enabled then
            vim.b[args.buf].user_codelens_was_enabled = nil
            if vim.lsp.codelens then
                vim.lsp.codelens.enable(true, { bufnr = args.buf })
            end
        end
    end,
})
