return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            inlay_hints = { enabled = false, exclude = {} },
            servers = {
                solidity_ls = {},
                zls = {},
                kulala_ls = {},
                bashls = {},
                templ = {},
                fish_lsp = {},
            },
            setup = {
                gopls = function()
                    return true
                end,
            },
            diagnostics = {
                underline = true,
                update_in_insert = false,
                severity_sort = true,
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
                        [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
                        [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
                        [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
                    },
                    numhl = {
                        [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
                        [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
                        [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
                        [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
                    },
                },
                virtual_text = { spacing = 4, source = "if_many", prefix = "󰈸 " },
                float = {
                    header = setmetatable({}, {
                        __index = function(_, k)
                            local icon, icons_hl = require("mini.icons").get("file", vim.api.nvim_buf_get_name(0))
                            return ({ string.format("Diagnostics: %s  %s", icon, vim.bo.filetype), icons_hl })[k]
                        end,
                    }),
                    format = function(d)
                        return string.format("[%s] : %s", d.source, d.message)
                    end,
                    source = "if_many",
                    severity_sort = true,
                    wrap = true,
                    border = "single",
                    max_width = math.floor(vim.o.columns / 2),
                    max_height = math.floor(vim.o.lines / 3),
                },
            },
        },
    },
    {
        "conform.nvim",
        opts = {
            formatters_by_ft = {
                templ = { "templ" },
                solidity = { "forge_fmt" },
                zig = { "zigfmt" },
                http = { "kulala-fmt" },
                fish = { "fish_indent" },
            },
        },
    },
}
