local function cabbrev(trig, command, opts)
    if type(trig) == "table" then
        local trig_short = trig[1]
        local trig_full = trig[2]
        for i = #trig_short, #trig_full do
            local cmd_part = trig_full:sub(1, i)
            cabbrev(cmd_part, command, opts)
        end
        return
    end

    vim.keymap.set("c", trig, function()
        if vim.fn.getcmdtype() == ":" and vim.fn.getcmdcompltype() == "command" then
            return command
        end
        return trig
    end, vim.tbl_deep_extend("keep", { expr = true }, opts or {}))
end

cabbrev("git", "Git")
