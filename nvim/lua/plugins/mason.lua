return {
    "williamboman/mason.nvim",
    opts = {
        ensure_installed = {
            "sqlfluff",
            "jq",
            "rust-analyzer",
            "prettier",
            "bacon-ls",
        },
        PATH = "prepend",
        max_concurrent_installers = 20,
    },
}
