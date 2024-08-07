local M = {}

---@alias nvim_direction_t 'h'|'j'|'k'|'l'
---@alias tmux_direction_t 'L'|'D'|'U'|'R'
---@alias tmux_borderpane_direction_t 'left'|'bottom'|'top'|'right'

---@return string tmux socket path
local function tmux_get_socket()
	return vim.split(vim.env.TMUX, ",")[1]
end

---@param command string tmux command to execute
---@param global boolean? command should be executed globally instead of in current pane
---@return string tmux command output
local function tmux_exec(command, global)
	command = global and string.format("tmux %s", command) or string.format("tmux -S %s %s", tmux_get_socket(), command)
	local handle = assert(io.popen(command), string.format("[tmux-nav]: unable to execute: [%s]", command))
	local result = handle:read("*a")
	handle:close()
	return result
end

---Get tmux option value in current pane
---@param opt string tmux pane option
---@return string tmux pane option value
function M.tmux_get_pane_opt(opt)
	return (
		tmux_exec(string.format("display-message -pt %s '#{%s}'", vim.env.TMUX_PANE, vim.fn.escape(opt, "'\\"))):gsub(
			"\n.*",
			""
		)
	)
end

---Set tmux option value in current pane
---@param opt string tmux pane option
---@param val string tmux pane option value
---@return nil
function M.tmux_set_pane_opt(opt, val)
	tmux_exec(string.format("set -pt %s %s '%s'", vim.env.TMUX_PANE, opt, vim.fn.escape(val, "'\\")))
end

---Unset a tmux pane option
---@param opt string tmux pane option
---@return nil
function M.tmux_unset_pane_opt(opt)
	tmux_exec(string.format("set -put %s '%s'", vim.env.TMUX_PANE, vim.fn.escape(opt, "'\\")))
end

---@return boolean
local function tmux_is_zoomed()
	return M.tmux_get_pane_opt("window_zoomed_flag") == "1"
end

---@type table<nvim_direction_t, tmux_borderpane_direction_t>
local tmux_pane_position_map = {
	h = "left",
	j = "bottom",
	k = "top",
	l = "right",
}

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
local tmux_direction_map = {
	h = "L",
	j = "D",
	k = "U",
	l = "R",
}

---@param direction nvim_direction_t
---@param count integer? default to 1
---@return nil
local function tmux_navigate(direction, count)
	count = count or 1
	for _ = 1, count do
		tmux_exec(string.format("select-pane -t '%s' -%s", vim.env.TMUX_PANE, tmux_direction_map[direction]))
	end
end

---@param direction nvim_direction_t
---@return boolean
local function nvim_at_border(direction)
	return vim.fn.winnr() == vim.fn.winnr(direction)
end

---@return boolean
local function nvim_in_floating_win()
	return vim.fn.win_gettype() == "popup"
end

---Check if nvim has only one window in current session
---@return boolean
local function nvim_has_only_win()
	return #vim.tbl_filter(function(win)
		return vim.fn.win_gettype(win) ~= "popup"
	end, vim.api.nvim_list_wins()) <= 1
end

---Check if nvim has only one window in current tab
---@return boolean
local function nvim_tabpage_has_only_win()
	return #vim.tbl_filter(function(win)
		return vim.fn.win_gettype(win) ~= "popup"
	end, vim.api.nvim_tabpage_list_wins(0)) <= 1
end

---@param direction nvim_direction_t
---@param count integer? default to 1
---@return nil
local function nvim_navigate(direction, count)
	vim.cmd.wincmd({
		direction,
		count = count,
	})
end

---@param direction nvim_direction_t
---@param count integer? default to 1
---@return nil
local function navigate(direction, count)
	count = count or 1
	if (nvim_at_border(direction) or nvim_in_floating_win()) and tmux_should_move(direction) then
		tmux_navigate(direction, count)
	else
		nvim_navigate(direction, count)
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
	return not tmux_is_zoomed() and nvim_tabpage_has_only_win()
end

---@return boolean
function M.tmux_mapkey_close_win_condition()
	return not tmux_is_zoomed() and nvim_has_only_win()
end

---@return boolean
function M.tmux_mapkey_resize_pane_horiz_condition()
	return not tmux_is_zoomed() and (nvim_at_border("l") and (nvim_at_border("h") or not tmux_at_border("l")))
end

---@return boolean
function M.tmux_mapkey_resize_pane_vert_condition()
	return not tmux_is_zoomed() and (nvim_at_border("j") and (nvim_at_border("k") or not tmux_at_border("j")))
end

---@return fun(): boolean
function M.tmux_mapkey_navigate_condition(direction)
	return function()
		return (nvim_at_border(direction) or nvim_in_floating_win()) and tmux_should_move(direction)
	end
end

---Map a key in normal and visual mode to a tmux command with fallback
---@param key string
---@param action string|function
---@param condition? fun(): boolean
---@return nil
function M.tmux_mapkey_fallback(key, action, condition)
	condition = condition or tmux_mapkey_default_condition
	require("utils.keys").amend({ "n", "x", "t" }, key, function(fallback)
		if not condition() or vim.env.NVIM or vim.fn.mode():sub(1, 1) == "t" and require("utils").running_tui() then
			fallback()
			return
		end
		if type(action) == "string" then
			tmux_exec(action)
			return
		end
		action()
	end)
end

return M
