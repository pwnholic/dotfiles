return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            codelens = { enabled = false },
            inlay_hints = { enabled = false, exclude = {} },
            diagnostics = {
                float = { border = vim.g.border },
                virtual_text = { spacing = 2, source = "if_many", prefix = "" },
            },
            servers = {},
            setup = {},
        },
    },
    -- FZF
    -- {
    --     "neovim/nvim-lspconfig",
    --     opts = function()
    --         local keys = require("lazyvim.plugins.lsp.keymaps").get()
    --         local fzf_lsp = function(type)
    --             return function()
    --                 require("fzf-lua")[type]({
    --                     cmd = "rg --vimgrep",
    --                     rg_opts = "--column --line-number --no-heading --color=always --smart-case --trim -e",
    --                     jump_to_single_result = true,
    --                     ignore_current_line = true,
    --                     fzf_opts = {
    --                         ["--layout"] = "reverse",
    --                         ["--ansi"] = true,
    --                         ["--marker"] = "█",
    --                         ["--pointer"] = "█",
    --                         ["--padding"] = "0,1",
    --                         ["--margin"] = "0",
    --                         ["--highlight-line"] = true,
    --                     },
    --                     winopts = {
    --                         height = 0.75,
    --                         width = 0.90,
    --                         row = 0.50,
    --                         col = 0.50,
    --                         preview = { layout = "vertical", vertical = "down:50%" },
    --                     },
    --                 })
    --             end
    --         end
    --         keys[#keys + 1] = { "gd", fzf_lsp("lsp_definitions"), desc = "Goto Definition" }
    --         keys[#keys + 1] = { "gr", fzf_lsp("lsp_references"), desc = "References" }
    --         keys[#keys + 1] = { "gI", fzf_lsp("lsp_implementations"), desc = "Goto Implementation" }
    --         keys[#keys + 1] = { "gy", fzf_lsp("lsp_typedefs"), desc = "Goto T[y]pe Definition" }
    --         keys[#keys + 1] = { "gD", fzf_lsp("lsp_declarations"), desc = "Goto Declaration" }
    --         keys[#keys + 1] = { "<leader>ci", fzf_lsp("lsp_incoming_calls"), desc = "Incoming Call" }
    --         keys[#keys + 1] = { "<leader>co", fzf_lsp("lsp_outgoing_calls"), desc = "Outgoing Call" }
    --     end,
    -- },
    -- TROUBLE
    {
        "neovim/nvim-lspconfig",
        opts = function()
            local keys = require("lazyvim.plugins.lsp.keymaps").get()
            keys[#keys + 1] = { "gd", "<cmd>Trouble lsp_definitions<cr>", desc = "Goto Definition", has = "definition" }
            keys[#keys + 1] = { "gr", "<cmd>Trouble lsp_references<cr>", desc = "References", nowait = true }
            keys[#keys + 1] = { "gI", "<cmd>Trouble lsp_implementations<cr>", desc = "Goto Implementation" }
            keys[#keys + 1] = { "gy", "<cmd>Trouble lsp_type_definitions<cr>", desc = "Goto T[y]pe Definition" }
            keys[#keys + 1] = { "gD", "<cmd>Trouble lsp_declarations<cr>", desc = "Goto Declaration" }
            keys[#keys + 1] = { "<leader>ci", "<cmd>Trouble lsp_incoming_calls<cr>", desc = "Incoming Call" }
            keys[#keys + 1] = { "<leader>co", "<cmd>Trouble lsp_outgoing_calls<cr>", desc = "Outgoing Call" }
        end,
    },
}
