return {
    "Wansmer/treesj",
    keys = { { "gS", "<cmd>TSJToggle<cr>", desc = "Split/Join Block Code" } },
    version = false,
    opts = {
        use_default_keymaps = false,
        max_join_length = 1024,
        check_syntax_error = true,
        cursor_behavior = "hold",
        notify = false,
        dot_repeat = true,
        on_error = function(err_msg, level)
            return vim.notify(err_msg, level, { title = "treej" })
        end,
    },
}
