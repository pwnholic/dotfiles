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

vim.api.nvim_create_autocmd("ModeChanged", {
    pattern = { "[itRss\x13]*:*", "*:[itRss\x13]*" },
    callback = function()
        if vim.v.event.new_mode:match("^[itRss\x13]") then
            if vim.wo.cul then
                vim.w._cul = true
                vim.wo.cul = false
            end
            if vim.wo.cuc then
                vim.w._cuc = true
                vim.wo.cuc = false
            end

            local hl = { italic = true, bold = true }
            vim.api.nvim_set_hl(0, "LspReferenceText", hl)
            vim.api.nvim_set_hl(0, "LspReferenceRead", hl)
            vim.api.nvim_set_hl(0, "LspReferenceWrite", hl)
        else
            if vim.w._cul and not vim.wo.cul then
                vim.wo.cul = true
                vim.w._cul = nil
            end
            if vim.w._cuc and not vim.wo.cuc then
                vim.wo.cuc = true
                vim.w._cuc = nil
            end

            local hl = { italic = true, bold = true, reverse = true }
            vim.api.nvim_set_hl(0, "LspReferenceText", hl)
            vim.api.nvim_set_hl(0, "LspReferenceRead", hl)
            vim.api.nvim_set_hl(0, "LspReferenceWrite", hl)
        end
    end,
})
