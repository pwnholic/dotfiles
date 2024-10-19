return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            {
                "rcarriga/nvim-dap-ui",
                opts = {
                    layouts = {
                        {
                            elements = {
                                { id = "watches", size = 0.25 },
                                { id = "scopes", size = 0.25 },
                                { id = "stacks", size = 0.25 },
                                { id = "breakpoints", size = 0.25 },
                            },
                            position = "right",
                            size = 60,
                        },
                        {
                            elements = {
                                { id = "repl", size = 0.55 },
                                { id = "console", size = 0.45 },
                            },
                            position = "bottom",
                            size = 7,
                        },
                    },
                },
            },
            {
                "theHamsta/nvim-dap-virtual-text",
                opts = {
                    enabled_commands = true,
                    all_frames = true,
                    virt_text_pos = "eol",
                },
            },
        },
    },
}
