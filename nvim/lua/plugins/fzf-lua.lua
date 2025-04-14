return {
    "ibhagwan/fzf-lua",
    keys = {
        {
            "<leader>fd",
            function()
                require("fzf-lua").files({
                    cwd = vim.fn.fnameescape(LazyVim.root({ normalize = true })),
                    fd_opts = [[--color=never --type d --hidden --follow --exclude .git]],
                    find_opts = [[-type d -not -path '*/.git/*' -printf '%P\n']],
                    actions = {
                        ["default"] = function(selected, opts)
                            for i = 1, #selected do
                                local path =
                                    vim.fn.fnameescape(require("fzf-lua.path").entry_to_file(selected[i], opts).path)
                                local ok = pcall(vim.api.nvim_cmd, { cmd = "Oil", args = { path } }, { output = false })
                                if not ok then
                                    vim.notify("[fzf-lua] failed to cd to " .. path, vim.log.levels.WARN)
                                end
                            end
                        end,
                    },
                })
            end,
            desc = "Find Directory (root)",
        },
    },
    opts = function(_, opts)
        local path = require("fzf-lua.path")
        local actions = require("fzf-lua.actions")

        opts.fzf_opts = {
            ["--info"] = "inline-right",
            ["--ansi"] = true,
            ["--no-scrollbar"] = true,
            ["--marker"] = "█",
            ["--pointer"] = "█",
            ["--padding"] = "0,1",
            ["--margin"] = "0",
            ["--highlight-line"] = true,
            ["--border"] = "none",
        }

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

        opts.file_icon_padding = " "
        opts.ui_select = function(fzf_opts, items)
            return vim.tbl_deep_extend("force", fzf_opts, {
                prompt = "  ",
                winopts = {
                    title = " " .. vim.trim((fzf_opts.prompt or "Select"):gsub("%s*:%s*$", "")) .. " ",
                    border = vim.g.border,
                    title_pos = "center",
                },
            }, fzf_opts.kind == "codeaction" and {
                winopts = {
                    layout = "vertical",
                    border = vim.g.border,
                    height = math.floor(math.min(vim.o.lines * 0.8 - 16, #items + 2) + 0.5) + 16,
                    width = 0.7,
                    preview = not vim.tbl_isempty(LazyVim.lsp.get_clients({ bufnr = 0, name = "vtsls" })) and {
                        layout = "vertical",
                        vertical = "down:12,border-top",
                        hidden = "hidden",
                    } or {
                        layout = "vertical",
                        vertical = "down:12,border-top",
                    },
                },
            } or {
                winopts = {
                    width = 0.7,
                    height = math.floor(math.min(vim.o.lines * 0.8, #items + 2) + 0.5),
                },
            })
        end

        opts.fzf_colors = {
            true,
            ["fg"] = { "fg", "CursorLine" },
            ["bg"] = { "bg", "Normal" },
            ["hl"] = { "fg", "LspKindValue" },
            ["fg+"] = { "fg", "Normal" },
            ["bg+"] = { "bg", { "CursorLine", "Normal" } },
            ["hl+"] = { "fg", "Statement" },
            ["info"] = { "fg", "PreProc" },
            ["prompt"] = { "fg", "Conditional" },
            ["pointer"] = { "fg", "Exception" },
            ["marker"] = { "fg", "Keyword" },
            ["spinner"] = { "fg", "Label" },
            ["header"] = { "fg", "Comment" },
            ["gutter"] = "-1",
        }

        opts.hls = {
            border = "Comment",
            preview_border = "Comment",
            title = "MiniHipatternsHack",
            preview_title = "MiniHipatternsTodo",
            header_bind = "FzfLuaFzfPointer",
        }

        opts.defaults = {
            file_icons = "mini",
            cwd_prompt = false,
            formatter = "path.dirname_first",
            headers = { "actions", "cwd" },
        }

        opts.files = {
            prompt = "Files ❯ ",
            winopts = {
                split = string.format("botright %dnew", math.floor(vim.o.lines / 2) - 4),
                preview = { hidden = true },
            },
            fzf_opts = {
                ["--info"] = "inline-right",
                ["--layout"] = "reverse",
                ["--ansi"] = true,
                ["--preview-window"] = "hidden",
                ["--no-preview"] = true,
                ["--border"] = "none",
                ["--marker"] = "█",
                ["--pointer"] = "█",
                ["--padding"] = "0,1",
                ["--margin"] = "0",
                ["--highlight-line"] = true,
            },
            actions = {
                ["ctrl-a"] = function(selected, opt)
                    local cwd = opt.cwd or opt._cwd or LazyVim.root({ normalize = true })
                    for i = 1, #selected do
                        local entry = path.entry_to_file(selected[i], opt)
                        if entry.path == "<none>" then
                            return
                        end

                        local fullpath = path.is_absolute(entry.path) and entry.path or path.join({ cwd, entry.path })
                        local trunc_path = vim.fn.fnamemodify(vim.fs.normalize(vim.fn.fnameescape(fullpath)), ":p:.")
                        vim.notify(string.format("Add %s to harpoon list", trunc_path), 2, { title = "FzF" })
                        require("harpoon"):list():add({
                            value = trunc_path,
                            context = { row = entry.line > 0 and entry.line or 1, col = entry.col or 1 },
                        })
                    end
                end,
            },
        }

        opts.lsp = {
            async_or_timeout = 5000,
            file_icons = true,
            jump1_action = actions.file_edit,
            git_icons = false,
            jump1 = true,
            winopts = {
                height = 0.80,
                width = 0.80,
                row = 0.50,
                col = 0.50,
                preview = {
                    layout = "vertical",
                    vertical = "down:65%",
                },
            },
            fzf_opts = {
                ["--layout"] = "reverse",
                ["--ansi"] = true,
                ["--no-separator"] = false,
                ["--marker"] = "█",
                ["--pointer"] = "█",
                ["--padding"] = "0,1",
                ["--margin"] = "0",
                ["--highlight-line"] = true,
            },
        }
    end,
}
