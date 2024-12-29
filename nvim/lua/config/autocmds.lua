vim.api.nvim_create_autocmd("ModeChanged", {
    pattern = { "[itRss\x13]*:*", "*:[itRss\x13]*" },
    callback = function()
        if vim.v.event.new_mode:match("^[itRss\x13]") then
            if vim.wo.cursorline then
                vim.w._cursorline = true
                vim.wo.cursorline = false
            end
            if vim.wo.cursorcolumn then
                vim.w._cursorcolumn = true
                vim.wo.cursorcolumn = false
            end
            local hl = { italic = true, bold = true, underline = true }
            vim.api.nvim_set_hl(0, "LspReferenceText", hl)
            vim.api.nvim_set_hl(0, "LspReferenceRead", hl)
            vim.api.nvim_set_hl(0, "LspReferenceWrite", hl)
        else
            if vim.w._cursorline and not vim.wo.cursorline then
                vim.wo.cursorline = true
                vim.w._cursorline = nil
            end
            if vim.w._cursorcolumn and not vim.wo.cursorcolumn then
                vim.wo.cursorcolumn = true
                vim.w._cursorcolumn = nil
            end
            local hl = { italic = true, bold = true, reverse = true }
            vim.api.nvim_set_hl(0, "LspReferenceText", hl)
            vim.api.nvim_set_hl(0, "LspReferenceRead", hl)
            vim.api.nvim_set_hl(0, "LspReferenceWrite", hl)
        end
    end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "FileChangedShellPost" }, {
    desc = "Automatically change local current directory.",
    callback = function(info)
        if info.file == "" or vim.bo[info.buf].buftype ~= "" then
            return
        end

        if not LazyVim.root() or LazyVim.root() == vim.uv.cwd() then
            return
        end

        for _, win in ipairs(vim.fn.win_findbuf(info.buf)) do
            vim.api.nvim_win_call(win, function()
                pcall(vim.cmd.lcd, { LazyVim.root(), mods = { silent = true, emsg_silent = true } })
            end)
        end
    end,
})
