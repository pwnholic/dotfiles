return {
    "epwalsh/obsidian.nvim",
    ft = "markdown",
    version = false,
    opts = function()
        return {
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
            mappings = {
                ["gf"] = {
                    action = function()
                        return require("obsidian").util.gf_passthrough()
                    end,
                    opts = { noremap = false, expr = true, buffer = true },
                },
                ["<leader>ch"] = {
                    action = function()
                        return require("obsidian").util.toggle_checkbox()
                    end,
                    opts = { buffer = true },
                },
                ["<cr>"] = {
                    action = function()
                        return require("obsidian").util.smart_action()
                    end,
                    opts = { buffer = true, expr = true },
                },
            },
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
            ---@return table
            note_frontmatter_func = function(note)
                if note.title then
                    note:add_alias(note.title)
                end
                local out = { id = note.id, aliases = note.aliases, tags = note.tags }
                if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
                    for k, v in pairs(note.metadata) do
                        out[k] = v
                    end
                end

                return out
            end,
            templates = {
                folder = "06 Templates",
                date_format = "%Y-%m-%d",
                time_format = "%H:%M",
                substitutions = {},
            },
            ---@param url string
            follow_url_func = function(url)
                vim.fn.jobstart({ "xdg-open", url }) -- linux
            end,

            -- Optional, set to true if you use the Obsidian Advanced URI plugin.
            -- https://github.com/Vinzent03/obsidian-advanced-uri
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
            attachments = {
                img_folder = "assets/imgs", -- This is the default
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
}
