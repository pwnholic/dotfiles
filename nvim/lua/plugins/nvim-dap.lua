return {
    {
        "mfussenegger/nvim-dap",
        opts = function()
            local dap = require("dap")
            dap.defaults.fallback.external_terminal = { command = "/usr/bin/kitty", args = { "-e" } }
            local repl = require("dap.repl")
            repl.commands = vim.tbl_extend("force", repl.commands, {
                locals = { ".scopes" },
                custom_commands = {
                    [".echo"] = function(text)
                        return dap.repl.append(text)
                    end,
                    [".terminate"] = function()
                        return dap.terminate({
                            terminate_args = { restart = true },
                            disconnect_args = { restart = true },
                        })
                    end,
                },
            })
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
                                { id = "scopes", size = 1 / 3 },
                                { id = "breakpoints", size = 1 / 3 },
                                { id = "stacks", size = 1 / 3 },
                                -- { id = "watches", size = 0.25 },
                            },
                            position = "right",
                            size = math.floor(vim.o.columns / 3),
                        },
                        {
                            elements = {
                                { id = "repl", size = 1 },
                                -- { id = "console", size = 1 / 2 },
                            },
                            position = "bottom",
                            size = math.floor(vim.o.lines / 4),
                        },
                    },
                },
            },
            {
                "theHamsta/nvim-dap-virtual-text",
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
            {
                "K",
                function()
                    local widgets = require("dap.ui.widgets")
                    widgets.centered_float(widgets.frames, { width = vim.o.columns, height = vim.o.lines })
                end,
                ft = "dapui_scopes",
            },
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
                "<leader>dx",
                function()
                    require("dap-utils").clear_breakpoints()
                    require("dap-utils").remove_watches()
                end,
                desc = "Clear all breakpoints",
            },
            {
                "<F17>",
                function()
                    local choice = vim.fn.confirm("Terminate program?", "&Cancel\n&Yes\n&No", 1)
                    if choice == 2 then
                        require("dap").terminate()
                    elseif choice == 3 then
                        require("dap").disconnect()
                        require("dap").close()
                    else
                        return
                    end
                    require("dapui").close({})
                    require("dap.repl").close({})
                    require("nvim-dap-virtual-text/virtual_text").clear_virtual_text()
                end,
                "Terminate debug session",
            },
            {
                "<F21>", -- SHIFT + F9
                function()
                    local types = { "log point", "conditional breakpoint", "exception breakpoint" }
                    vim.ui.select(types, {
                        prompt = "Select Breakpoint Types",
                    }, function(choice)
                        if choice == types[1] then
                            require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
                        elseif choice == types[2] then
                            require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "), vim.fn.input("Hit times: "))
                        elseif choice == types[3] then
                            require("dap").set_exception_breakpoints()
                        end
                    end)
                end,
                "Set Breakpoint",
            },
        },
    },
}
