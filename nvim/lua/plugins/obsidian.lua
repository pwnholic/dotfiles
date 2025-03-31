return {
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
            { "<leader>op", "<cmd>ObsidianOpen<cr>", desc = "Open Apps", ft = "markdown" },
            { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "New Notes", ft = "markdown" },
            { "<leader>o ", "<cmd>ObsidianQuickSwitch<cr>", desc = "Switch or Open Note", ft = "markdown" },
            { "g]", "<cmd>ObsidianFollowLink<cr>", desc = "Follow Link", ft = "markdown" },
            { "g[", "<cmd>ObsidianBacklinks<cr>", desc = "Back link", ft = "markdown" },
            { "<leader>oT", "<cmd>ObsidianTags<cr>", desc = "Search Tags", ft = "markdown" },
            { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Search or Create Note", ft = "markdown" },
            { "<leader>or", "<cmd>ObsidianRename<cr>", desc = "", ft = "markdown" },
        }
    end,
    opts = {
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
        use_advanced_uri = false,
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
        ui = { enable = true },
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
    },
    config = function(_, opts)
        require("obsidian").setup(opts)
    end,
}
