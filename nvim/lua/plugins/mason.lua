return {
    "williamboman/mason.nvim",
    opts = {
        ensure_installed = {
            "sqlfluff",
            "jq",
            "rust-analyzer",
            "prettier",
            "markdownlint-cli2",
            "markdown-toc",
            "bacon",
            "bacon-ls",
        },
        PATH = "prepend",
        max_concurrent_installers = 20,
    },
}
