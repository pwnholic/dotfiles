return {
    {
        "ray-x/go.nvim",
        ft = { "go", "gomod" },
        keys = {
            { "<leader>js", "<cmd>GoFillStruct<cr>", desc = "Fill Struct", ft = "go" },
            { "<leader>jp", "<cmd>GoFixPlurals<cr>", desc = "Fix Plurals", ft = "go" },
            { "<leader>jS", "<cmd>GoFillSwitch<cr>", desc = "Fill Switch", ft = "go" },
            { "<leader>jD", "<cmd>GoModTidy<cr>", desc = "`go mod tidy`", ft = "go" },
            { "<leader>jI", "<cmd>GoModVendor<cr>", desc = "`go mod vendor`", ft = "go" },
            {
                "<leader>ji",
                function()
                    vim.ui.input({ prompt = "Impl {r *receiver} -> {interface} : " }, function(input)
                        if input ~= "" then
                            return vim.cmd(string.format("GoImpl %s", input))
                        end
                    end)
                end,
                desc = "Implement Method",
                ft = "go",
            },
            {
                "<leader>jt",
                function()
                    local actions = {
                        Add = "-add-tags",
                        Remove = "-remove-tags",
                        Clear = "-clear-tags",
                    }
                    vim.ui.select(vim.tbl_keys(actions), { prompt = "Modify Tags Option:" }, function(choice)
                        if choice then
                            vim.ui.input({ prompt = "Input Tags: " }, function(input)
                                if input and input ~= "" then
                                    vim.cmd(string.format("GoModifyTag %s %s", actions[choice], input))
                                end
                            end)
                        end
                    end)
                end,
                desc = "Modify Tag",
                ft = "go",
            },
        },
        opts = {
            lsp_keymaps = false,
            lsp_cfg = false,
            icons = false,
            trouble = false,
            tag_transform = "snakecase",
            tag_options = "json=",
            dap_debug_keymap = false,
            dap_debug = false,
            null_ls = false,
            lsp_inlay_hints = { enable = false },
            diagnostic = false,
            go_input = vim.ui.input,
            go_select = vim.ui.select,
        },
    },
}
