return {
    "ray-x/go.nvim",
    branch = "master",
    ft = { "go", "gomod" },
    keys = {
        { "<A-g>s", "<cmd>GoFillStruct<cr>", desc = "Fill Struct", ft = "go" },
        { "<A-g>p", "<cmd>GoFixPlurals<cr>", desc = "Fix Plurals", ft = "go" },
        { "<A-g>S", "<cmd>GoFillSwitch<cr>", desc = "Fill Switch", ft = "go" },
        { "<A-g>t", "<cmd>GoModTidy<cr>", desc = "go mod tidy", ft = "go" },
        { "<A-g>I", "<cmd>GoModVendor<cr>", desc = "go mod vendor", ft = "go" },
        {
            "<A-g>i",
            function()
                vim.ui.input({ prompt = "Enter {r *reciver} -> {interface} : " }, function(input)
                    if input ~= "" then
                        local command = string.format("GoImpl %s", input)
                        vim.cmd(command)
                    end
                end)
            end,
            desc = "Go Implement",
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
        null_ls = false,
        lsp_inlay_hints = { enable = false },
        diagnostic = {
            underline = true,
            update_in_insert = false,
            virtual_text = {
                spacing = 4,
                source = "if_many",
                prefix = "●",
            },
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
