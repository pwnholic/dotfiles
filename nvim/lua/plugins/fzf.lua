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
        local f = string.format

        local function action_git_commit(selected, def_opts)
            actions.git_stage(selected, def_opts)
            for _, e in ipairs(selected) do
                local file = path.relative_to(path.entry_to_file(e, def_opts).path, def_opts.cwd)
                vim.notify(f("Please write commit message on file %s", file), 2)
                vim.cmd(f("Git commit %s", file))
            end
        end

        ---@diagnostic disable-next-line: unused-local
        local function action_git_create_new_branch()
            vim.ui.input({ prompt = "New Branch Name : " }, function(input)
                if input ~= "" then
                    input = string.lower(string.gsub(input, "%s", "-"))
                    vim.cmd("Git checkout -b " .. input)
                    vim.notify("New branch " .. input .. " has been created", 2, { title = "Git FzfLua" })
                end
            end)
        end

        local function action_git_rename_branch(selected, _)
            local del_branch = selected[1]:match("[^%s%*]+")
            if vim.fn.confirm("Rename branch " .. del_branch .. "?", "&Yes\n&No") == 1 then
                vim.ui.input({ prompt = "New Branch Name : " }, function(new_name)
                    if new_name ~= "" then
                        -- stylua: ignore start
                        new_name = string.lower(string.gsub(new_name, "%s", "-"))
                        vim.cmd(f("Git branch -m %s %s", del_branch, new_name))
                        vim.notify( f("Local branch %s has been renamed to %s", del_branch, new_name), 2, { title = "FzfLua Git" })

                        vim.cmd(f("Git push origin --delete %s", del_branch))
                        vim.notify(f("Delete the %s branch on remote", del_branch), 2, { title = "FzfLua Git" })

                        vim.cmd(f("Git push origin %s", new_name ))
                        vim.notify(f("Pust the new %s branch on remote", new_name), 2, { title = "FzfLua Git" })
                        -- stylua: ignore end
                    end
                end)
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

        core.ACTION_DEFINITIONS[action_git_create_new_branch] = { "new branch" }
        config._action_to_helpstr[action_git_create_new_branch] = "new-branch"

        core.ACTION_DEFINITIONS[action_git_rename_branch] = { "rename branch" }
        config._action_to_helpstr[action_git_rename_branch] = "rename-branch"

        opts.file_icon_padding = " "
        opts.winopts = {
            split = string.format("belowright %dnew", math.floor(vim.o.lines / 3)),
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
            RIPGREP_CONFIG_PATH = vim.env.RIPGREP_CONFIG_PATH,
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
            branches = {
                prompt = "Branches❯ ",
                cmd = "git branch --all --color",
                preview = "git log --graph --pretty=oneline --abbrev-commit --color {1}",
                actions = {
                    ["enter"] = actions.git_switch,
                    ["ctrl-x"] = { fn = actions.git_branch_del, reload = true },
                    ["ctrl-a"] = action_git_create_new_branch,
                    ["ctrl-r"] = action_git_rename_branch,
                },
            },
        }
    end,
}
