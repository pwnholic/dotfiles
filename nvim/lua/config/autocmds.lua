-- local group = vim.api.nvim_create_augroup("InlayHintsNormalModeOnly", { clear = true })
--
-- vim.api.nvim_create_autocmd("ModeChanged", {
--     group = group,
--     pattern = "*:*",
--     desc = "Enable inlay hints only in normal mode",
--     callback = function(args)
--         local bufnr = args.buf
--         local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/inlayHint" })
--
--         if vim.api.nvim_buf_is_valid(bufnr) and #clients > 0 and next(clients) then
--             vim.lsp.inlay_hint.enable(args.match:sub(3, 3) == "n", { bufnr = bufnr })
--         end
--     end,
-- })

vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "FocusLost" }, {
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
                    vim.cmd.update({ mods = { emsg_silent = true } })
                end)
            end)
        end)
    end,
})

local function command_abbrev(trig, command, opts)
    local keymap_opts = vim.tbl_extend("keep", opts or {}, { expr = true })
    if type(trig) == "table" then
        local short, full = trig[1], trig[2]
        for i = #short, #full do
            command_abbrev(full:sub(1, i), command, opts)
        end
        return
    end
    vim.keymap.set("ca", trig, function()
        return vim.fn.getcmdcompltype() == "command" and command or trig
    end, keymap_opts)
end

vim.api.nvim_create_autocmd("CmdlineEnter", {
    once = true,
    callback = function()
        -- Basic Git
        command_abbrev("git", "Git")
        command_abbrev("gst", "Git status")
        command_abbrev("gdf", "Git diff")
        command_abbrev("gds", "Git diff --staged")

        -- Add & Commit
        command_abbrev("gad", "Git add")
        command_abbrev("gadd", "Git add %")
        command_abbrev("gaa", "Git add .")
        command_abbrev("gcm", "Git commit")
        command_abbrev("gcmm", "Git commit -m")

        -- Push & Pull
        command_abbrev("gps", "Git push")
        command_abbrev("gpl", "Git pull --rebase")

        -- Log
        command_abbrev("glg", "Git log --oneline --graph --decorate")
        command_abbrev("glgs", "Git log --stat")
        command_abbrev("glga", "Git log --oneline --graph --decorate --all")
        command_abbrev("glgf", "Git log -p -1")

        -- Branch
        command_abbrev("gbr", "Git branch")
        command_abbrev("gco", "Git checkout")
        command_abbrev("gcob", "Git checkout -b")
        command_abbrev("gmg", "Git merge")

        -- Reset & Restore
        command_abbrev("grh", "Git reset --hard")
        command_abbrev("gre", "Git restore")
        command_abbrev("gres", "Git restore --staged")

        -- Amend & Fixup
        command_abbrev("gcam", "Git commit --amend --no-edit")
        command_abbrev("gcamm", "Git commit --amend")
        command_abbrev("gfu", "Git commit --fixup")

        -- Rebase
        command_abbrev("gri", "Git rebase -i")
        command_abbrev("grbc", "Git rebase --continue")
        command_abbrev("grbs", "Git rebase --skip")
        command_abbrev("grba", "Git rebase --abort")

        -- Cherry Pick
        command_abbrev("gcp", "Git cherry-pick")
        command_abbrev("gcpc", "Git cherry-pick --continue")
        command_abbrev("gcpa", "Git cherry-pick --abort")

        -- Stash
        command_abbrev("gsta", "Git stash")
        command_abbrev("gstaa", "Git stash apply")
        command_abbrev("gstp", "Git stash pop")
        command_abbrev("gstl", "Git stash list")
        command_abbrev("gstd", "Git stash drop")

        -- Tag
        command_abbrev("gtg", "Git tag")
        command_abbrev("gtgm", "Git tag -m")
        command_abbrev("gtgd", "Git tag -d")

        -- Blame & Inspect
        command_abbrev("gbl", "Git blame")
        command_abbrev("gsh", "Git show")
        command_abbrev("gshh", "Git show HEAD")

        -- Worktree
        command_abbrev("gwt", "Git worktree")
        command_abbrev("gwtl", "Git worktree list")
        command_abbrev("gwta", "Git worktree add")
        command_abbrev("gwtr", "Git worktree remove")

        -- Bisect
        command_abbrev("gbs", "Git bisect start")
        command_abbrev("gbsg", "Git bisect good")
        command_abbrev("gbsb", "Git bisect bad")
        command_abbrev("gbsr", "Git bisect reset")

        -- Clean
        command_abbrev("gcln", "Git clean -fd")
        command_abbrev("gclnn", "Git clean -fdn")
    end,
})
