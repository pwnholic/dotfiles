local autocmd, augroup = vim.api.nvim_create_autocmd, vim.api.nvim_create_augroup

autocmd({ "BufLeave", "WinLeave", "FocusLost" }, {
    nested = true,
    desc = "Autosave on focus change.",
    callback = function(args)
        vim.uv.fs_stat(args.file, function(err, stat)
            if err or not stat or stat.type ~= "file" then
                return
            end
            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(args.buf) then
                    return
                end
                vim.api.nvim_buf_call(args.buf, function()
                    vim.cmd.update({
                        mods = { emsg_silent = true },
                    })
                end)
            end)
        end)
    end,
})

autocmd({ "BufLeave", "FocusLost", "InsertEnter", "CmdlineEnter", "WinLeave" }, {
    group = augroup("ToggleRelativeLineNumbers", { clear = true }),
    desc = "Toggle relative line numbers off",
    callback = function(args)
        if vim.wo.nu then
            vim.wo.relativenumber = false
        end

        -- Redraw here to avoid having to first write something for the line numbers to update.
        if args.event == "CmdlineEnter" then
            if not vim.tbl_contains({ "@", "-" }, vim.v.event.cmdtype) then
                vim.cmd.redraw()
            end
        end
    end,
})
