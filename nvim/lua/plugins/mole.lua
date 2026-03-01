return {
    "zion-off/mole.nvim",
    keys = {
        "<leader>m",
        "<leader>ma",
        "<leader>ms",
        "<leader>mq",
        "<leader>mr",
        "<leader>mw",
        "<leader>ml",
        "<leader>md",
        "<leader>my",
    },
    opts = {
        session_dir = vim.fn.stdpath("data") .. "/mole",
        capture_mode = "snippet",
        auto_open_panel = true,
        notify = true,
        picker = "snacks",
        session_name = function()
            local ok, result = pcall(vim.fn.system, "git branch --show-current 2>/dev/null")
            local branch = "no-git"
            if ok and result and result ~= "" then
                branch = result:gsub("%s+", "")
                branch = branch:gsub('[/%\\:%*%?"<>|]', "-")
            end
            if branch == "" then
                branch = "no-git"
            end
            return os.date("%Y%m%d%H%M%S") .. "_" .. branch
        end,

        keys = {
            annotate = "<leader>ma",
            start_session = "<leader>ms",
            stop_session = "<leader>mq",
            resume_session = "<leader>mr",
            toggle_window = "<leader>mw",
            jump_to_location = { "<CR>", "gd" },
            next_annotation = "]a",
            prev_annotation = "[a",
        },
        window = { width = 0.35 },
        input = { width = 60, border = vim.o.winborder },
        format = {
            header = function(info)
                local title = info.title or "Untitled Session"
                local cwd = info.cwd or vim.fn.getcwd()
                local timestamp = info.timestamp or os.date("%Y-%m-%d %H:%M:%S")
                local project_name = vim.fn.fnamemodify(cwd, ":t") or cwd

                -- detect git remote
                local ok_remote, remote = pcall(vim.fn.system, "git remote get-url origin 2>/dev/null")
                local repo = ""
                if ok_remote and remote and remote ~= "" then
                    repo = remote:gsub("%s+", ""):match("[:/]([%w%-%.]+/[%w%-%.]+)%.git$")
                        or remote:gsub("%s+", ""):match("[:/]([%w%-%.]+/[%w%-%.]+)$")
                        or ""
                end

                -- detect git branch
                local ok_branch, branch_raw = pcall(vim.fn.system, "git branch --show-current 2>/dev/null")
                local branch = ""
                if ok_branch and branch_raw then
                    branch = branch_raw:gsub("%s+", "")
                end

                -- build frontmatter, skip field kosong via vim.iter
                local fm_lines = vim.iter({
                    { "title", title },
                    { "project", project_name },
                    { "path", cwd },
                    { "repo", repo },
                    { "branch", branch },
                    { "started", timestamp },
                    { "status", "active" },
                    { "tags", "[]" },
                })
                    :filter(function(f)
                        return f[2] ~= nil and f[2] ~= ""
                    end)
                    :map(function(f)
                        return f[1] .. ": " .. f[2]
                    end)
                    :totable()

                -- flatten nested tables jadi satu flat list
                return vim.iter({
                    { "---" },
                    fm_lines,
                    { "---" },
                    { "" },
                    { "# " .. title },
                    { "" },
                    { "## Annotations" },
                    { "" },
                })
                    :flatten()
                    :totable()
            end,

            footer = function(info)
                local timestamp = info.timestamp or os.date("%Y-%m-%d %H:%M:%S")
                return {
                    "",
                    "---",
                    "",
                    "## Summary",
                    "",
                    "<!-- tulis kesimpulanmu di sini -->",
                    "",
                    "*Ended: " .. timestamp .. "*",
                }
            end,

            resumed = function(info)
                local timestamp = info.timestamp or os.date("%Y-%m-%d %H:%M:%S")
                return {
                    "",
                    "---",
                    "",
                    "*Resumed: " .. timestamp .. "*",
                    "",
                }
            end,
        },
    },

    config = function(_, opts)
        local ok_mole, mole = pcall(require, "mole")
        if not ok_mole then
            vim.notify("mole.nvim failed to load: " .. tostring(mole), vim.log.levels.ERROR)
            return
        end

        local ok_setup, err = pcall(mole.setup, opts)
        if not ok_setup then
            vim.notify("mole.setup() failed: " .. tostring(err), vim.log.levels.ERROR)
            return
        end

        local ok_wk, wk = pcall(require, "which-key")
        if ok_wk then
            pcall(wk.add, {
                { "<leader>m", group = " mole" },
                { "<leader>ma", desc = "Annotate selection", mode = "v" },
                { "<leader>ms", desc = "Start session" },
                { "<leader>mq", desc = "Stop session" },
                { "<leader>mr", desc = "Resume session" },
                { "<leader>mw", desc = "Toggle panel" },
                { "<leader>ml", desc = "Annotate current line" },
                { "<leader>md", desc = "Browse sessions" },
                { "<leader>my", desc = "Copy latest session" },
            })
        end

        local function is_mole_active()
            local ok, m = pcall(require, "mole")
            if ok and m.is_active and type(m.is_active) == "function" then
                local active_ok, active = pcall(m.is_active)
                return active_ok and active
            end
            return false
        end

        local function get_mole_dir()
            local dir = vim.fn.stdpath("data") .. "/mole"
            local mkdir_ok, mkdir_err = pcall(vim.fn.mkdir, dir, "p")
            if not mkdir_ok then
                vim.notify("Cannot create mole directory: " .. tostring(mkdir_err), vim.log.levels.ERROR)
                return nil
            end
            return dir
        end

        local function get_session_files()
            local dir = vim.fn.stdpath("data") .. "/mole"
            local ok_glob, files = pcall(vim.fn.globpath, dir, "*.md", false, true)
            if not ok_glob or type(files) ~= "table" then
                return {}
            end
            return files
        end
        -- quick annotate current line
        vim.keymap.set("n", "<leader>ml", function()
            if not is_mole_active() then
                vim.notify("No active mole session. Start one with <leader>ms", vim.log.levels.WARN)
                return
            end
            local ok_exec, exec_err = pcall(function()
                vim.cmd("normal! V")
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>ma", true, false, true), "m", false)
            end)
            if not ok_exec then
                vim.notify("Annotate line failed: " .. tostring(exec_err), vim.log.levels.ERROR)
            end
        end, { desc = "Annotate current line" })

        -- browse sessions via snacks picker
        vim.keymap.set("n", "<leader>md", function()
            local dir = get_mole_dir()
            if not dir then
                return
            end

            local files = get_session_files()
            if #files == 0 then
                vim.notify("No mole sessions found", vim.log.levels.INFO)
                return
            end

            local ok_snacks, snacks = pcall(require, "snacks")
            if ok_snacks and snacks.picker and type(snacks.picker.files) == "function" then
                local ok_pick, pick_err = pcall(snacks.picker.files, { cwd = dir })
                if not ok_pick then
                    vim.notify("Snacks picker failed: " .. tostring(pick_err), vim.log.levels.WARN)
                    vim.cmd("edit " .. vim.fn.fnameescape(dir))
                end
            else
                vim.cmd("edit " .. vim.fn.fnameescape(dir))
            end
        end, { desc = "Browse sessions" })

        -- copy latest session to clipboard
        vim.keymap.set("n", "<leader>my", function()
            local files = get_session_files()
            if #files == 0 then
                vim.notify("No mole sessions found", vim.log.levels.WARN)
                return
            end

            table.sort(files)
            local latest = files[#files]

            local ok_read, lines = pcall(vim.fn.readfile, latest)
            if not ok_read or type(lines) ~= "table" or #lines == 0 then
                vim.notify("Failed to read session: " .. tostring(latest), vim.log.levels.ERROR)
                return
            end

            local content = table.concat(lines, "\n")
            local ok_reg, reg_err = pcall(vim.fn.setreg, "+", content)
            if not ok_reg then
                pcall(vim.fn.setreg, '"', content)
                vim.notify(
                    "Copied to unnamed register (clipboard unavailable): " .. tostring(reg_err),
                    vim.log.levels.WARN
                )
                return
            end

            local filename = vim.fn.fnamemodify(latest, ":t")
            vim.notify("Copied '" .. filename .. "' to clipboard (" .. #lines .. " lines)", vim.log.levels.INFO)
        end, { desc = "Copy latest session" })

        local mole_group = vim.api.nvim_create_augroup("MoleEnhancements", { clear = true })
        vim.api.nvim_create_autocmd("BufEnter", {
            group = mole_group,
            callback = function(ev)
                local bufname = ev.file or ""
                local mole_dir = vim.fn.stdpath("data") .. "/mole"
                local ok_rb, resolved_buf = pcall(vim.fn.resolve, bufname)
                local ok_rd, resolved_dir = pcall(vim.fn.resolve, mole_dir)
                if not ok_rb or not ok_rd then
                    return
                end
                if not (resolved_buf:find(resolved_dir, 1, true) and resolved_buf:match("%.md$")) then
                    return
                end
                pcall(function()
                    vim.opt_local.wrap = true
                    vim.opt_local.linebreak = true
                    vim.opt_local.conceallevel = 2
                    vim.opt_local.spell = false
                    vim.opt_local.number = false
                    vim.opt_local.relativenumber = false
                    vim.opt_local.signcolumn = "no"
                end)
            end,
        })

        -- auto-stop session sebelum quit
        vim.api.nvim_create_autocmd("VimLeavePre", {
            group = mole_group,
            callback = function()
                if not is_mole_active() then
                    return
                end
                local ok_stop, stop_err = pcall(function()
                    require("mole").stop()
                end)
                if not ok_stop then
                    pcall(vim.notify, "Failed to auto-stop mole: " .. tostring(stop_err), vim.log.levels.WARN)
                end
            end,
        })
    end,
}
