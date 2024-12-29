return {
    "epwalsh/obsidian.nvim",
    version = "*",
    ft = "markdown",
    keys = {
        { "<leader>no", "<cmd>ObsidianOpen<cr>", desc = "Open Obsidian App" },
    },
    opts = {
        wiki_link_func = "prepend_note_path",
        new_notes_location = "current_dir",
        open_notes_in = "current",
        preferred_link_style = "wiki",
        disable_frontmatter = true,
        workspaces = { { name = "Local", path = string.format("%s/Notes", os.getenv("HOME")) } },
        daily_notes = { folder = "00 Inbox", template = nil },
        completion = { nvim_cmp = false },
        templates = { folder = "40 Templates" },
        ui = { enable = false },
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
    },
}
