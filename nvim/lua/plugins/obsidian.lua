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
        local update_interval_mins = 1 -- in minutes

        local function get_git_user()
            local result = nil
            Job:new({
                command = "git",
                args = { "config", "user.name" },
                on_exit = function(j, return_val)
                    if return_val == 0 then
                        result = j:result()[1]
                    end
                end,
            }):sync() -- Use sync to ensure the result is available
            return result
        end

        local function pull_changes()
            Job:new({
                command = "git",
                args = { "pull" },
                cwd = note_path,
                on_exit = function(j, return_val)
                    if return_val ~= 0 then
                        vim.notify("git pull failed: " .. table.concat(j:stderr_result(), "\n"), vim.log.levels.ERROR)
                    else
                        vim.notify("git pull succeeded", vim.log.levels.INFO)
                    end
                end,
            }):start()
        end

        local function push_changes()
            vim.notify("Pushing updates...", vim.log.levels.INFO)
            Job:new({
                command = "git",
                args = { "push" },
                cwd = note_path,
                on_exit = function(j, return_val)
                    if return_val ~= 0 then
                        vim.notify("git push failed: " .. table.concat(j:stderr_result(), "\n"), vim.log.levels.ERROR)
                    else
                        vim.notify("git push succeeded", vim.log.levels.INFO)
                    end
                end,
            }):start()
        end

        local function commit_changes()
            local timestamp = os.date("%Y-%m-%d %H:%M:%S")
            Job:new({
                command = "git",
                args = { "commit", "-m", "vault backup: " .. timestamp },
                cwd = note_path,
                on_exit = function(j, return_val)
                    if return_val == 0 then
                        push_changes()
                    else
                        local msg = f("Error committing changes: %s", table.concat(j:stderr_result(), "\n"))
                        vim.notify(msg, vim.log.levels.ERROR)
                    end
                end,
            }):start()
        end

        local function stage_changes()
            vim.notify("Performing git sync...", vim.log.levels.INFO)
            Job:new({
                command = "git",
                args = { "add", "." },
                cwd = note_path,
                on_exit = function(j, return_val)
                    if return_val == 0 then
                        commit_changes()
                    else
                        local msg = f("Error staging changes: %s", table.concat(j:stderr_result(), "\n"))
                        vim.notify(msg, vim.log.levels.ERROR)
                    end
                end,
            }):start()
        end

        local function stage_and_pull()
            Job
                :new({
                    command = "git",
                    args = { "status", "--porcelain" },
                    cwd = note_path,
                    on_exit = function(j, _)
                        local result = j:result()
                        if #result == 0 then
                            vim.notify("No changes to sync", vim.log.levels.INFO, { title = "Obsidian.nvim" })
                        else
                            vim.notify("Changes detected. Syncing...", vim.log.levels.INFO, { title = "Obsidian.nvim" })
                            coroutine.wrap(function()
                                stage_changes()
                                pull_changes()
                            end)()
                        end
                    end,
                })
                :start()
        end

        local git_sync_enabled = false
        vim.keymap.set("n", "<leader>ou", function()
            if not git_sync_enabled then
                git_sync_enabled = true
                vim.notify("Git sync enabled", 2, { title = "Obsidian.nvim" })
                vim.cmd.update({ mods = { emsg_silent = true } })
                local interval = update_interval_mins * 60000
                local timer = vim.uv.new_timer()
                assert(timer, "Must be able to create timer")
                timer:start(
                    interval,
                    interval,
                    vim.schedule_wrap(function()
                        if get_git_user() ~= "pwnholic" then
                            vim.notify("Unauthorized user. Git operations are disabled.", vim.log.levels.ERROR)
                            return
                        else
                            if os.getenv("PWD") == note_path then
                                return stage_and_pull()
                            end
                        end
                    end)
                )
                return timer
            else
                git_sync_enabled = false
                return vim.notify("Git sync disabled", 2, { title = "Obsidian.nvim" })
            end
        end, { desc = "Toggle Git Sync" })

        vim.api.nvim_create_user_command("ObsidianGitSync", function()
            if get_git_user() ~= "pwnholic" then
                vim.notify("Unauthorized user. Git operations are disabled.", vim.log.levels.ERROR)
                return
            else
                if os.getenv("PWD") == note_path then
                    return stage_and_pull()
                end
            end
        end, {})
    end,
}
