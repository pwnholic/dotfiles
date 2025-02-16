return {
    "3rd/image.nvim",
    ft = { "markdown" },
    opts = {
        backend = "kitty",
        processor = "magick_rock",
        integrations = {
            markdown = {
                enabled = true,
                clear_in_insert_mode = true,
                download_remote_images = false,
                only_render_image_at_cursor = false,
                floating_windows = false,
                filetypes = { "markdown", "vimwiki" },
            },
            html = { enabled = true },
            css = { enabled = true },
        },
        max_width = nil,
        max_height = nil,
        max_width_window_percentage = nil,
        max_height_window_percentage = 50,
        window_overlap_clear_enabled = false,
        window_overlap_clear_ft_ignore = { "snacks_notif", "scrollview", "scrollview_sign" },
        editor_only_render_when_focused = false,
        tmux_show_only_in_active_window = false,
        hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
    },
}
