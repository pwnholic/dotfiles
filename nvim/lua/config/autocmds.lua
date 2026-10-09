-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Shared group for everything that quiets down while typing: cursor
-- guides plus LSP chrome. One group so `:au user_lsp_insert_toggle`
-- shows the whole picture.
local typing_group = vim.api.nvim_create_augroup("user_lsp_insert_toggle", { clear = true })

-- Cursor guides while typing: `cursorline`/`cursorcolumn` highlight the whole
-- row/column, which is noise mid-keystroke when the blinking block cursor
-- already marks the position. Both are restored on InsertLeave -- but only
-- if they were on before, so a manual `:set nocursorline` stays off.
vim.api.nvim_create_autocmd("InsertEnter", {
    group = typing_group,
    desc = "Hide cursorline/cursorcolumn while typing",
    callback = function(args)
        -- `args.win` is absent when the event is faked (e.g. via
        -- `nvim_exec_autocmds` in tests); the current window is the
        -- correct fallback since InsertEnter is always window-local.
        local win = args.win or vim.api.nvim_get_current_win()
        if vim.wo[win].cursorline then
            vim.b[args.buf].user_cursorline_was_enabled = true
            vim.wo[win].cursorline = false
        end
        if vim.wo[win].cursorcolumn then
            vim.b[args.buf].user_cursorcolumn_was_enabled = true
            vim.wo[win].cursorcolumn = false
        end
    end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
    group = typing_group,
    desc = "Restore cursorline/cursorcolumn after typing",
    callback = function(args)
        if vim.b[args.buf].user_cursorline_was_enabled then
            vim.b[args.buf].user_cursorline_was_enabled = nil
            local win = args.win or vim.api.nvim_get_current_win()
            if vim.api.nvim_win_is_valid(win) then
                vim.wo[win].cursorline = true
            end
        end
        if vim.b[args.buf].user_cursorcolumn_was_enabled then
            vim.b[args.buf].user_cursorcolumn_was_enabled = nil
            local win = args.win or vim.api.nvim_get_current_win()
            if vim.api.nvim_win_is_valid(win) then
                vim.wo[win].cursorcolumn = true
            end
        end
    end,
})

-- Auto-quieten LSP chrome while typing: inlay hints and codelens virtual
-- text shift code as you type, which is noisy mid-keystroke. Both come back
-- on InsertLeave -- but only if they were on before (a manual `<leader>uh`
-- toggle-off, or codelens disabled in the LazyVim LSP opts, stays off).
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
