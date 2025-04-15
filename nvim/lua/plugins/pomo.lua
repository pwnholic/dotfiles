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
