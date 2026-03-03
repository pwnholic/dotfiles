return {
    "3rd/image.nvim",
    build = false, -- jangan build luarock otomatis, kita pakai magick_cli
    ft = { "markdown", "vimwiki", "norg", "typst" }, -- lazy load per filetype
    opts = {
        backend = "kitty", -- "kitty" | "ueberzug" | "sixel"
        processor = "magick_cli", -- "magick_cli" (default, paling mudah) | "magick_rock"
        integrations = {
            markdown = {
                enabled = true,
                clear_in_insert_mode = false,
                download_remote_images = true,
                only_render_image_at_cursor = false,
                only_render_image_at_cursor_mode = "popup",
                floating_windows = false,
                filetypes = { "markdown", "vimwiki" },
            },
            neorg = {
                enabled = true,
                filetypes = { "norg" },
            },
            typst = {
                enabled = true,
                filetypes = { "typst" },
            },
            html = {
                enabled = false,
            },
            css = {
                enabled = false,
            },
        },
        max_width = nil, -- nil = auto
        max_height = nil,
        max_width_window_percentage = nil,
        max_height_window_percentage = 50, -- gambar max 50% tinggi window
        scale_factor = 1.0, -- 1.0 = normal, naikkan untuk HiDPI
        window_overlap_clear_enabled = true, -- bersihkan gambar saat window overlap
        window_overlap_clear_ft_ignore = {
            "cmp_menu",
            "cmp_docs",
            "snacks_notif",
            "scrollview",
            "scrollview_sign",
        },
        editor_only_render_when_focused = true,
        tmux_show_only_in_active_window = true,
        hijack_file_patterns = {
            "*.png",
            "*.jpg",
            "*.jpeg",
            "*.gif",
            "*.webp",
            "*.avif",
        },
    },
    keys = {
        { "<leader>i", desc = "image" },
        {
            "<leader>it",
            function()
                local img = require("image")
                if img.is_enabled() then
                    img.disable()
                    vim.notify("image.nvim disabled", vim.log.levels.INFO)
                else
                    img.enable()
                    vim.notify("image.nvim enabled", vim.log.levels.INFO)
                end
            end,
            desc = "Toggle image rendering",
        },
        {
            "<leader>ir",
            "<cmd>ImageReport<cr>",
            desc = "Image diagnostic report",
        },
    },
}
