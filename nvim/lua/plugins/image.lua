return {
    "3rd/image.nvim",
    ft = { "markdown", "neorg" },
    opts = {
        backend = "kitty",
        processor = "magick_rock",
        integrations = {
            markdown = {
                enabled = true,
                clear_in_insert_mode = false,
                download_remote_images = false,
                only_render_image_at_cursor = false,
                floating_windows = false,
                filetypes = { "markdown", "vimwiki" },
            },
        },
        max_height_window_percentage = 50,
        editor_only_render_when_focused = false,
        tmux_show_only_in_active_window = false,
        hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
    },
}
