return {
    {
        "williamboman/mason.nvim",
        opts = {
            ensure_installed = {
                -- "rust-analyzer",
                -- "bacon-ls",
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        opts = function()
            local lspconfig = require("lspconfig")
            local lsp_setup = require("lspconfig.configs")
            if not lsp_setup.iwes then
                lsp_setup.iwes = {
                    default_config = {
                        name = "iwes",
                        cmd = { "iwes" },
                        flags = { debounce_text_changes = 500, },
                        single_file_support = true,
                        filetypes = { "markdown" },
                        root_dir = function(fname)
                            return lspconfig.util.root_pattern(".iwe", ".git")(fname)
                        end,
                    },
                }
            end
        end,
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            codelens = { enabled = false },
            inlay_hints = { enabled = false, exclude = {} },
            diagnostics = {
                float = { border = vim.g.border },
                virtual_text = { spacing = 2, source = "if_many", prefix = "" },
                virtual_lines = false,
            },
            servers = {
                iwes = {},
            },
            setup = { },
        },
    },
    -- FZF
    {
        "neovim/nvim-lspconfig",
        opts = function()
            local keys = require("lazyvim.plugins.lsp.keymaps").get()
            local function symbols_filter(entry, ctx)
                if ctx.symbols_filter == nil then
                    ctx.symbols_filter = LazyVim.config.get_kind_filter(ctx.bufnr) or false
                end
                if ctx.symbols_filter == false then
                    return true
                end
                return vim.tbl_contains(ctx.symbols_filter, entry.kind)
            end

            --- @param type string
            --- @param opts table?
            local fzf_lsp = function(type, opts)
                opts = opts or {}
                return function()
                    local lsp_provider = string.format("lsp_%s", type)
                    return require("fzf-lua")[lsp_provider](vim.tbl_extend("force", {
                        jump1 = true,
                        ignore_current_line = true,
                        fzf_opts = vim.g.fzf_layout.vertical.fzf_options.with_preview,
                        winopts = vim.g.fzf_layout.vertical.window_options.with_preview,
                        actions = {
                            ["ctrl-t"] = function()
                                if lsp_provider == "live_workspace_symbols" then
                                    lsp_provider = "lsp_document_symbols"
                                end
                                vim.cmd(string.format("Trouble %s", lsp_provider))
                            end,
                        },
                    }, opts))
                end
            end

            local regex_filter = { regex_filter = symbols_filter }
            keys[#keys + 1] = { "gd", fzf_lsp("definitions"), desc = "Goto Definition" }
            keys[#keys + 1] = { "gr", fzf_lsp("references"), desc = "References" }
            keys[#keys + 1] = { "gI", fzf_lsp("implementations"), desc = "Goto Implementation" }
            keys[#keys + 1] = { "gy", fzf_lsp("typedefs"), desc = "Goto T[y]pe Definition" }
            keys[#keys + 1] = { "gD", fzf_lsp("declarations"), desc = "Goto Declaration" }
            keys[#keys + 1] = { "<leader>ci", fzf_lsp("incoming_calls"), desc = "Incoming Call" }
            keys[#keys + 1] = { "<leader>co", fzf_lsp("outgoing_calls"), desc = "Outgoing Call" }
            keys[#keys + 1] = { "<leader>ss", fzf_lsp("document_symbols", regex_filter), desc = "Goto Symbols" }
            keys[#keys + 1] = { "<leader>sS", fzf_lsp("live_workspace_symbols", regex_filter), desc = "Workspace Symbols" }
        end,
    },
    -- TROUBLE
    -- {
    --     "neovim/nvim-lspconfig",
    --     opts = function()
    --         local keys = require("lazyvim.plugins.lsp.keymaps").get()
    --         keys[#keys + 1] = { "gd", "<cmd>Trouble lsp_definitions<cr>", desc = "Goto Definition", has = "definition" }
    --         keys[#keys + 1] = { "gr", "<cmd>Trouble lsp_references<cr>", desc = "References", nowait = true }
    --         keys[#keys + 1] = { "gI", "<cmd>Trouble lsp_implementations<cr>", desc = "Goto Implementation" }
    --         keys[#keys + 1] = { "gy", "<cmd>Trouble lsp_type_definitions<cr>", desc = "Goto T[y]pe Definition" }
    --         keys[#keys + 1] = { "gD", "<cmd>Trouble lsp_declarations<cr>", desc = "Goto Declaration" }
    --         keys[#keys + 1] = { "<leader>ci", "<cmd>Trouble lsp_incoming_calls<cr>", desc = "Incoming Call" }
    --         keys[#keys + 1] = { "<leader>co", "<cmd>Trouble lsp_outgoing_calls<cr>", desc = "Outgoing Call" }
    --         keys[#keys + 1] = { "<leader>ss", "<cmd>Trouble lsp_document_symbols<cr>", desc = "Goto Symbols" }
    --     end,
    -- },
}
