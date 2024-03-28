---@alias nvim_direction_t 'h'|'j'|'k'|'l'
---@alias tmux_direction_t 'L'|'D'|'U'|'R'
---@alias tmux_borderpane_direction_t 'left'|'bottom'|'top'|'right'
---@return string tmux socket path
local function tmux_get_socket()
	return vim.split(vim.env.TMUX, ",")[1]
end

---@return string tmux command output
local function tmux_exec(command, global)
	command = global and string.format("tmux %s", command) or string.format("tmux -S %s %s", tmux_get_socket(), command)
	local handle = assert(io.popen(command), string.format("[tmux-nav]: unable to execute: [%s]", command))
	local result = handle:read("*a")
	handle:close()
	return result
end

---Get tmux option value in current pane
---@return string tmux pane option value
local function tmux_get_pane_opt(opt)
	return (
		tmux_exec(string.format("display-message -pt %s '#{%s}'", vim.env.TMUX_PANE, vim.fn.escape(opt, "'\\"))):gsub(
			"\n.*",
			""
		)
	)
end

---Set tmux option value in current pane
---@return nil
local function tmux_set_pane_opt(opt, val)
	tmux_exec(string.format("set -pt %s %s '%s'", vim.env.TMUX_PANE, opt, vim.fn.escape(val, "'\\")))
end

---Unset a tmux pane option
---@return nil
local function tmux_unset_pane_opt(opt)
	tmux_exec(string.format("set -put %s '%s'", vim.env.TMUX_PANE, vim.fn.escape(opt, "'\\")))
end

---@return boolean
local function tmux_is_zoomed()
	return tmux_get_pane_opt("window_zoomed_flag") == "1"
end

---@type table<nvim_direction_t, tmux_borderpane_direction_t>
local tmux_pane_position_map = { h = "left", j = "bottom", k = "top", l = "right" }

---@param direction nvim_direction_t
---@return boolean
local function tmux_at_border(direction)
	return tmux_get_pane_opt("pane_at_" .. tmux_pane_position_map[direction]) == "1"
end

---@return boolean
local function tmux_should_move(direction)
	return not tmux_is_zoomed() and not tmux_at_border(direction)
end

---@type table<nvim_direction_t, tmux_direction_t>
local tmux_direction_map = { h = "L", j = "D", k = "U", l = "R" }

---@return nil
local function tmux_navigate(direction, count)
	count = count or 1
	for _ = 1, count do
		tmux_exec(string.format("select-pane -t '%s' -%s", vim.env.TMUX_PANE, tmux_direction_map[direction]))
	end
end

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

---@return nil
local function nvim_navigate(direction, count)
	vim.cmd.wincmd({ direction, count = count })
end

---@return nil
local function navigate(direction, count)
	count = count or 1
	if (nvim_at_border(direction) or nvim_in_floating_win()) and tmux_should_move(direction) then
		tmux_navigate(direction, count)
	else
		nvim_navigate(direction, count)
	end
end

---@return function: rhs of a window navigation keymap
local function navigate_wrap(direction)
	return function()
		navigate(direction, vim.v.count1)
	end
end

---@return boolean
local function tmux_mapkey_default_condition()
	return not tmux_is_zoomed() and nvim_tabpage_has_only_win()
end

---@return boolean
local function tmux_keys_close_win_cond()
	return not tmux_is_zoomed() and nvim_has_only_win()
end

---@return boolean
local function tmux_keys_resize_pane_horiz_cond()
	return not tmux_is_zoomed() and (nvim_at_border("l") and (nvim_at_border("h") or not tmux_at_border("l")))
end

---@return boolean
local function tmux_keys_resize_pane_vert_cond()
	return not tmux_is_zoomed() and (nvim_at_border("j") and (nvim_at_border("k") or not tmux_at_border("j")))
end

---@return fun(): boolean
local function tmux_navigate_cond(direction)
	return function()
		return (nvim_at_border(direction) or nvim_in_floating_win()) and tmux_should_move(direction)
	end
end

---Map a key in normal and visual mode to a tmux command with fallback
---@return nil
local function tmux_key_fallback(key, action, condition, opts)
	condition = condition or tmux_mapkey_default_condition
	require("utils").amend_keys({ "n", "x", "t" }, key, function(fallback)
		if not condition() or vim.env.NVIM or vim.fn.mode():sub(1, 1) == "t" and require("utils").running_tui() then
			fallback()
			return
		end
		if type(action) == "string" then
			tmux_exec(action)
			return
		end
		action()
	end, opts)
