return {
    "mfussenegger/nvim-lint",
    opts = {
        events = { "BufWritePost" },
        linters_by_ft = { go = { "golangcilint" }, solidity = { "solhint" } },
    },
}
