return {
    "ray-x/go.nvim",
    dependencies = "ray-x/guihua.lua",
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all_sync()',
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
            lsp_on_attach = function(client, _)
                if not client.server_capabilities.semanticTokensProvider then
                    local semantic = client.config.capabilities.textDocument.semanticTokens
                    client.server_capabilities.semanticTokensProvider = {
                        full = true,
                        legend = { tokenTypes = semantic.tokenTypes, tokenModifiers = semantic.tokenModifiers },
                        range = true,
                    }
                end
            end,
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
                    border = "single",
                    max_width = math.floor(vim.o.columns / 2),
                    max_height = math.floor(vim.o.lines / 3),
                },
            },
        }
    end,
}