end

---Setup keymaps and tmux variable `@is_vim`
local function setup()
	if vim.g.loaded_tmux or not vim.env.TMUX or not vim.g.has_ui then
		return
	end
	vim.g.loaded_tmux = true

    -- stylua: ignore start
	tmux_key_fallback("<M-h>", navigate_wrap("h"), tmux_navigate_cond("h"), { desc = "Move to Left Pane" })
	tmux_key_fallback("<M-j>", navigate_wrap("j"), tmux_navigate_cond("j"), { desc = "Move to Down Pane" })
	tmux_key_fallback("<M-k>", navigate_wrap("k"), tmux_navigate_cond("k"), { desc = "Move to Up Pane" })
	tmux_key_fallback("<M-l>", navigate_wrap("l"), tmux_navigate_cond("l"), { desc = "Move to Right Pane" })

	tmux_key_fallback("<M-c>", "new-window", _, { desc = "Tmux New Window" })
	tmux_key_fallback("<M-s>", [[command-prompt -p "New Session:" "new-session -A -s '%%'"]] , _, { desc = "New Session" })

	tmux_key_fallback("<M-r>", [[command-prompt -I "#W" { rename-window "%%" }]], _, { desc = "Rename Window" })
	tmux_key_fallback("<M-R>", [[command-prompt -I "#S" { rename-session "%%" }]], _, { desc = "Rename Session" })

	tmux_key_fallback("<M-o>", "confirm 'kill-pane -a'", _, { desc = "Kill Pane All" })
    tmux_key_fallback("<M-q>", "confirm kill-pane", tmux_keys_close_win_cond, { desc = "Kill Pane With Cond" })
	tmux_key_fallback("<M-Q>", "confirm 'kill-window'", _, { desc = "Kill Window" })
	tmux_key_fallback("<M-S>", "confirm 'kill-session'", _, { desc = "Kill Session" })

	tmux_key_fallback("<M-+>", "confirm 'select-layout tiled'", _, { desc = "Select Layout Tiled" })

	tmux_key_fallback("<M-E>", "swap-pane -U", _, { desc = "Swap Up Pane" })
	tmux_key_fallback("<M-e>", "swap-pane -D", _, { desc = "Swap Down Pane" })
	tmux_key_fallback("<M-w>", "choose-tree -ZN", _, { desc = "Tmux Choose Tree" })
	tmux_key_fallback("<M-z>", "resize-pane -Z", _, { desc = "Tmux Zoom Pane" })
	tmux_key_fallback("<M-,>", "resize-pane -L 4", tmux_keys_resize_pane_horiz_cond, { desc = "Horizontal Resize Left +4" })
	tmux_key_fallback("<M-.>", "resize-pane -R 4", tmux_keys_resize_pane_horiz_cond, { { desc = "Horizontal Resize Right +4" } })
	tmux_key_fallback("<M-->", [[run "tmux resize-pane -y $(($(tmux display -p '#{pane_height}') - 2))"]], tmux_keys_resize_pane_vert_cond, { desc = "Vertical Resize Down -2" })
	tmux_key_fallback("<M-=>", [[run "tmux resize-pane -y $(($(tmux display -p '#{pane_height}') + 2))"]], tmux_keys_resize_pane_vert_cond, { desc = "Vertical Resize Up +2" })
	-- stylua: ignore end

	-- Set @is_vim and register relevant autocmds callbacks if not already in a vim/nvim session
	if tmux_get_pane_opt("@is_vim") == "" then
		tmux_set_pane_opt("@is_vim", "yes")
		local groupid = vim.api.nvim_create_augroup("TmuxNavSetIsVim", {})
		vim.api.nvim_create_autocmd("VimResume", {
			desc = "Set @is_vim in tmux pane options after vim resumes.",
			group = groupid,
			callback = function()
				tmux_set_pane_opt("@is_vim", "yes")
			end,
		})
		vim.api.nvim_create_autocmd({ "VimSuspend", "VimLeave" }, {
			desc = "Unset @is_vim in tmux pane options on vim leaving or suspending.",
			group = groupid,
			callback = function()
				tmux_unset_pane_opt("@is_vim")
			end,
		})
	end
end

return { setup = setup }
