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

vim.api.nvim_create_autocmd("InsertEnter", {
    once = true,
    group = vim.api.nvim_create_augroup("ExpandTabSetup", {}),
    callback = function()
        vim.on_key(function(key)
            if key ~= "\t" or vim.bo.et or vim.fn.match(vim.fn.mode(), [[^i\|^R]]) == -1 then
                return
            end

            local col = vim.api.nvim_win_get_cursor(0)[2]
            local line = vim.api.nvim_get_current_line()
            local after_non_blank = vim.fn.match(line:sub(1, col), [[\S]]) >= 0
            -- An adjacent tab is a tab that can be joined with the tab
            -- inserted before the cursor assuming 'noet' is set
            local has_adjacent_tabs = vim.fn.match(line:sub(1, col), string.format([[\t\ \{,%d}$]], math.max(0, vim.bo.ts - 1))) >= 0
                or line:sub(col + 1, col + 1) == "\t"

            if not after_non_blank or has_adjacent_tabs then
                return
            end

            if vim.b.et == nil then
                vim.b.et = vim.bo.et
            end
            vim.bo.et = true
        end)

        vim.api.nvim_create_autocmd("TextChangedI", {
            group = vim.api.nvim_create_augroup("Expandtab", {}),
            callback = function(info)
                -- Restore 'expandtab' setting
                if vim.b[info.buf].et == nil then
                    return
                end
                vim.bo[info.buf].et = vim.b[info.buf].et
                vim.b[info.buf].et = nil
            end,
        })
    end,
})
