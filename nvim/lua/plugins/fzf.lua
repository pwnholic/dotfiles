local preview = {
    fzf_opts_no_preview = {
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
    },
    fzf_opts_with_preview = {
        ["--info"] = "inline-right",
        ["--ansi"] = true,
        ["--marker"] = "█",
        ["--pointer"] = "█",
        ["--padding"] = "0,1",
        ["--margin"] = "0",
        ["--highlight-line"] = true,
        ["--no-scrollbar"] = true,
    },
    winopts_no_preview = {
        split = string.format("botright %dnew", math.floor(vim.o.lines / 2)),
        preview = { hidden = true },
    },
    vertical_preview = {
        fzf_opts = {
            ["--layout"] = "reverse",
            ["--ansi"] = true,
            ["--marker"] = "█",
            ["--pointer"] = "█",
            ["--padding"] = "0,1",
            ["--margin"] = "0",
            ["--highlight-line"] = true,
        },
        winopts = {
            height = 0.75,
            width = 0.90,
            row = 0.50,
            col = 0.50,
            preview = {
                layout = "vertical",
                vertical = "down:50%",
            },
        },
    },
}

return {
    "ibhagwan/fzf-lua",
    keys = {
        {
            "<leader>fd",
            function()
                require("fzf-lua").files({
                    cwd = os.getenv("PWD"),
                    fd_opts = table.concat({
                        "--color=never",
                        "--type",
                        "d",
                        "--hidden",
                        "--follow",
                        "--exclude",
                        ".git",
                    }, " "),
                    find_opts = table.concat({
                        "-type",
                        "d",
                        "-not",
                        "-path",
                        [['*/\.git/*']],
                        "-printf",
                        "'%P\n'",
                    }, " "),
                    actions = {
                        ["default"] = function(selected, opts)
                            for i = 1, #selected do
                                local path = require("fzf-lua.path").entry_to_file(selected[i], opts).path
                                vim.cmd(string.format("Oil %s", path))
                            end
                        end,
                    },
                    winopts = {
                        split = string.format("belowright %dnew", math.floor(vim.o.lines / 3)),
                        preview = { hidden = "hidden" },
                    },
                    fzf_opts = preview.fzf_opts_no_preview,
                })
            end,
            desc = "Find Folder (root)",
        },
        { "<leader>fl", "<cmd>FzfLua tabs<CR>", desc = "Search Tabs" },
        { "<leader>gS", "<cmd>FzfLua git_stash<CR>", desc = "Git stash" },
        { "<leader>gl", "<cmd>FzfLua git_branches<CR>", desc = "Git branches" },
        { "<leader>gj", "<cmd>FzfLua git_bcommits<CR>", desc = "Git commit (buffer)" },
        {
            "<leader>cb",
            function()
                require("fzf-lua").lsp_finder({
                    fzf_opts = preview.vertical_preview.fzf_opts,
                    winopts = preview.vertical_preview.winopts,
                })
            end,
            desc = "Lsp Find",
        },
        { "<leader>gx", desc = "Git conflict list" },
    },
    opts = function(_, opts)
        local actions = require("fzf-lua.actions")
        local path = require("fzf-lua.path")
        local no_preview = {
            fzf_opts = preview.fzf_opts_no_preview,
            winopts = preview.winopts_no_preview,
        }

        vim.keymap.set("n", "<leader>gx", function()
            require("fzf-lua").fzf_exec("git diff --name-only --diff-filter=U", {
                prompt = "Git Conflict>",
                actions = {
                    ["right"] = { fn = actions.git_unstage, reload = true },
                    ["left"] = { fn = actions.git_stage, reload = true },
                    ["ctrl-x"] = { fn = actions.git_reset, reload = true },
                    ["default"] = actions.file_edit,
                },
            })
        end, { desc = "Git conflict list" })

        opts.file_icon_padding = " "
        opts.winopts = {
            height = 0.75,
            width = 0.90,
            row = 0.50,
            col = 0.50,
            backdrop = 80, -- opcity
            title_flags = false,
            border = vim.g.border,
            preview = {
                horizontal = "right:55%",
                layout = "flex",
                border = vim.g.border,
                scrollbar = false,
                winopts = {
                    number = false,
                    relativenumber = false,
                    cursorline = true,
                    cursorlineopt = "both",
                    cursorcolumn = false,
                    signcolumn = "yes",
                    list = false,
                    foldenable = false,
                    foldmethod = "manual",
                },
            },
        }
        opts.fzf_opts = preview.fzf_opts_with_preview
        opts.defaults = {
            file_icons = "mini",
            headers = { "actions", "cwd" },
            cwd_header = false,
            formatter = "path.dirname_first",
        }
        opts.files = {
            prompt = "Files ❯ ",
            multiprocess = true,
            git_icons = false,
            color_icons = true,
            -- path_shorten   = 1,
            formatter = "path.filename_first",
            find_opts = table.concat({
                "-type",
                "f",
                "-type",
                "l",
                "-not",
                "-path",
                [['*/\.git/*']],
                "-printf",
                "'%P\n'",
            }, " "),
            fd_opts = table.concat({
                "--color=never",
                "--type",
                "f",
                "--type",
                "l",
                "--follow",
                "--exclude",
                ".git",
            }, " "),
            rg_opts = table.concat({ "--color=never", "--files", "--follow", "-g=!git/" }, " "),
            cwd_prompt = false,
            cwd_prompt_shorten_len = 32,
            cwd_prompt_shorten_val = 1,
            toggle_ignore_flag = "--no-ignore",
            toggle_hidden_flag = "--hidden",
            actions = {
                ["alt-i"] = { actions.toggle_ignore },
                ["alt-h"] = { actions.toggle_hidden },
            },
        }

        opts.tabs = no_preview
        opts.commands = no_preview
        opts.diagnostics = {
            prompt = "Diagnostics❯ ",
            cwd_only = false,
            file_icons = true,
            git_icons = false,
            diag_icons = true,
            diag_source = true,
            icon_padding = " ",
            multiline = true,
        }
        opts.lsp = {
            finder = {
                prompt = "LSP Finder> ",
                file_icons = true,
                color_icons = true,
                async = true,
                silent = true,
                separator = "│ ",
            },
        }
        opts.grep = {
            prompt = "Rg ❯ ",
            input_prompt = "Grep For ❯ ",
            multiprocess = true,
            git_icons = false,
            color_icons = true,
            grep_opts = table.concat({
                "--binary-files=without-match",
                "--line-number",
                "--recursive",
                "--color=auto",
                "--perl-regexp",
                "-e",
            }, " "),
            rg_opts = table.concat({
                "--column",
                "--hidden",
                "--follow",
                "--line-number",
                "--no-heading",
                "--color=always",
                "--smart-case",
                "--max-columns=4096",
                "-g=!git/",
                "-e",
            }, " "),
            rg_glob = true,
            -- RIPGREP_CONFIG_PATH = vim.env.RIPGREP_CONFIG_PATH,
            glob_flag = "--iglob",
            glob_separator = "%s%-%-",
            no_header = false,
            no_header_i = false,
            actions = {
                ["alt-i"] = { actions.toggle_ignore },
                ["alt-h"] = { actions.toggle_hidden },
            },
        }

        opts.git = {
            status = {
                prompt = "GitStatus❯ ",
                cmd = "git -c color.status=false --no-optional-locks status --porcelain=v1 -u",
                multiprocess = true,
                file_icons = true,
                color_icons = true,
                previewer = "git_diff",
                preview_pager = false,
                winopts = {
                    preview = {
                        border = "none",
                        horizontal = "right:55%",
                        layout = "flex",
                    },
                },
                actions = {
                    ["right"] = { fn = actions.git_unstage, reload = true },
                    ["left"] = { fn = actions.git_stage, reload = true },
                    ["ctrl-x"] = { fn = actions.git_reset, reload = true },
                    ["ctrl-l"] = function(selected, o)
                        ---@type string
                        local filepath
                        for _, sel in ipairs(selected) do
                            local entry = path.entry_to_file(sel, o, o._uri)
                            if entry.path == "<none>" then
                                return
                            end
                            local fullpath = entry.bufname or entry.uri and entry.uri:match("^%a+://(.*)") or entry.path
                            if not fullpath then
                                return
                            end
                            if not path.is_absolute(fullpath) then
                                fullpath = path.join({ o.cwd or o._cwd or vim.uv.cwd(), fullpath })
                            end
                            filepath = vim.fn.fnamemodify(fullpath, ":p:.")
                        end
                        return vim.cmd("Git add " .. filepath) and vim.cmd("Git commit " .. filepath)
                    end,
                },
            },
        }
    end,
}
