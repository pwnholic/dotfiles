return {
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        config = function()
            local harpoon = require("harpoon")
            harpoon:setup({
                settings = {
                    save_on_toggle = true,
                    key = function()
                        return LazyVim.root()
                    end,
                },
            })
            harpoon:extend({
                UI_CREATE = function(ctx)
                    vim.keymap.set("n", "<C-v>", function()
                        harpoon.ui:select_menu_item({ vsplit = true })
                    end, { buffer = ctx.bufnr })
                    vim.keymap.set("n", "<C-s>", function()
                        harpoon.ui:select_menu_item({ split = true })
                    end, { buffer = ctx.bufnr })
                    vim.keymap.set("n", "<C-t>", function()
                        harpoon.ui:select_menu_item({ tabedit = true })
                    end, { buffer = ctx.bufnr })
                end,
            })
        end,
        keys = function()
            local keys = {
                {
                    "<A-space>",
                    function()
                        require("harpoon").ui:toggle_quick_menu(require("harpoon"):list(), { ui_width_ratio = 0.45, border = "single", title = "" })
                    end,
                    desc = "Harpoon List",
                },
                {
                    "<leader>a",
                    function()
                        vim.notify("Add to Mark", 2)
                        require("harpoon"):list():add()
                    end,
                    desc = "Add to Mark",
                },
            }
            for i = 1, 9 do
                table.insert(keys, {
                    "<leader>" .. i,
                    function()
                        require("harpoon"):list():select(i)
                    end,
                    desc = "Harpoon to File " .. i,
                })
            end
            return keys
        end,
    },
    {
        "ibhagwan/fzf-lua",
        keys = {
            {
                "<leader>fd",
                function()
                    require("fzf-lua").files({
                        find_opts = [[-type d -not -path '*/\.git/*' -not -path '*/\.venv/*' -printf '%P\n']],
                        fd_opts = [[--color=never --type d --hidden --follow --exclude .git --exclude .venv]],
                    })
                end,
                desc = "Find Folder (root)",
            },
            { "<leader>fl", "<cmd>FzfLua tabs<CR>", desc = "Search Tabs" },
        },
        opts = {
            winopts = {
                backdrop = 100,
                split = "botright 10new | setlocal bt=nofile bh=wipe nobl noswf wfh",
                preview = { hidden = "hidden" },
            },
            file_icon_padding = " ",
            fzf_opts = {
                ["--info"] = "inline-right",
                ["--layout"] = "reverse",
                ["--marker"] = "█",
                ["--pointer"] = "█",
                ["--border"] = "none",
                ["--padding"] = "0,1",
                ["--margin"] = "0",
                ["--no-preview"] = true,
                ["--highlight-line"] = true,
                ["--preview-window"] = "hidden",
            },
            defaults = {
                -- formatter = "path.filename_first",
                file_icons = "mini",
                headers = { "actions", "cwd" },
                cwd_header = true,
                formatter = "path.dirname_first",
            },
            files = {
                prompt = "Files❯ ",
                multiprocess = true,
                git_icons = false,
                color_icons = true,
                -- path_shorten   = 1,
                formatter = "path.filename_first",
                find_opts = [[-type f -type l -not -path '*/\.git/*' -printf '%P\n']],
                fd_opts = [[--color=never --type f --type l --follow --exclude .git]],
                rg_opts = [[--color=never --files --follow -g '!.git'"]],
                cwd_prompt = false,
                cwd_prompt_shorten_len = 32,
                cwd_prompt_shorten_val = 1,
                toggle_ignore_flag = "--no-ignore",
                toggle_hidden_flag = "--hidden",
            },
            grep = {
                prompt = "Rg❯ ",
                input_prompt = "Grep For❯ ",
                multiprocess = true,
                git_icons = false,
                color_icons = true,
                grep_opts = [[--binary-files=without-match --line-number --recursive --color=auto --perl-regexp -e]],
                rg_opts = [[--column --hidden --follow --line-number --no-heading --color=always --smart-case --max-columns=4096 -g=!git/ -e]],
                rg_glob = true,
                glob_flag = "--iglob",
                glob_separator = "%s%-%-",
                -- multiline = 1, -- Display as: PATH:LINE:COL\nTEXT\n
                no_header = false,
                no_header_i = false,
            },
            lsp = {
                definitions = { prompt = "Goto Definitions > " },
                references = { prompt = "Goto References > " },
                typedefs = { prompt = "Goto TypeDefinition > " },
                implementations = { prompt = "Goto Implementations > " },
            },
        },
    },
}
