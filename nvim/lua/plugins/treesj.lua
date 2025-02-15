return {
    "Wansmer/treesj",
    keys = { { "<leader>cj", "<cmd>TSJToggle<cr>", desc = "Split or Join Block of Code" } },
    opts = function()
        return {
            use_default_keymaps = false,
            check_syntax_error = true,
            max_join_length = 1024,
            cursor_behavior = "hold",
            notify = true,
            dot_repeat = true,
            on_error = function(err_msg, level)
                return vim.notify(err_msg, level, { title = "treej" })
            end,
        }
    end,
}
