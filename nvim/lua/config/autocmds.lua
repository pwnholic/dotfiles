vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "FocusLost" }, {
    nested = true,
    desc = "Autosave on focus change.",
    callback = function()
        vim.cmd.update({ mods = { emsg_silent = true } })
    end,
})
