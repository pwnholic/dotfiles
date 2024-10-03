local M = {}

---@alias nvim_direction_t 'h'|'j'|'k'|'l'
---@alias tmux_direction_t 'L'|'D'|'U'|'R'
---@alias tmux_borderpane_direction_t 'left'|'bottom'|'top'|'right'

---@param command string tmux command to execute
---@param global boolean? command should be executed globally instead of in current pane
---@return string tmux command output
function M.tmux_exec(command, global)
    command = global and string.format("tmux %s", command) or string.format("tmux -S %s %s", vim.split(vim.env.TMUX, ",")[1], command)
    local handle = assert(io.popen(command), string.format("[tmux-nav]: unable to execute: [%s]", command))
    local result = handle:read("*a")
    handle:close()
    return result
end

---Get tmux option value in current pane
---@param opt string tmux pane option
---@return string tmux pane option value
function M.tmux_get_pane_opt(opt)
    return (M.tmux_exec(string.format("display-message -pt %s '#{%s}'", vim.env.TMUX_PANE, vim.fn.escape(opt, "'\\"))):gsub("\n.*", ""))
end

---@return boolean
local function tmux_is_zoomed()
    return M.tmux_get_pane_opt("window_zoomed_flag") == "1"
end

---@type table<nvim_direction_t, tmux_borderpane_direction_t>
local tmux_pane_position_map = { h = "left", j = "bottom", k = "top", l = "right" }

---@param direction nvim_direction_t
---@return boolean
local function tmux_at_border(direction)
    return M.tmux_get_pane_opt("pane_at_" .. tmux_pane_position_map[direction]) == "1"
end

---@param direction nvim_direction_t
---@return boolean
local function tmux_should_move(direction)
    return not tmux_is_zoomed() and not tmux_at_border(direction)
end

---@type table<nvim_direction_t, tmux_direction_t>
local tmux_direction_map = { h = "L", j = "D", k = "U", l = "R" }

---@param direction nvim_direction_t
---@param count integer? default to 1
---@return nil
local function tmux_navigate(direction, count)
    count = count or 1
    for _ = 1, count do
        M.tmux_exec(string.format("select-pane -t '%s' -%s", vim.env.TMUX_PANE, tmux_direction_map[direction]))
    end
end

---@param direction nvim_direction_t
---@param count integer? default to 1
---@return nil
local function navigate(direction, count)
    count = count or 1
    if (vim.fn.winnr() == vim.fn.winnr(direction) or vim.fn.win_gettype() == "popup") and tmux_should_move(direction) then
        tmux_navigate(direction, count)
    else
        vim.cmd.wincmd({ direction, count = count })
    end
end

---@param direction nvim_direction_t
---@return function: rhs of a window navigation keymap
function M.navigate_wrap(direction)
    return function()
        navigate(direction, vim.v.count1)
    end
end

---@return boolean
local function tmux_mapkey_default_condition()
    return not tmux_is_zoomed()
        and #vim.tbl_filter(function(win)
                return vim.fn.win_gettype(win) ~= "popup"
            end, vim.api.nvim_tabpage_list_wins(0))
            <= 1
end

---@return boolean
function M.tmux_mapkey_close_win_condition()
    return not tmux_is_zoomed()
        and #vim.tbl_filter(function(win)
            return vim.fn.win_gettype(win) ~= "popup"
        end, vim.api.nvim_list_wins()) <= 1
end

---@return boolean
function M.tmux_mapkey_resize_pane_horiz_condition()
    return not tmux_is_zoomed() and (vim.fn.winnr() == vim.fn.winnr("l") and (vim.fn.winnr() == vim.fn.winnr("h") or not tmux_at_border("l")))
end

---@return boolean
function M.tmux_mapkey_resize_pane_vert_condition()
    return not tmux_is_zoomed() and (vim.fn.winnr() == vim.fn.winnr("j") and (vim.fn.winnr() == vim.fn.winnr("k") or not tmux_at_border("j")))
end

---@return fun(): boolean
function M.tmux_mapkey_navigate_condition(direction)
    return function()
        return (vim.fn.winnr() == vim.fn.winnr(direction) or vim.fn.win_gettype() == "popup") and tmux_should_move(direction)
    end
end

---@class keymap_def_t
---@field lhs string
---@field lhsraw string
---@field rhs string?
---@field callback function?
---@field expr boolean?
---@field desc string?
---@field noremap boolean?
---@field script boolean?
---@field silent boolean?
---@field nowait boolean?
---@field buffer boolean?
---@field replace_keycodes boolean?

