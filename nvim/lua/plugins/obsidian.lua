return {
    "obsidian-nvim/obsidian.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    version = false,
    cmd = {
        "ObsidianOpen",
        "ObsidianNew",
        "ObsidianQuickSwitch",
        "ObsidianFollowLink",
        "ObsidianBacklinks",
        "ObsidianTags",
        "ObsidianToday",
        "ObsidianYesterday",
        "ObsidianTomorrow",
        "ObsidianDailies",
        "ObsidianTemplate",
        "ObsidianSearch",
        "ObsidianLink",
        "ObsidianLinkNew",
        "ObsidianLinks",
        "ObsidianExtractNote",
        "ObsidianWorkspace",
        "ObsidianPasteImg",
        "ObsidianRename",
        "ObsidianToggleCheckbox",
        "ObsidianNewFromTemplate",
        "ObsidianTOC",
    },
    keys = {
        {
            "gf",
            function()
                if require("obsidian").util.cursor_on_markdown_link() then
                    return "<cmd>ObsidianFollowLink<CR>"
                else
                    return "gf"
                end
            end,
            desc = "Go File",
            expr = true,
            ft = "markdown",
        },
        { "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Open note in Obsidian app (current buffer)" },
        {
            "<leader>oq",
            function()
                vim.ui.input({ prompt = "Open note query (current buffer if empty): " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    if cleaned_input == "" then
                        vim.cmd.ObsidianOpen() -- Default: current buffer if input is empty
                    else
                        vim.cmd.ObsidianOpen({ args = cleaned_input })
                    end
                end)
            end,
            desc = "Open note in Obsidian app with query",
        },
        {
            "<leader>on",
            function()
                vim.ui.input({ prompt = "New note title (leave empty for default naming): " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    if cleaned_input == "" then
                        vim.cmd.ObsidianNew() -- Default: plugin's default naming if input is empty
                    else
                        vim.cmd.ObsidianNew({ args = cleaned_input })
                    end
                end)
            end,
            desc = "Create a new note with title",
        },

        { "<leader>os", "<cmd>ObsidianQuickSwitch<cr>", desc = "Quickly switch/open note" },
        { "<leader>of", "<cmd>ObsidianFollowLink<cr>", desc = "Follow link under cursor" },
        { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Show backlinks to current note" },
        {
            "<leader>ot",
            function()
                vim.ui.input({ prompt = "Tag(s) to search (all if empty): " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    vim.cmd.ObsidianTags({ args = cleaned_input })
                end)
            end,
            desc = "Show occurrences of specific tag(s) / all if empty",
        },
        {
            "<leader>oS",
            function()
                vim.ui.input({ prompt = "Search query: " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    vim.cmd.ObsidianSearch({ args = cleaned_input })
                end)
            end,
            desc = "Search for notes with query",
        },

        { "<leader>od", "<cmd>ObsidianToday<cr>", desc = "Open/create daily note" },
        { "<leader>ody", "<cmd>ObsidianYesterday<cr>", desc = "Open/create yesterday's daily note" },
        { "<leader>odt", "<cmd>ObsidianTomorrow<cr>", desc = "Open/create tomorrow's daily note" },
        {
            "<leader>odl",
            function()
                vim.ui.input({ prompt = "Daily notes offset (e.g., -2 1): " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    vim.cmd.ObsidianDailies({ args = cleaned_input })
                end)
            end,
            desc = "Open picker list of daily notes with offset",
        },

        {
            "<leader>otm",
            function()
                vim.ui.input({ prompt = "Template name (select from list if empty): " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    if cleaned_input == "" then
                        vim.cmd.ObsidianTemplate()
                    else
                        vim.cmd.ObsidianTemplate({ args = cleaned_input })
                    end
                end)
            end,
            desc = "Insert specific template",
        },
        {
            "<leader>onf",
            function()
                vim.ui.input({ prompt = "New note title from template (default naming if empty): " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    if cleaned_input == "" then
                        vim.cmd.ObsidianNewFromTemplate()
                    else
                        vim.cmd.ObsidianNewFromTemplate({ args = cleaned_input })
                    end
                end)
            end,
            desc = "Create new note from template with title",
        },

        {
            "<leader>ol",
            function()
                vim.ui.input({ prompt = "Link note query (selected text if empty): " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    if cleaned_input == "" then
                        vim.cmd.ObsidianLink()
                    else
                        vim.cmd.ObsidianLink({ args = cleaned_input })
                    end
                end)
            end,
            mode = "v",
            desc = "Link visual selection to note",
        },
        {
            "<leader>oln",
            function()
                vim.ui.input({ prompt = "New note title to link (selected text if empty): " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    if cleaned_input == "" then
                        vim.cmd.ObsidianLinkNew()
                    else
                        vim.cmd.ObsidianLinkNew({ args = cleaned_input })
                    end
                end)
            end,
            mode = "v",
            desc = "Create new note and link visual selection",
        },
        { "<leader>olL", "<cmd>ObsidianLinks<cr>", desc = "Collect all links in current buffer" },

        {
            "<leader>ox",
            function()
                vim.ui.input({ prompt = "Extract note title (selected text if empty): " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    if cleaned_input == "" then
                        vim.cmd.ObsidianExtractNote()
                    else
                        vim.cmd.ObsidianExtractNote({ args = cleaned_input })
                    end
                end)
            end,
            mode = "v",
            desc = "Extract visual selection to new note",
        },
        {
            "<leader>ow",
            function()
                vim.ui.input({ prompt = "Switch to workspace: " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    vim.cmd.ObsidianWorkspace({ args = cleaned_input })
                end)
            end,
            desc = "Switch to specific workspace",
        },
        {
            "<leader>op",
            function()
                vim.ui.input({ prompt = "Image name (optional): " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    if cleaned_input == "" then
                        vim.cmd.ObsidianPasteImg()
                    else
                        vim.cmd.ObsidianPasteImg({ args = cleaned_input })
                    end
                end)
            end,
            desc = "Paste image from clipboard",
        },
        {
            "<leader>or",
            function()
                vim.ui.input({ prompt = "New note name: " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    vim.cmd.ObsidianRename({ args = cleaned_input })
                end)
            end,
            desc = "Rename current note",
        },
        {
            "<leader>ord",
            function()
                vim.ui.input({ prompt = "New note name (dry-run): " }, function(input)
                    if input == nil then
                        return
                    end -- User canceled
                    local cleaned_input = input:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
                    vim.cmd("ObsidianRename " .. cleaned_input .. " --dry-run")
                end)
            end,
            desc = "Rename current note (dry-run)",
        },
    },
    opts = {
        workspaces = {
            {
                path = vim.fs.joinpath((os.getenv("HOME") or os.getenv("USERPROFILE")), "Notes2"),
            },
        },
        dir = vim.fs.joinpath((os.getenv("HOME") or os.getenv("USERPROFILE")), "Notes2"),
        daily_notes = { folder = "inbox" },
        new_notes_location = "current_dir",
        disable_frontmatter = true,
        templates = { folder = vim.fs.joinpath("systems", "templates") },
        picker = { name = "fzf-lua" },
        ui = { enable = false },
        attachments = { img_folder = vim.fs.joinpath("utilities", "attachments") },
    },
}
