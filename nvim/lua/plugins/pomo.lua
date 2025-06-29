return {
    "pwnholic/pomo.nvim",
    cmd = { "TimerStart", "TimerRepeat", "TimerSession" },
    dependencies = {
        {
            "nvim-lualine/lualine.nvim",
            opts = function(_, opts)
                table.insert(opts.sections.lualine_x, {
                    function()
                        local ok, pomo = pcall(require, "pomo")
                        if not ok then
                            return ""
                        end
                        local timer = pomo.get_first_to_finish()
                        if timer == nil then
                            return ""
                        end
                        return string.format("󰣠  %s", tostring(timer))
                    end,
                    color = "PomoTimer",
                })
            end,
        },
    },
    keys = {
        {
            "<leader>ps",
            function()
                vim.ui.select({
                    "New Custom Timer",
                    "Focus Coding (50/10)",
                    "Deep Work (90/15)",
                    "Learning Session (40/10)",
                }, { prompt = "Pilih Jenis Timer:" }, function(item, idx)
                    if idx == 1 then
                        vim.ui.input({ prompt = "Masukkan timer kustom (contoh: 30m Project X):" }, function(input)
                            if input and input ~= "" then
                                local newArgs = vim.split(input, " ")
                                vim.cmd.TimerStart({ args = { newArgs[1], table.concat(newArgs, " ", 2) } })
                            end
                        end)
                    else
                        local session_map = {
                            ["Focus Coding (50/10)"] = "focus_coding",
                            ["Deep Work (90/15)"] = "deep_work",
                            ["Learning Session (40/10)"] = "learning_session",
                        }
                        local session_key = session_map[item]
                        if session_key then
                            if string.find(session_key, "m ") then
                                local args = vim.split(item, " ")
                                vim.cmd.TimerStart({ args = { args[1], table.concat(args, " ", 2) } })
                            else
                                vim.cmd.TimerSession({ args = { session_key } })
                            end
                        end
                    end
                end)
            end,
            desc = "Start a new timer",
        },
    },
    opts = {
        notifiers = {
            { name = "Default", opts = { sticky = false } },
            { name = "System" },
        },
        timers = {
            Break = {
                { name = "System" },
            },
        },
        sessions = {
            focus_coding = {
                { name = "Coding Focus", duration = "50m" },
                { name = "Break", duration = "10m" },
                { name = "Coding Focus", duration = "50m" },
                { name = "Break", duration = "10m" },
                { name = "Coding Focus", duration = "50m" },
                { name = "Long Break", duration = "20m" },
            },
            deep_work = {
                { name = "Deep Work", duration = "90m" },
                { name = "Long Break", duration = "15m" },
                { name = "Deep Work", duration = "90m" },
                { name = "Long Break", duration = "30m" },
            },
            learning_session = {
                { name = "Learning/Research", duration = "40m" },
                { name = "Short Break", duration = "10m" },
                { name = "Learning/Research", duration = "40m" },
                { name = "Short Break", duration = "10m" },
                { name = "Learning/Research", duration = "40m" },
                { name = "Long Break", duration = "15m" },
            },
        },
    },
}
