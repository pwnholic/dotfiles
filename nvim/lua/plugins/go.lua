return {
    "ray-x/go.nvim",
    dependencies = { "ray-x/guihua.lua", branch = "master" },
    ft = { "go", "gomod" },
    branch = "master",
    build = ":GoUpdateBinaries",
    opts = function()
        return {
            tag_transform = "snakecase",
            tag_options = "json",
            gofmt = "goimports",
            lsp_cfg = true,
            lsp_keymaps = false,
            null_ls = false,
            lsp_inlay_hints = { enable = false },
            dap_debug_keymap = false,
            trouble = true,
            luasnip = true,
            lsp_on_attach = nil,
            dap_debug_gui = {
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
            dap_debug_vt = {
                enabled = true,
                enabled_commands = true,
                all_frames = true,
                virt_text_pos = "eol",
            },
            dap_port = 38697,
            dap_timeout = 15,
            dap_retries = 20,
            diagnostic = {
                hdlr = true,
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
                    border = vim.g.border,
                    max_width = math.floor(vim.o.columns / 2),
                    max_height = math.floor(vim.o.lines / 3),
                },
            },
        }
    end,
}
