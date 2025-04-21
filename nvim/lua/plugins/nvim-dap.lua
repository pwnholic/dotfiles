return {
    "mfussenegger/nvim-dap",
    keys = {
        {
            "<F5>",
            function()
                return require("dap").continue()
            end,
            desc = "Continue",
        },
        {
            "<C-F5>",
            function()
                return require("dap").run_last()
            end,
            desc = "Run Last",
        },
        {
            "<S-F5>",
            function()
                return require("dap").stop()
            end,
            desc = "Stop",
        },
        {
            "<C-S-F5>",
            function()
                return require("dap").pause()
            end,
            desc = "Pause",
        },
        {
            "<F11>",
            function()
                return require("dap").step_into()
            end,
            desc = "Step Into",
        },
        {
            "<F10>",
            function()
                return require("dap").step_over()
            end,
            desc = "Step Over",
        },
        {
            "<S-F11>",
            function()
                return require("dap").step_out()
            end,
            desc = "Setp Out",
        },
        {
            "<F9>",
            function()
                return require("dap").toggle_breakpoint()
            end,
            desc = "Toggle Breakpoint",
        },
        {
            "<C-S-D>",
            function()
                return require("dap").repl.open()
            end,
            desc = "Open REPL",
        },
        {
            "<A-F11>",
            function()
                return require("dap").step_into()
            end,
            desc = "Step Into",
        },
        {
            "<C-S-P>",
            function()
                return require("dap.ui.widgets").hover()
            end,
            desc = "Hover",
        },
    },
    dependencies = {
        {
            "rcarriga/nvim-dap-ui",
            opts = {
                expand_lines = false,
                layouts = {
                    {
                        elements = {
                            { id = "scopes", size = 0.25 },
                            { id = "breakpoints", size = 0.25 },
                            { id = "stacks", size = 0.25 },
                            { id = "watches", size = 0.25 },
                        },
                        position = "right",
                        size = math.floor(vim.o.columns / 2.5),
                    },
                    {
                        elements = {
                            { id = "repl", size = 0.5 },
                            { id = "console", size = 0.5 },
                        },
                        position = "bottom",
                        size = math.floor(vim.o.lines / 3.5),
                    },
                },
            },
        },
        {
            "theHamsta/nvim-dap-virtual-text",
            opts = {
                display_callback = function(variable)
                    local name = string.lower(variable.name)
                    local value = string.lower(variable.value)
                    if name:match("secret") or name:match("api") or value:match("secret") or value:match("api") then
                        return "*****"
                    end
                    if #variable.value > 15 then
                        return " " .. string.sub(variable.value, 1, 15) .. "... "
                    end
                    return " " .. variable.value
                end,
            },
        },
    },
}
