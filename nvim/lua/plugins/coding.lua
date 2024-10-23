return {
    {
        "mfussenegger/nvim-dap",
        keys = {
            "<F1>",
            "<F2>",
            "<F5>",
            "<F6>",
            "<F8>",
            "<F9>",
            "<F10>",
            "<F11>",
            "<F17>", -- shift + f5
            "<F23>", -- shift + f11
            "<F41>", -- ctrl + shift + f5
            "<F21>", -- shift + f9
            "<F45>", -- ctrl + shift + f9
        },
        opts = function()
            local dap = require("dap")
            local keymap = require("utils.keys")

            local last_dap_fn = function() end
            local function set_logpoint()
                dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
            end

            local function set_cond_breakpoint()
                dap.set_breakpoint(nil, vim.fn.input("Breakpoint condition: "))
            end

            local function wrap(fn)
                return function()
                    last_dap_fn = fn
                    fn()
                end
            end

            local keymaps = {
                ["<F1>"] = { fn = dap.up, desc = "Up" },
                ["<F2>"] = { fn = dap.down, desc = "Down" },
                ["<F5>"] = { fn = dap.continue, desc = "Continue" },
                ["<F6>"] = { fn = dap.pause, desc = "Pause" },
                ["<F8>"] = { fn = dap.repl.open, desc = "Open REPL" },
                ["<F9>"] = { fn = dap.toggle_breakpoint, desc = "Toggle Breakpoint" },
                ["<F10>"] = { fn = dap.step_over, desc = "Step Over" },
                ["<F11>"] = { fn = dap.step_into, desc = "Step Into" },
                ["<F17>"] = { fn = dap.terminate, desc = "Terminate Session" },
                ["<F23>"] = { fn = dap.step_out, desc = "Step Out" },
                ["<F41>"] = { fn = dap.restart, desc = "Restart Session" },
                ["<F21>"] = { fn = set_cond_breakpoint, desc = "Set Breakpoint Cond" },
                ["<F45>"] = { fn = set_logpoint, desc = "Set Logpoint" },
            }

            for key, map in pairs(keymaps) do
                vim.keymap.set("n", key, wrap(map.fn), { desc = map.desc })
            end

            keymap.amend("n", "<CR>", function(fallback)
                if dap.session() then
                    last_dap_fn()
                    return
                end
                fallback()
            end)

            vim.api.nvim_create_user_command("DapClear", dap.clear_breakpoints, { desc = "Clear all breakpoints" })
        end,
        dependencies = {
            {
                "rcarriga/nvim-dap-ui",
                keys = {
                    {
                        "<F16>",
                        function()
                            require("dapui").float_element(vim.o.filetype:gsub("dapui_", ""), {
                                width = vim.o.columns,
                                height = vim.o.lines,
                                title = vim.o.filetype:gsub("dapui_", ""):upper(),
                                enter = true,
                                position = "center",
                            })
                        end,
                        ft = { "dapui_watches", "dapui_scopes", "dapui_breakpoints", "dapui_stacks" },
                        desc = "Float Element",
                    },
                    {
                        "K",
                        function()
                            require("dapui").eval()
                        end,
                        ft = { "dapui_watches", "dapui_scopes", "dapui_breakpoints", "dapui_stacks" },
                        desc = "Eval",
                    },
                },
                opts = {
                    expand_lines = false,
                    floating = {
                        border = "single",
                        mappings = { close = { "q", "<Esc>" } },
                    },
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
    {
        "williamboman/mason.nvim",
        opts = {
            ensure_installed = {},
        },
    },
}
