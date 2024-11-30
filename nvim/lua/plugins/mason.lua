return {
    "williamboman/mason.nvim",
    opts = {
        ensure_installed = { "sqlfluff", "jq", "rust-analyzer" },
        PATH = "prepend",
        max_concurrent_installers = 20,
    },
}
