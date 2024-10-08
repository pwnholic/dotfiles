return {
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
        { "<leader><Tab>s", "<cmd>FzfLua tabs<CR>", desc = "Search Tabs" },
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
    },
}
