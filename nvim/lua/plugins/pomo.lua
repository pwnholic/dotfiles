return {
    "epwalsh/pomo.nvim",
    version = false,
    cmd = { "TimerStart", "TimerRepeat", "TimerSession" },
    opts = {
        notifiers = {
            { name = "Default", opts = { sticky = false } },
        },
        sessions = {
            pomodoro = {
                { name = "Work", duration = "25m" },
                { name = "Short Break", duration = "5m" },
                { name = "Work", duration = "25m" },
                { name = "Short Break", duration = "5m" },
                { name = "Work", duration = "25m" },
                { name = "Long Break", duration = "15m" },
            },
        },
    },
}
