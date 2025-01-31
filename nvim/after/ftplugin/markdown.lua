---@diagnostic disable: missing-fields
vim.opt_local.number = false
vim.opt_local.relativenumber = false
vim.opt_local.signcolumn = "no"
vim.opt_local.stc = ""
vim.opt_local.foldmethod = "expr"

local job_ok, Job = pcall(require, "plenary.job")
if not job_ok then
    return vim.notify("Could find planery module", 2, { title = "Markdown" })
end

local note_ok, note_path = pcall(os.getenv, "HOME")
if not note_ok then
    return vim.notify("Could not find note path", 2, { title = "Markdown" })
end

note_path = string.format("%s/Notes", note_path)

local function run_job(cmd, args, on_exit)
    return coroutine.wrap(function()
        local job = Job:new({
            command = cmd,
            args = args,
            cwd = note_path,
            on_exit = on_exit or function() end,
        })
        if not on_exit then
            return job:sync()
        else
            return job:start()
        end
    end)()
end

local function git_sync(path)
    if os.getenv("PWD") ~= path then
        vim.notify("Should be on note directory", vim.log.levels.ERROR)
        return
    end
    return coroutine.wrap(function()
        local git_user = run_job("git", { "config", "user.name" })
        if not git_user or git_user[1] ~= "pwnholic" then
            vim.notify(
                "Git user mismatch: expected 'pwnholic', found '" .. (git_user[1] or "unknown") .. "'",
                vim.log.levels.ERROR
            )
            return
        end

        local porcelain = run_job("git", { "status", "--porcelain" })
        if #porcelain == 0 then
            vim.notify("No changes to sync", vim.log.levels.INFO, { title = "Markdown" })
            return
        end

        local pull_result = run_job("git", { "pull", "--all" })
        if #pull_result == 0 then
            vim.notify("Git pull failed", vim.log.levels.ERROR)
            return
        end
        vim.notify("Git pull succeeded", vim.log.levels.INFO)

        run_job("git", { "add", "." }, function(j, return_val)
            if return_val ~= 0 then
                vim.notify("Git stage failed: " .. table.concat(j:stderr_result(), "\n"), vim.log.levels.ERROR)
            else
                vim.notify("Changes staged successfully", vim.log.levels.INFO)
            end
        end)

        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local commit_result = run_job("git", { "commit", "-m", "vault backup: " .. timestamp })
        if #commit_result == 0 then
            vim.notify("Git commit failed", vim.log.levels.ERROR)
            return
        end
        vim.notify("Changes committed successfully", vim.log.levels.INFO)

        run_job("git", { "push" }, function(j, return_val)
            if return_val ~= 0 then
                vim.notify("Git push failed: " .. table.concat(j:stderr_result(), "\n"), vim.log.levels.ERROR)
            else
                vim.notify("Git push succeeded", vim.log.levels.INFO)
            end
        end)
    end)()
end

local enabled = false
local interval = 1 * 60000 -- 1 minutes
vim.keymap.set("n", "<leader>ou", function()
    if not enabled then
        enabled = true
        vim.notify("Git sync enabled", 2, { title = "Markdown" })
        vim.cmd.update({ mods = { emsg_silent = true } })
        local timer = vim.uv.new_timer()
        assert(timer, "Must be able to create timer")
        timer:start(
            interval,
            interval,
            vim.schedule_wrap(function()
                git_sync(note_path)
            end)
        )
        return timer
    else
        enabled = false
        return vim.notify("Git sync disabled", 2, { title = "Markdown" })
    end
end, { desc = "Toggle Git Sync" })

vim.api.nvim_create_user_command("MarkGitSync", function()
    git_sync(note_path)
end, {})

vim.keymap.set("n", "<leader>op", function()
    if vim.uv.cwd() == note_path then
        return run_job("xdg-open", {
            string.format(
                "obsidian://%s&path=%s",
                note_path:gsub("([^%w%-%._~])", function(c)
                    return string.format("%%%02X", string.byte(c))
                end),
                vim.api.nvim_buf_get_name(0):gsub("([^%w%-%._~])", function(c)
                    return string.format("%%%02X", string.byte(c))
                end)
            ),
        }, function(j, return_val)
            if return_val ~= 0 then
                vim.notify("Filed to open obsidian: " .. table.concat(j:stderr_result(), "\n"), vim.log.levels.ERROR)
            end
        end)
    else
        return vim.notify(string.format("Path should be on %s", note_path), 2, { title = "Markdown" })
    end
end, { desc = "Open in Obsidian Vault" })
