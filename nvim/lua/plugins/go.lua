return {
    "ray-x/go.nvim",
    ft = { "go", "gomod" },
    keys = {
        { "<leader>js", "<cmd>GoFillStruct<cr>", desc = "Fill Struct", ft = "go" },
        { "<leader>jp", "<cmd>GoFixPlurals<cr>", desc = "Fix Plurals", ft = "go" },
        { "<leader>jS", "<cmd>GoFillSwitch<cr>", desc = "Fill Switch", ft = "go" },
        { "<leader>jd", "<cmd>GoModTidy<cr>", desc = "`go mod tidy`", ft = "go" },
        { "<leader>jI", "<cmd>GoModVendor<cr>", desc = "`go mod vendor`", ft = "go" },
        {
            "<leader>ji",
            function()
                vim.ui.input({ prompt = "Enter {r *receiver} -> {interface} : " }, function(input)
                    if input ~= "" then
                        vim.cmd(string.format("GoImpl %s", input))
                    end
                end)
            end,
            desc = "Implement Method",
            ft = "go",
        },
        {
            "<leader>jt",
            function()
                vim.ui.select({ "Add", "Clear", "Remove" }, {
                    prompt = "Modify Tags Option:",
                }, function(choice)
                    if choice == "Add" then
                        vim.ui.input({ prompt = "Input Tags to Add: " }, function(input)
                            if input ~= nil then
                                vim.cmd(string.format("GoModifyTag -add-tags %s", input))
                            end
                        end)
                    elseif choice == "Remove" then
                        vim.ui.input({ prompt = "Input Tags to Remove : " }, function(input)
                            if input ~= nil then
                                vim.cmd(string.format("GoModifyTag -remove-tags %s", input))
                            end
                        end)
                    elseif choice == "Clear" then
                        vim.ui.input({ prompt = "Input Tags to Clear : " }, function(input)
                            if input ~= nil then
                                vim.cmd(string.format("GoModifyTag -clear-tags %s", input))
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
        goimports = "goimports",
        lsp_keymaps = false,
        lsp_cfg = true,
        icons = false,
        trouble = true,
        tag_transform = "snakecase",
        tag_options = "json=",
        dap_debug_keymap = false,
        dap_debug = false,
        null_ls = false,
        lsp_inlay_hints = { enable = false },
        diagnostic = {
            underline = true,
            update_in_insert = false,
            virtual_text = { spacing = 4, source = "if_many", prefix = " " },
            severity_sort = true,
            float = { border = vim.g.border },
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
                    [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
                    [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
                    [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
                },
            },
        },
        go_input = vim.ui.input,
        go_select = vim.ui.select,
    },
}
