vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "FocusLost" }, {
    nested = true,
    desc = "Autosave on focus change.",
    callback = function()
        vim.cmd.update({ mods = { emsg_silent = true } })
    end,
})

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

if not vim.env.TMUX then
    return
else
    local tmux = require("utils.tmux")
    if tmux.tmux_get_pane_opt("@is_vim") == "" then
        tmux.tmux_exec(string.format("set -pt %s %s '%s'", vim.env.TMUX_PANE, "@is_vim", vim.fn.escape("yes", "'\\")))
        local groupid = vim.api.nvim_create_augroup("TmuxNavSetIsVim", {})
        vim.api.nvim_create_autocmd("VimResume", {
            desc = "Set @is_vim in tmux pane options after vim resumes.",
            group = groupid,
            callback = function()
                tmux.tmux_exec(string.format("set -pt %s %s '%s'", vim.env.TMUX_PANE, "@is_vim", vim.fn.escape("yes", "'\\")))
            end,
        })
        vim.api.nvim_create_autocmd({ "VimSuspend", "VimLeave" }, {
            desc = "Unset @is_vim in tmux pane options on vim leaving or suspending.",
            group = groupid,
            callback = function()
                tmux.tmux_exec(string.format("set -put %s '%s'", vim.env.TMUX_PANE, vim.fn.escape("@is_vim", "'\\")))
            end,
        })
    end
end
