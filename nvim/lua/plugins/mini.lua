--- mini.nvim: notification UI, icons, cursor-word highlight, key hints.
---
--- Loaded on `VeryLazy` (after `VimEnter`): the editor is fully up, but startup
--- is not blocked and nothing is forced on buffers that never need it.
---
--- mini.notify installs itself as `vim.notify` (the documented usage), which is
--- exactly the primary implementation `core.notify` is designed around; the
--- native notifier keeps working before this plugin loads.
---
--- @class plugins.mini
local M = {}

local SRC = "https://github.com/nvim-mini/mini.nvim"

function M.setup()
    local pack = require("core.pack")
    pack.register({
        src = SRC,
        name = "mini.nvim",
        event = { "VeryLazy" },
        reloadable = true,
        config = M.configure,
    })
end

function M.configure()
    local notify = require("core.notify")

    -- Primary notification UI. `setup()` installs mini's implementation as
    -- `vim.notify`, so `core.notify` (and every plugin using `vim.notify`)
    -- goes through it from now on. Defaults are used deliberately (the option
    -- shapes are mini's documented ones). Headless sessions keep the native
    -- notifier: automation must not need floating notification windows.
    if #vim.api.nvim_list_uis() > 0 then
        require("mini.notify").setup()
    else
        notify.debug("headless session: keeping the native notifier")
    end

    require("mini.icons").setup()
    require("mini.icons").mock_nvim_web_devicons()

    -- Git/diff indicators in the statuscolumn: mini.diff places these signs, and
    -- the statuscolumn renders them through `%s`. The icons come from
    -- `defaults.git` (the same ones used for the statusline summary).
    local git = require("core.defaults").get("git", {})
    local signs = git.signs or {}
    require("mini.diff").setup({
        view = {
            signs = {
                add = signs.add or "│",
                change = signs.change or "│",
                delete = signs.delete or "│",
            },
        },
    })

    -- Git/diff indicators in the statusline: mini.diff documents overriding
    -- `vim.b.minidiff_summary_string` on `User MiniDiffUpdated` for custom
    -- formatting; the counts live in `vim.b.minidiff_summary`.
    local git_icons = require("core.defaults").get("git", {})
    vim.api.nvim_create_autocmd("User", {
        pattern = "MiniDiffUpdated",
        group = vim.api.nvim_create_augroup("core_minidiff_icons", { clear = true }),
        desc = "mini.diff: statusline summary with the configured icons",
        callback = function(data)
            local summary = vim.b[data.buf].minidiff_summary
            if not summary then
                return
            end
            local parts = {}
            if summary.add > 0 then
                parts[#parts + 1] = (git_icons.added or "+") .. summary.add
            end
            if summary.change > 0 then
                parts[#parts + 1] = (git_icons.modified or "~") .. summary.change
            end
            if summary.delete > 0 then
                parts[#parts + 1] = (git_icons.removed or "-") .. summary.delete
            end
            vim.b[data.buf].minidiff_summary_string = table.concat(parts, " ")
        end,
    })

    require("mini.cursorword").setup({ delay = 100 })

    -- UI modules from the same repository, configured from the same pack spec
    -- (one repository = one load = one config).
    local ui = require("core.defaults").get("ui", {})
    require("mini.git").setup() -- branch for the statusline git section
    require("plugins.mini_statusline").setup(ui.statusline)
    -- `'statuscolumn'` is native now (core.statuscolumn): marks are per-line data
    -- that mini.statuscolumn cannot render, and its pre-computed content buys us
    -- nothing here.
    require("core.statuscolumn").setup()

    require("mini.clue").setup({
        triggers = {
            { mode = "n", keys = "<Leader>" },
            { mode = "x", keys = "<Leader>" },
            { mode = "n", keys = "g" },
            { mode = "n", keys = "z" },
            { mode = "n", keys = "[" },
            { mode = "n", keys = "]" },
            { mode = "n", keys = "<C-w>" },
            { mode = "i", keys = "<C-x>" },
        },
        clues = {
            require("mini.clue").gen_clues.builtin_completion(),
            require("mini.clue").gen_clues.g(),
            require("mini.clue").gen_clues.marks(),
            require("mini.clue").gen_clues.registers(),
            require("mini.clue").gen_clues.windows(),
            require("mini.clue").gen_clues.z(),
            { mode = "n", keys = "<Leader>u", desc = "+toggle" },
            { mode = "n", keys = "<Leader>t", desc = "+terminal" },
            { mode = "n", keys = "<Leader>g", desc = "+git" },
            { mode = "n", keys = "<Leader>c", desc = "+code" },
        },
        window = {
            config = { width = "auto" },
            -- mini.clue's own default is 1000 ms (see defaults.ui_clue.delay).
            delay = require("core.defaults").get("ui_clue.delay", 300),
        },
    })

    -- Cursor-word toggle: mini.cursorword decides per buffer through
    -- `vim.b.minicursorword_disable`, so the toggle is genuinely buffer-local and
    -- reads back the plugin's own state instead of shadowing it.
    local ok, err = require("core.toggle").attach("cursorword", {
        get = function(ctx)
            return not vim.b[ctx.bufnr].minicursorword_disable
        end,
        set = function(value, ctx)
            if value then
                vim.b[ctx.bufnr].minicursorword_disable = nil
            else
                vim.b[ctx.bufnr].minicursorword_disable = true
            end
        end,
    })
    if not ok then
        notify.error("mini.lua: cannot attach cursorword toggle: " .. tostring(err))
    end
end

function M.teardown()
    -- mini modules manage their own augroups; re-running `setup()` on reload is
    -- supported, so only the toggle implementation has to be detached.
    require("core.toggle").attach("cursorword", nil)
end

return M
