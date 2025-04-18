return {
    {
        "obsidian-nvim/obsidian.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        cmd = { "ObsidianOpen", "ObsidianNew", "ObsidianRename" },
        version = false,
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
        },
        opts = {
            dir = vim.fs.joinpath((os.getenv("HOME") or os.getenv("USERPROFILE")), "Notes2"),
            daily_notes = { folder = "Inbox" },
            new_notes_location = "current_dir",
            disable_frontmatter = true,
            templates = { folder = vim.fs.joinpath("Systems", "Templates") },
            picker = { name = "fzf-lua" },
            ui = { enable = false },
            attachments = { img_folder = vim.fs.joinpath("Utilities", "Attachments") },
        },
    },
    {
        "neovim/nvim-lspconfig",
        opts = function()
            local lspconfig = require("lspconfig")
            local lsp_setup = require("lspconfig.configs")
            if not lsp_setup.iwes then
                lsp_setup.iwes = {
                    default_config = {
                        name = "iwes",
                        cmd = { "iwes" },
                        flags = { debounce_text_changes = 500 },
                        single_file_support = true,
                        filetypes = { "markdown" },
                        root_dir = function(fname)
                            return lspconfig.util.root_pattern(".iwe", ".git")(fname)
                        end,
                    },
                }
            end
        end,
    },
    {
        "OXY2DEV/markview.nvim",
        ft = "markdown",
        version = false,
        opts = {
            yaml = {
                enable = true,
                properties = {
                    default = {
                        use_types = true,
                        border_top = " │ ",
                        border_middle = " │ ",
                        border_bottom = " └",
                    },
                },
            },
        },
    },
}
