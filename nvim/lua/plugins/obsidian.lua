return {
    "epwalsh/obsidian.nvim",
    ft = "markdown",
    version = false,
    opts = {
        workspaces = { { name = "Notes", path = os.getenv("HOME") .. "/Notes", overrides = {} } },
        notes_subdir = nil,
        log_level = vim.log.levels.INFO,
        daily_notes = {
            folder = "00 Inbox",
            date_format = "%Y-%m-%d",
            alias_format = "%B %-d, %Y",
            default_tags = { "daily-notes" },
            template = nil,
        },
        completion = { nvim_cmp = true, min_chars = 2 },
        new_notes_location = "current_dir",
        -- note_id_func = function(title)
        --     return title
        -- end,
        note_path_func = function(spec)
            local path = spec.dir / tostring(spec.id)
            return path:with_suffix(".md")
        end,
        wiki_link_func = "use_path_only",
        markdown_link_func = function(opts)
            return require("obsidian.util").markdown_link(opts)
        end,
        preferred_link_style = "wiki",
        disable_frontmatter = true,
        templates = {
            folder = "Templates",
            date_format = "%Y-%m-%d",
            time_format = "%H:%M",
            substitutions = {},
        },
        ---@param url string
        follow_url_func = function(url)
            vim.fn.jobstart({ "xdg-open", url }) -- linux
        end,
        use_advanced_uri = true,
        picker = {
            name = "fzf-lua",
            note_mappings = { new = "<C-x>", insert_link = "<C-l>" },
            tag_mappings = { tag_note = "<C-x>", insert_tag = "<C-l>" },
        },
        sort_by = "modified",
        sort_reversed = true,
        search_max_lines = 1000,
        open_notes_in = "current",
        ui = { enable = false },
    },
}
