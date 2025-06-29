return {
    "epwalsh/pomo.nvim",
    version = false,
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
                vim.ui.select(
                    { "New Timer", "25m Learn", "45m Work" },
                    { prompt = "Chouse yout timer" },
                    function(item, idx)
                        if idx == 1 then
                            vim.ui.input({ prompt = "Input your custom timer {timer} {name}" }, function(input)
                                if input and input ~= "" then
                                    local newArgs = vim.split(input, " ")
                                    vim.cmd.TimerStart({ args = { newArgs[1], newArgs[2] } })
                                end
                            end)
                        elseif idx > 1 then
                            local args = vim.split(item, " ")
                            vim.cmd.TimerStart({ args = { args[1], args[2] } })
                        end
                    end
                )
            end,
            desc = "Start a new timer",
        },
    },
    opts = {
        notifiers = {
            { name = "Default", opts = { sticky = false } },
        },
        sessions = {
            work = {
                { name = "Work", duration = "30m" },
                { name = "Microbreak", duration = "5m" },
                { name = "Work", duration = "30m" },
                { name = "Microbreak", duration = "5m" },
                { name = "Work", duration = "30m" },
                { name = "Long Break", duration = "10m" },
            },
        },
    },
}
