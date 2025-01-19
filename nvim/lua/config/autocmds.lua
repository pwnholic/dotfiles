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
                pcall(vim.cmd.lcd, {
                    LazyVim.root() or vim.uv.cwd(),
                    mods = { silent = true, emsg_silent = true },
                })
            end)
        end
    end,
})

---Set abbreviation that only expand when the trigger is at the position of
---a command
---@param trig string|{ [1]: string, [2]: string }
---@param command string
---@param opts table?
local function command_abbrev(trig, command, opts)
    if type(trig) == "table" then
        local trig_short = trig[1]
        local trig_full = trig[2]
        for i = #trig_short, #trig_full do
            local cmd_part = trig_full:sub(1, i)
            command_abbrev(cmd_part, command)
        end
        return
    end
    vim.keymap.set("ca", trig, function()
        return vim.fn.getcmdcompltype() == "command" and command or trig
    end, vim.tbl_deep_extend("keep", { expr = true }, opts or {}))
end

vim.api.nvim_create_autocmd("CmdlineEnter", {
    once = true,
    callback = function()
        command_abbrev("git", "Git")
        return true
    end,
})

-- vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "FocusLost" }, {
--     nested = true,
--     desc = "Autosave on focus change.",
--     callback = function(info)
--         if (vim.uv.fs_stat(info.file) or {}).type ~= "file" then
--             return
--         end
--         vim.cmd.update({ mods = { emsg_silent = true } })
--     end,
-- })

vim.api.nvim_create_autocmd("CmdwinEnter", {
    group = vim.api.nvim_create_augroup("execute_cmd_and_stay", { clear = true }),
    desc = "Execute command and stay in the command-line window",
    callback = function(args)
        vim.keymap.set({ "n", "i" }, "<S-CR>", "<cr>q:", { buffer = args.buf })
    end,
})
