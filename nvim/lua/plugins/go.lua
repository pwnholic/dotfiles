return {
    "ray-x/go.nvim",
    branch = "master",
    ft = { "go", "gomod", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },
    opts = function()
        return {
            disable_defaults = false,
            go = "go",
            goimports = "goimports",
            gofmt = false,
            fillstruct = "fillstruct",
            tag_options = "",
            icons = { breakpoint = "🧘", currentpos = "🏃" },
            verbose = false,
            lsp_cfg = false,
            lsp_gofumpt = false,
            lsp_keymaps = false,
            lsp_codelens = false,
            diagnostic = require("utils.lsp").diagnostics_config,
            go_input = vim.ui.input,
            go_select = vim.ui.select,
            lsp_document_formatting = false,
            lsp_inlay_hints = { enable = false },
            textobjects = false,
            trouble = true,
            luasnip = true,
        }
    end,
    config = function(_, opts)
        require("go").setup(opts)
    end,
}
