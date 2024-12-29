return {
    "ibhagwan/fzf-lua",
    keys = {
        {
            "<leader>fd",
            function()
                require("fzf-lua").files({
                    fd_opts = [[--color=never --type d --hidden --follow --exclude .git]],
                    find_opts = [[-type d -not -path '*/\.git/*' -printf '%P\n']],
                })
            end,
            desc = "Find Folder (root)",
        },
        { "<leader>fl", "<cmd>FzfLua tabs<CR>", desc = "Search Tabs" },
        { "<leader>gS", "<cmd>FzfLua git_stash<CR>", desc = "Git stash" },
        { "<leader>gl", "<cmd>FzfLua git_branches<CR>", desc = "Git branches" },
        { "<leader>gj", "<cmd>FzfLua git_bcommits<CR>", desc = "Git commit (buffer)" },
        { "<leader>gx", desc = "Git conflict list" },
    },
    opts = function(_, opts)
        local actions = require("fzf-lua.actions")
        local path = require("fzf-lua.path")
        local core = require("fzf-lua.core")
        local config = require("fzf-lua.config")

        local function action_git_commit(selected, def_opts)
            actions.git_stage(selected, def_opts)
            for _, e in ipairs(selected) do
                local file = path.relative_to(path.entry_to_file(e, def_opts).path, def_opts.cwd)
                vim.notify(string.format("Please write commit message on file %s", file), 2)
                vim.cmd(string.format("Git commit %s", file))
            end
        end

        vim.keymap.set("n", "<leader>gx", function()
            require("fzf-lua").fzf_exec("git diff --name-only --diff-filter=U", {
                prompt = "Git Conflict>",
                actions = {
                    ["right"] = { fn = actions.git_unstage, reload = true },
                    ["left"] = { fn = actions.git_stage, reload = true },
                    ["ctrl-x"] = { fn = actions.git_reset, reload = true },
                    ["ctrl-m"] = action_git_commit,
                },
            })
        end, { desc = "Git conflict list" })

        core.ACTION_DEFINITIONS[action_git_commit] = { "git commit" }
        config._action_to_helpstr[action_git_commit] = "git-commit"

        opts.file_icon_padding = " "
        opts.winopts = {
            split = "botright 10new | setlocal bt=nofile bh=wipe nobl noswf wfh",
            preview = { hidden = "hidden" },
        }
        opts.fzf_opts = {
            ["--info"] = "inline-right",
            ["--layout"] = "reverse",
            ["--ansi"] = true,
            ["--marker"] = "█",
            ["--pointer"] = "█",
            ["--padding"] = "0,1",
            ["--margin"] = "0",
            ["--highlight-line"] = true,
            ["--preview-window"] = "hidden",
            ["--no-preview"] = true,
            ["--border"] = "none",
        }
        opts.defaults = {
            file_icons = "mini",
            headers = { "actions", "cwd" },
            cwd_header = true,
            formatter = "path.dirname_first",
        }
        opts.files = {
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
        }
        opts.grep = {
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
            no_header = false,
            no_header_i = false,
        }
        opts.git = {
            status = {
                prompt = "Git Status❯ ",
                cmd = "git -c color.status=false --no-optional-locks status --porcelain=v1 -u",
                multiprocess = true,
                git_icons = true,
                color_icons = true,
                previewer = "git_diff",
                actions = {
                    ["right"] = { fn = actions.git_unstage, reload = true },
                    ["left"] = { fn = actions.git_stage, reload = true },
                    ["ctrl-x"] = { fn = actions.git_reset, reload = true },
                    ["ctrl-m"] = action_git_commit,
                },
            },
        }
    end,
}