---Get keymap definition
---@param mode string
---@param lhs string
---@return keymap_def_t
local function get_keys(mode, lhs)
    local lhs_keycode = vim.keycode(lhs)
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
        if vim.keycode(map.lhs) == lhs_keycode then
            return {
                lhs = map.lhs,
                rhs = map.rhs,
                expr = map.expr == 1,
                callback = map.callback,
                desc = map.desc,
                noremap = map.noremap == 1,
                script = map.script == 1,
                silent = map.silent == 1,
                nowait = map.nowait == 1,
                buffer = true,
                replace_keycodes = map.replace_keycodes == 1,
            }
        end
    end
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
        if vim.keycode(map.lhs) == lhs_keycode then
            return {
                lhs = map.lhs,
                rhs = map.rhs or "",
                expr = map.expr == 1,
                callback = map.callback,
                desc = map.desc,
                noremap = map.noremap == 1,
                script = map.script == 1,
                silent = map.silent == 1,
                nowait = map.nowait == 1,
                buffer = false,
                replace_keycodes = map.replace_keycodes == 1,
            }
        end
    end
    return {
        lhs = lhs,
        rhs = lhs,
        expr = false,
        noremap = true,
        script = false,
        silent = true,
        nowait = false,
        buffer = false,
        replace_keycodes = true,
    }
end

---@param def keymap_def_t
---@return function
local function keys_fallback_fn(def)
    local modes = def.noremap and "in" or "im"
    ---@param keys string
    ---@return nil
    local function feed(keys)
        local keycode = vim.keycode(keys)
        local keyseq = vim.v.count > 0 and vim.v.count .. keycode or keycode
        vim.api.nvim_feedkeys(keyseq, modes, false)
    end
    if not def.expr then
        return def.callback or function()
            feed(def.rhs)
        end
    end
    if def.callback then
        return function()
            feed(def.callback())
        end
    else
        -- Escape rhs to avoid nvim_eval() interpreting
        -- special characters
        local rhs = vim.fn.escape(def.rhs, "\\")
        return function()
            feed(vim.api.nvim_eval(rhs))
        end
    end
end

---Amend keymap
---Caveat: currently cannot amend keymap with <Cmd>...<CR> rhs
---@param modes string[]|string
---@param lhs string
---@param rhs function(fallback: function)
---@param opts table?
---@return nil
local function ammend_keys(modes, lhs, rhs, opts)
    modes = type(modes) ~= "table" and { modes } or modes --[=[@as string[]]=]
    for _, mode in ipairs(modes) do
        local fallback = keys_fallback_fn(get_keys(mode, lhs))
        vim.keymap.set(mode, lhs, function()
            rhs(fallback)
        end, opts)
    end
end

local TUI_REGEX = vim.regex(
    [[\v^(sudo(\s+--?(\w|-)+((\s+|\=)\S+)?)*\s+)?]]
        .. [[(/usr/bin/)?]]
        .. [[(n?vim?|vimdiff|emacs(client)?|lem|nano]]
        .. [[|helix|kak|tmux|lazygit|h?top|gdb|fzf|nmtui|sudoedit|ssh|crontab)]]
)

---Get the command running in the foreground in the terminal buffer 'buf'
---@param buf integer? terminal buffer handler, default to 0 (current)
---@return string[]: command running in the foreground
local function foground_cmds(buf)
    buf = buf or 0
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].bt ~= "terminal" then
        return {}
    end
    local channel = vim.bo[buf].channel
    local chan_valid, pid = pcall(vim.fn.jobpid, channel)
    if not chan_valid then
        return {}
    end

    local cmds = {}
    for _, stat_cmd_str in ipairs(vim.split(vim.fn.system("ps h -o stat,args -g " .. pid), "\n", { trimempty = true })) do
        local stat, cmd = unpack(vim.split(stat_cmd_str, "%s+", { trimempty = true }))
        if stat:find("^%w+%+") then
            table.insert(cmds, cmd)
        end
    end

    return cmds
end

---Check if any of the processes in terminal buffer `buf` is a TUI app
---@param buf integer? buffer handler
---@return boolean?
local function validate_running_tui(buf)
    local cmds = foground_cmds(buf)
    for _, cmd in ipairs(cmds) do
        if TUI_REGEX:match_str(cmd) then
            return true
        end
    end
    return false
end

---Map a key in normal and visual mode to a tmux command with fallback
---@param key string
---@param action string|function
---@param condition? fun(): boolean
---@return nil
function M.tmux_mapkey_fallback(key, action, condition)
    condition = condition or tmux_mapkey_default_condition
    ammend_keys({ "n", "x", "t" }, key, function(fallback)
        if not condition() or vim.env.NVIM or vim.fn.mode():sub(1, 1) == "t" and validate_running_tui() then
            fallback()
            return
        end
        if type(action) == "string" then
            M.tmux_exec(action)
            return
        end
        action()
    end)
end

return M
