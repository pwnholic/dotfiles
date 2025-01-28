return {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
        local keys = require("lazyvim.plugins.lsp.keymaps").get()
        keys[#keys + 1] = { "gd", "<cmd>Trouble lsp_definitions<cr>" }
        keys[#keys + 1] = { "gr", "<cmd>Trouble lsp_references<cr>" }

        opts.codelens = { enabled = false }
        opts.inlay_hints = { enabled = false, exclude = {} }
        opts.diagnostics = {
            float = { border = vim.g.border },
            virtual_text = { spacing = 2, source = "if_many", prefix = "" },
        }
        opts.servers = {}
        opts.setup = {}
    end,
}
