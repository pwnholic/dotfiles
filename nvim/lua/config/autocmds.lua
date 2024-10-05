-- vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "FocusLost" }, {
--     nested = true,
--     desc = "Autosave on focus change.",
--     callback = function()
--         vim.cmd.update({ mods = { emsg_silent = true } })
--     end,
-- })

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileChangedShellPost" }, {
    desc = "Automatically change local current directory.",
    callback = function(info)
        if info.file == "" or vim.bo[info.buf].bt ~= "" then
            return
        end
        if not LazyVim.root() or LazyVim.root() == vim.fn.getcwd(0) then
            return
        end
        for _, win in ipairs(vim.fn.win_findbuf(info.buf)) do
            vim.api.nvim_win_call(win, function()
                pcall(vim.cmd.lcd, { LazyVim.root(), mods = { silent = true, emsg_silent = true } })
            end)
        end
    end,
})
