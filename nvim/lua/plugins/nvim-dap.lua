return {
    "mfussenegger/nvim-dap",
    opts = function()
        local dap = require("dap")
        dap.defaults.fallback.external_terminal = {
            command = "/usr/bin/kitty",
            args = { "-e" },
        }
    end,
    dependencies = {
        {
            "rcarriga/nvim-dap-ui",
            opts = {

                controls = {
                    element = "repl",
                    enabled = true,
                    icons = {
                        disconnect = "  ",
                        pause = "  ",
                        play = "  ",
                        run_last = "  ",
                        step_back = "  ",
                        step_into = "  ",
                        step_out = "  ",
                        step_over = "  ",
                        terminate = "  ",
                    },
                },
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
                        size = 58,
                    },
                    {
                        elements = {
                            { id = "repl", size = 0.5 },
                            { id = "console", size = 0.5 },
                        },
                        position = "bottom",
                        size = 7,
                    },
                },
            },
        },
        {
            "nvim-dap-virtual-text",
            opts = {
                virt_text_pos = "inline",
                all_frames = true,
                ---@diagnostic disable-next-line: unused-local
                display_callback = function(variable, buf, stackframe, node, options)
                    local trim_value = variable.value:gsub("%s+", " ")
                    if options.virt_text_pos == "inline" then
                        if #variable.value > 15 then
                            return string.format(" %s... ", string.sub(trim_value, 1, 15))
                        end
                        return string.format(" %s ", trim_value)
                    end
                end,
            },
        },
    },
    keys = {
        { "<leader>dn", "<cmd>DapNew<cr>", desc = "Set Config" },
        { "<leader>dx", "<cmd>DapClearBreakpoints<cr>", desc = "Clear all breakpoints" },
        {
            "<leader>dr",
            function()
                require("dap").repl.toggle({}, "vsplit")
            end,
            desc = "REPL Vertical",
        },
        {
            "<leader>dR",
            function()
                require("dap").repl.toggle()
            end,
            desc = "REPL Horizontal",
        },
        {
            "<F1>",
            function()
                require("dap").up()
            end,
            "Stack up",
        },
        {
            "<F2>",
            function()
                require("dap").down()
            end,
            "Stack down",
        },
        {
            "<F5>",
            function()
                require("dap").continue()
            end,
            "Continue program execution",
        },
        {
            "<F6>",
            function()
                require("dap").pause()
            end,
            "Pause program execution",
        },
        {
            "<F8>",
            function()
                require("dap").repl.open()
            end,
            "Open debug REPL",
        },
        {
            "<F9>",
            function()
                require("dap").toggle_breakpoint()
            end,
            "Toggle breakpoint",
        },
        {
            "<F10>",
            function()
                require("dap").step_over()
            end,
            "Step over",
        },
        {
            "<F11>",
            function()
                require("dap").step_into()
            end,
            "Step into",
        },
        {
            "<F17>",
            function()
                require("dap").terminate()
            end,
            "Terminate debug session",
        },
        {
            "<F23>",
            function()
                require("dap").step_out()
            end,
            "Step out",
        },
        {
            "<F41>",
            function()
                require("dap").restart()
            end,
            "Restart debug session",
        },
        {
            "<F21>",
            function()
                require("dap").set_breakpoint(nil, vim.fn.input("Breakpoint condition: "))
            end,
            "Set conditional breakpoint",
        },
        {
            "<F45>",
            function()
                require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
            end,
            "Set logpoint",
        },
    },
}
