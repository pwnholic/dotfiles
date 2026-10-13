-- nvim-dap-ui: RIGHT-side vertical layout + responsive behavior.
--
-- WHY THIS FILE EXISTS (root causes of "UI tidak responsive"):
--   1. Upstream default is `position = "left"`, fixed `size = 40` columns
--      plus per-element FRACTIONS (0.25 each). `WindowLayout:resize()` only
--      re-applies `area_state.size` + win fractions when open/resize runs -
--      there is NO `VimResized` hook upstream, so after `tmux split` /
--      font zoom / window drag, the sidebar keeps its stale pixel width
--      and overflows on narrow screens.
--   2. `dapui.open()` calls `win_layout:resize(args)` with args lacking
--      `reset`, so once you (or a plugin) manually drag a DAP window edge,
--      `win_state.size` stays captured forever - reopening never restores
--      the intended proportions.
--   3. `winfixwidth`/`winfixheight` are force-set on every DAP window
--      (`windows/layout.lua:_init_win_settings`), which blocks Neovim's
--      `equalalways` rebalancer from touching them. Without an explicit
--      re-layout pass, they freeze while the rest of the editor moves.
--
-- WHAT THIS FILE DOES:
--   - Moves the sidebar to `position = "right"`, sized as a FRACTION
--     (`0.25 * columns`) so `resize()` recomputes columns on every open.
--     (Float < 1 = proportional; see `WindowLayout:resize` upstream.)
--   - Shrinks the tray (repl/console) to a `0.25 * lines` fraction so it
--     also scales with terminal height.
--   - `VimResized` autocmd resizes OPEN layouts only (`resize({reset=true})`
--     per open layout). It deliberately never calls `dapui.open()` without a
--     `layout` arg: that would re-open layouts the user closed on purpose
--     (e.g. via `<leader>du`).
--   - `VimResized` fires at most ~every 200ms via a shared debounce timer
--     (it bursts on every pixel during a tmux drag); stale requests are
--     superseded, never queued.
--   - The merge-SAFE pattern: `opts = function(_, opts)` CHAIN-runs after
--     LazyVim's own (empty) `opts`, mutating the merged table in place.
--     Our `opts.layouts` replaces the default wholesale (upstream keeps a
--     user-supplied `config.layouts` as-is - no deep-merge leftovers).
--     NOTE: `config` below REPLACES LazyVim's dap-ui `config` (lazy.nvim
--     keeps only the last `config` fn), so its body replicates LazyVim's
--     verbatim: `dapui.setup(opts)` + auto open/close listeners.
--
-- EDGE CASES:
--   - Narrow screens (< 91 cols): 0.25 would squeeze the code window, so
--     the sidebar drops to a fixed 20 cols (still >= dapui's own minimum
--     of ~17 for signcolumn+content). Tray keeps max 8 lines.
--   - Manual drags are captured via `update_sizes()` inside upstream
--     `open()`/`close()`; only `VimResized` forces `reset = true`.
local SIDEBAR_RATIO = 0.25
local SIDEBAR_MIN_COLS = 20
local TRAY_RATIO = 0.25
local TRAY_MAX_LINES = 8
local RESIZE_DEBOUNCE_MS = 200

--- Error-safe access to the upstream layout list. Nil when DAP UI was never
--- set up (e.g. no debug session started yet) - the VimResized handler
--- treats that as a silent no-op, never an error.
---@return table|nil
local function ui_layouts()
    local ok, mod = pcall(require, "dapui.windows")
    if not ok or type(mod.layouts) ~= "table" or #mod.layouts == 0 then
        return nil
    end
    return mod.layouts
end

--- Reset every OPEN layout to its responsive size for the CURRENT
--- terminal geometry. Closed layouts are never touched (unlike
--- `dapui.open()` with no args, which opens all). Narrow screens get the
--- fixed-width branch; wide screens restore the ratio branch.
---@param layouts table
local function reset_open_layouts(layouts)
    local narrow = vim.o.columns < (SIDEBAR_MIN_COLS / SIDEBAR_RATIO)
    for _, layout in ipairs(layouts) do
        if layout:is_open() then
            if layout.layout_type == "vertical" then
                layout.area_state.init_size = narrow and SIDEBAR_MIN_COLS or SIDEBAR_RATIO
                for _, win_state in ipairs(layout.win_states) do
                    win_state.init_size = nil
                end
                for i, s in ipairs({ 0.30, 0.20, 0.25, 0.25 }) do
                    if layout.win_states[i] then
                        layout.win_states[i].init_size = s
                    end
                end
            else
                layout.area_state.init_size = narrow and TRAY_MAX_LINES or TRAY_RATIO
            end
            layout:resize({ reset = true })
        end
    end
end

local function responsive_layouts()
    if vim.o.columns < (SIDEBAR_MIN_COLS / SIDEBAR_RATIO) then
        return {
            {
                elements = {
                    { id = "scopes", size = 0.30 },
                    { id = "breakpoints", size = 0.20 },
                    { id = "stacks", size = 0.25 },
                    { id = "watches", size = 0.25 },
                },
                size = SIDEBAR_MIN_COLS,
                position = "right",
            },
            {
                elements = { "repl", "console" },
                size = TRAY_MAX_LINES,
                position = "bottom",
            },
        }
    end
    return {
        {
            elements = {
                { id = "scopes", size = 0.30 },
                { id = "breakpoints", size = 0.20 },
                { id = "stacks", size = 0.25 },
                { id = "watches", size = 0.25 },
            },
            size = SIDEBAR_RATIO,
            position = "right",
        },
        {
            elements = { "repl", "console" },
            size = TRAY_RATIO,
            position = "bottom",
        },
    }
end

return {
    {
        "rcarriga/nvim-dap-ui",
        opts = function(_, opts)
            opts.layouts = responsive_layouts()
            -- Roomier value rendering: default trims at 100 lines; values
            -- longer than that still wrap inside the (now narrower-on-small
            -- -screens) sidebar, this just stops premature trimming.
            opts.render = opts.render or {}
            opts.render.max_value_lines = 200
            -- Nicer float windows for `dapui.float_element` / eval.
            opts.floating = opts.floating or {}
            opts.floating.max_width = 0.85
            opts.floating.max_height = 0.8
            opts.floating.border = vim.o.winborder
        end,
        config = function(_, opts)
            -- See header NOTE: this replaces LazyVim's dap-ui `config`, so
            -- replicate its body (setup + auto open/close listeners) here.
            -- Kept in sync with LazyVim `extras/dap/core.lua`.
            local dap, dapui = require("dap"), require("dapui")
            dapui.setup(opts)
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open({})
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close({})
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close({})
            end

            local timer = assert(vim.uv.new_timer(), "dap-ui: failed to create resize timer")
            local group = vim.api.nvim_create_augroup("dapui_responsive", { clear = true })
            vim.api.nvim_create_autocmd("VimResized", {
                group = group,
                desc = "Re-apply proportional DAP UI layouts on terminal geometry change",
                callback = function()
                    timer:start(RESIZE_DEBOUNCE_MS, 0, function()
                        timer:stop()
                        vim.schedule(function()
                            local layouts = ui_layouts()
                            if not layouts then
                                return
                            end
                            local cmdheight = vim.o.cmdheight
                            reset_open_layouts(layouts)
                            vim.o.cmdheight = cmdheight
                        end)
                    end)
                end,
            })
        end,
    },
}
