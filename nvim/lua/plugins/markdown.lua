return {
    {
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
    },
    {
        "epwalsh/obsidian.nvim",
        ft = "markdown",
        keys = function()
            return {
                {
                    "gf",
                    function()
                        return require("obsidian").util.gf_passthrough()
                    end,
                    desc = "Go To Notes",
                    expr = true,
                    ft = "markdown",
                },
                {
                    "<CR>",
                    function()
                        return require("obsidian").util.smart_action()
                    end,
                    ft = "markdown",
                    expr = true,
                },
            }
        end,
        opts = function()
            return {
                dir = os.getenv("HOME") .. "/Notes",
                notes_subdir = false,
                daily_notes = {
                    folder = "00 Inbox",
                    date_format = "%Y-%m-%d",
                    alias_format = "%B %-d, %Y",
                    default_tags = { "daily-notes" },
                    template = nil,
                },
                mappings = {},
                new_notes_location = "current_dir",
                note_id_func = function(title)
                    local suffix = ""
                    if title ~= nil then
                        suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
                    else
                        for _ = 1, 4 do
                            suffix = suffix .. string.char(math.random(65, 90))
                        end
                    end
                    return tostring(os.time()) .. "-" .. suffix
                end,

                note_path_func = function(spec)
                    local path = spec.dir / tostring(spec.id)
                    return path:with_suffix(".md")
                end,
                wiki_link_func = "prepend_note_path",
                markdown_link_func = function(opts)
                    return require("obsidian.util").markdown_link(opts)
                end,
                preferred_link_style = "wiki",
                disable_frontmatter = true,
                templates = {
                    folder = "40 Templates",
                    date_format = "%Y-%m-%d",
                    time_format = "%H:%M",
                    substitutions = {},
                },
                follow_url_func = function(url)
                    vim.ui.open(url)
                end,
                use_advanced_uri = true,
                open_app_foreground = false,

                picker = {
                    name = "fzf-lua",
                    note_mappings = {
                        new = "<C-x>",
                        insert_link = "<C-l>",
                    },
                    tag_mappings = {
                        tag_note = "<C-x>",
                        insert_tag = "<C-l>",
                    },
                },
                ui = { enable = false },
                attachments = {
                    img_folder = "Assets/Images",
                    img_name_func = function()
                        return string.format("%s-", os.time())
                    end,
                    img_text_func = function(client, path)
                        path = client:vault_relative_path(path) or path
                        return string.format("![%s](%s)", path.name, path)
                    end,
                },
            }
        end,
    },
    {
        "OXY2DEV/markview.nvim",
        ft = "markdown",
        opts = {
            yaml = { enable = false },
        },
    },
}
