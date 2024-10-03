local M = {}
---@alias nvim_direction_t 'h'|'j'|'k'|'l'

local function tmux_get_socket()
    return vim.split(vim.env.TMUX, ",")[1]
end

function M.tmux_exec(command, global)
    command = global and string.format("tmux %s", command) or string.format("tmux -S %s %s", tmux_get_socket(), command)
    local handle = assert(io.popen(command), string.format("Unable to execute: [%s]", command))
    local result = handle:read("*a")
    handle:close()
    return result
end

function M.tmux_get_pane_opt(opt)
    return (M.tmux_exec(string.format("display-message -pt %s '#{%s}'", vim.env.TMUX_PANE, vim.fn.escape(opt, "'\\"))):gsub("\n.*", ""))
end

local function tmux_is_zoomed()
    return M.tmux_get_pane_opt("window_zoomed_flag") == "1"
end

local tmux_pane_position_map = { h = "left", j = "bottom", k = "top", l = "right" }

local function tmux_at_border(direction)
    return M.tmux_get_pane_opt("pane_at_" .. tmux_pane_position_map[direction]) == "1"
end

local function tmux_should_move(direction)
    return not tmux_is_zoomed() and not tmux_at_border(direction)
end

local tmux_direction_map = {
    h = "L",
    j = "D",
    k = "U",
    l = "R",
}

local function tmux_navigate(direction, count)
    count = count or 1
    for _ = 1, count do
        M.tmux_exec(string.format("select-pane -t '%s' -%s", vim.env.TMUX_PANE, tmux_direction_map[direction]))
    end
end

local function nvim_at_border(direction)
    return vim.fn.winnr() == vim.fn.winnr(direction)
end

local function nvim_navigate(direction, count)
    vim.cmd.wincmd({ direction, count = count })
end

local function navigate(direction, count)
    count = count or 1
    if (nvim_at_border(direction)) and tmux_should_move(direction) then
        tmux_navigate(direction, count)
    else
        nvim_navigate(direction, count)
    end
end

function M.navigate_wrap(direction)
    return function()
        navigate(direction, vim.v.count1)
    end
end

return M
