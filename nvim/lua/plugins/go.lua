return {
    {
        "ray-x/go.nvim",
        ft = { "go", "gomod" },
        dependencies = { "ray-x/guihua.lua" },
        keys = {
            { "<leader>jf", "<cmd>GoFillStruct<cr>", desc = "Fill struct with default values", ft = "go" },
            { "<leader>js", "<cmd>GoFillSwitch<cr>", desc = "Fill switch statement with cases", ft = "go" },
            { "<leader>je", "<cmd>GoIfErr<cr>", desc = "Add if err != nil block", ft = "go" },
            { "<leader>jp", "<cmd>GoFixPlurals<cr>", desc = "Fix plural variable names", ft = "go" },
            { "<leader>jc", "<cmd>GoClearTag<cr>", desc = "Clear all struct tags", ft = "go" },
            { "<leader>ji", "<cmd>GoImports<cr>", desc = "Organize Go imports", ft = "go" },
            { "<leader>jt", "<cmd>GoModTidy<cr>", desc = "Run go mod tidy", ft = "go" },
            {
                "<leader>ja",
                function()
                    vim.ui.input({ prompt = "Add struct tags" }, function(input)
                        if input == "" then
                            return vim.notify("Empty input tags", "info", { title = "Go tags" })
                        end
                        return vim.cmd.GoAddTag({ args = { input:gsub("^%s+", ""):gsub("%s+$", "") } })
                    end)
                end,
                desc = "Add struct tags",
                ft = "go",
            },
            {
                "<leader>jr",
                function()
                    vim.ui.input({ prompt = "Remove struct tags" }, function(input)
                        if input == "" then
                            return vim.notify("Empty input tags", "info", { title = "Go tags" })
                        end
                        return vim.cmd.GoRmTag({ args = { input:gsub("^%s+", ""):gsub("%s+$", "") } })
                    end)
                end,
                desc = "Remove struct tags",
                ft = "go",
            },
            {
                "<leader>ji",
                function()
                    vim.ui.input({ prompt = "Go Impl {receiver} {interface}" }, function(input)
                        if input == "" then
                            return vim.notify("Empty input tags", "info", { title = "Go tags" })
                        end
                        return vim.cmd.GoImpl({ args = { input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ") } })
                    end)
                end,
                desc = "Implement interface methods for receiver",
                ft = "go",
            },
        },
        opts = {
            gopls_cmd = { vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin", "gopls") },
            gopls_remote_auto = false,
            lsp_cfg = true,
            dap_debug = false,
            dap_debug_keymap = false,
            textobjects = false,
            trouble = true,
            lsp_document_formatting = false,
            lsp_keymaps = false,
            icons = false,
            tag_options = table.concat({
                "json=omitempty",
                "validate=required",
                "binding=required",
            }, ","),
            --                               tag_transform = "camelcase",
            tag_transform = "snakecase",
            lsp_semantic_highlights = true,
            go_input = vim.ui.input,
            go_select = vim.ui.select,
            lsp_inlay_hints = { enable = false },
            diagnostic = {
                hdlr = true,
                underline = true,
                update_in_insert = false,
                virtual_text = {
                    spacing = 4,
                    source = "if_many",
                    prefix = "●",
                },
                severity_sort = true,
                float = {
                    border = vim.g.border,
                },
                signs = {
                    linehl = {
                        [vim.diagnostic.severity.ERROR] = "ErrorMsg",
                    },
                    numhl = {
                        [vim.diagnostic.severity.WARN] = "WarningMsg",
                    },
                    text = {
                        [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
                        [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
                        [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
                        [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
                    },
                },
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        ft = { "go", "gomod" },
        opts = {
            setup = {
                gopls = function()
                    return true
                end,
            },
        },
    },
}
