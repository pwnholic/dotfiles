return {
    "ibhagwan/fzf-lua",
    keys = {
        { "<leader>dy", "<cmd>FzfLua dap_breakpoints<cr>", desc = "Search breakpoints" },
        { "<leader>dv", "<cmd>FzfLua dap_variables<cr>", desc = "Search Variable" },
        { "<leader>df", "<cmd>FzfLua dap_frames<cr>", desc = "Search Frames" },
        {
            "<leader>fd",
            function()
                require("fzf-lua").files({
                    cwd = vim.fn.fnameescape(os.getenv("PWD") or ""),
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
                                local ok, path = pcall(require("fzf-lua.path").entry_to_file, selected[i], opts)
                                if not ok then
                                    return vim.notify("could not get path for given buffer", 3, { title = "Path" })
                                end
                                return vim.cmd(string.format("Oil %s", vim.fn.fnameescape(path.path)))
                            end
                        end,
                    },
                    winopts = vim.g.fzf_layout.horizontal.window_options.no_preview,
                    fzf_opts = vim.g.fzf_layout.horizontal.fzf_options.no_preview,
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
                    fzf_opts = vim.g.fzf_layout.vertical.fzf_options.with_preview,
                    winopts = vim.g.fzf_layout.vertical.window_options.with_preview,
                })
            end,
            desc = "Lsp Find",
        },
        { "<leader>gx", desc = "Git conflict list" },
    },
    opts = function(_, opts)
        local actions = require("fzf-lua.actions")
        local path = require("fzf-lua.path")
        local core = require("fzf-lua.core")
        local config = require("fzf-lua.config")

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

        opts.fzf_opts = vim.g.fzf_layout.horizontal.fzf_options.with_preview

        opts.defaults = {
            file_icons = "mini",
            headers = { "actions", "cwd" },
            cwd_header = false,
            formatter = "path.dirname_first",
        }

        local function add_to_harpoon(selected, opt)
            for i = 1, #selected do
                local entry = path.entry_to_file(selected[i], opt)
                if entry.path == "<none>" then
                    return
                end
                local fullpath = entry.bufname or entry.uri and entry.uri:match("^%a+://(.*)") or entry.path
                if not fullpath then
                    return
                end
                if not path.is_absolute(fullpath) then
                    fullpath = path.join({ opt.cwd or opt._cwd or vim.uv.cwd(), fullpath })
                end
                local fp = vim.fn.fnameescape(vim.fn.fnamemodify(fullpath, ":p:."))
                vim.notify(string.format("Add %s to harpoon list", fp), 2, { title = "FzF" })
                require("harpoon"):list():add({ value = fp, context = { row = entry.line > 0 and entry.line or 1, col = entry.col or 1 } })
            end
        end

        opts.files = {
            prompt = "Files ❯ ",
            fzf_opts = vim.g.fzf_layout.vertical.fzf_options.with_preview,
            winopts = vim.g.fzf_layout.vertical.window_options.with_preview,
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
                ["ctrl-a"] = add_to_harpoon,
            },
        }

        opts.diagnostics = {
            fzf_opts = vim.g.fzf_layout.vertical.fzf_options.with_preview,
            winopts = vim.g.fzf_layout.vertical.window_options.with_preview,
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
            fzf_opts = vim.g.fzf_layout.vertical.fzf_options.with_preview,
            winopts = vim.g.fzf_layout.vertical.window_options.with_preview,
            multiprocess = true,
            git_icons = false,
            color_icons = true,
            rg_opts = table.concat({
                "--no-messages",
                "--hidden",
                "--follow",
                "--smart-case",
                "--column",
                "--line-number",
                "--no-heading",
                "--color=always",
                "-g=!.git/",
                "-e",
            }, " "),
            rg_glob = true,
            RIPGREP_CONFIG_PATH = vim.env.RIPGREP_CONFIG_PATH,
            glob_flag = "--iglob",
            glob_separator = "%s%-%-",
            no_header = false,
            no_header_i = false,
            actions = {
                ["alt-i"] = { actions.toggle_ignore },
                ["alt-h"] = { actions.toggle_hidden },
            },
        }

        local function git_commit_action(selected, o)
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
                filepath = vim.fn.fnameescape(vim.fn.fnamemodify(fullpath, ":p:."))
            end
            return vim.cmd("Git add " .. filepath) and vim.cmd("Git commit " .. filepath)
        end

        opts.git = {
            status = {
                winopts = vim.g.fzf_layout.horizontal.window_options.no_preview,
                fzf_opts = vim.g.fzf_layout.horizontal.fzf_options.no_preview,
                prompt = "GitStatus❯ ",
                cmd = "git -c color.status=false --no-optional-locks status --porcelain=v1 -u",
                multiprocess = true,
                file_icons = true,
                color_icons = true,
                previewer = "git_diff",
                preview_pager = false,
                actions = {
                    ["right"] = { fn = actions.git_unstage, reload = true },
                    ["left"] = { fn = actions.git_stage, reload = true },
                    ["ctrl-x"] = { fn = actions.git_reset, reload = true },
                    ["ctrl-l"] = {
                        git_commit_action,
                        -- actions.resume,
                    },
                },
            },
        }

        core.ACTION_DEFINITIONS[git_commit_action] = { "commit with message" }
        core.ACTION_DEFINITIONS[add_to_harpoon] = { "add to harponn" }
        config._action_to_helpstr[git_commit_action] = "git_commit"
        config._action_to_helpstr[add_to_harpoon] = "add_to_harpoon"
    end,
}
