---@diagnostic disable: undefined-field

vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "FocusLost" }, {
    nested = true,
    desc = "Autosave on focus change.",
    callback = function(ev)
        if (vim.uv.fs_stat(ev.file) or {}).type ~= "file" then
            return
        end
        vim.cmd.update({ mods = { emsg_silent = true } })
    end,
})

local view_group = vim.api.nvim_create_augroup("auto_view", { clear = true })
vim.api.nvim_create_autocmd({ "BufWinLeave", "BufWritePost", "WinLeave" }, {
    desc = "Save view with mkview for real files",
    group = view_group,
    callback = function(args)
        if vim.b[args.buf].view_activated then
            vim.cmd.mkview({ mods = { emsg_silent = true } })
        end
    end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    desc = "Try to load file view if available and enable view saving for real files",
    group = view_group,
    callback = function(args)
        if not vim.b[args.buf].view_activated then
            local filetype = vim.bo[args.buf].filetype
            local buftype = vim.bo[args.buf].buftype
            local ignore_filetypes = { "gitcommit", "gitrebase", "svg", "hgcommit" }
            if buftype == "" and filetype and filetype ~= "" and not vim.tbl_contains(ignore_filetypes, filetype) then
                vim.b[args.buf].view_activated = true
                vim.cmd.loadview({ mods = { emsg_silent = true } })
            end
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
        command_abbrev("gcm", "GitCommitMsg")
        return true
    end,
})

vim.api.nvim_create_autocmd("BufRead", {
    callback = function(ev)
        if vim.bo[ev.buf].buftype == "quickfix" then
            vim.schedule(function()
                vim.cmd([[cclose]])
                vim.cmd([[Trouble qflist open]])
            end)
        end
    end,
})
