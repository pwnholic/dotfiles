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
                                { id = "scopes", size = 0.25 },
                                { id = "breakpoints", size = 0.25 },
                                { id = "stacks", size = 0.25 },
                                { id = "watches", size = 0.25 },
                            },
                            position = "right",
                            size = 45,
                        },
                        {
                            elements = {
                                { id = "repl", size = 0.55 },
                                { id = "console", size = 0.45 },
                            },
                            position = "bottom",
                            size = 8,
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
