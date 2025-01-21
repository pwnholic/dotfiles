---@diagnostic disable: missing-fields
local ok, note_path = pcall(os.getenv, "HOME")
if not ok then
    return vim.notify("Could not find note path", 2, { title = "Obsidian" })
end

local f = string.format
note_path = f("%s/Notes", note_path)

return {
    "epwalsh/obsidian.nvim",
    version = "*",
    ft = "markdown",
    keys = {
        { "<leader>on", "<cmd>ObsidianOpen<cr>", desc = "Open Obsidian App" },
    },
    opts = {
        wiki_link_func = "prepend_note_path",
        new_notes_location = "current_dir",
        open_notes_in = "current",
        preferred_link_style = "wiki",
        disable_frontmatter = true,
        workspaces = { { name = "Local", path = note_path } },
        daily_notes = { folder = "00 Inbox", template = nil },
        completion = { nvim_cmp = false },
        templates = { folder = "40 Templates" },
        ui = { enable = false },
        note_id_func = function(title)
            local suffix = ""
            if title ~= nil then
                suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
            else
                for _ = 1, 4 do
                    suffix = suffix .. string.char(math.random(65, 90))
                end
            end
            return tostring(os.time()) .. "-" .. suffix
        end,
    },
    config = function(_, opts)
        require("obsidian").setup(opts)
        local Job = require("plenary.job")

        local function run_job(cmd, args, on_exit)
            return coroutine.wrap(function()
                local job = Job:new({
                    command = cmd,
                    args = args,
                    cwd = note_path,
                    on_exit = on_exit or function() end,
                })

                if not on_exit then
                    return job:sync() -- Sinkron jika on_exit tidak diberikan
                else
                    return job:start() -- Asinkron jika on_exit diberikan
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
                    vim.notify("No changes to sync", vim.log.levels.INFO, { title = "Obsidian.nvim" })
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
                vim.notify("Git sync enabled", 2, { title = "Obsidian.nvim" })
                vim.cmd.update({ mods = { emsg_silent = true } })
                local timer = vim.uv.new_timer()
                assert(timer, "Must be able to create timer")
                -- stylua: ignore start
                timer:start(interval, interval, vim.schedule_wrap(function() git_sync(note_path) end))
                return timer
            else
                enabled = false
                return vim.notify("Git sync disabled", 2, { title = "Obsidian.nvim" })
            end
        end, { desc = "Toggle Git Sync" })

        vim.api.nvim_create_user_command("ObsidianGitSync", function()
            git_sync(note_path)
        end, {})
    end,
}
