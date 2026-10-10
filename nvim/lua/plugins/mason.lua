return {
    {
        "mason-org/mason.nvim",
        opts = function(_, opts)
            opts.ensure_installed = opts.ensure_installed or {}
            -- Binaries already on mason bin/ (stylua/shfmt/go/gopls/
            -- python-lsp/oxfmt/taplo) come from extras; install only the
            -- missing formatter CLIs.
            vim.list_extend(opts.ensure_installed, { "prettier", "ruff" })
        end,
    },
}
