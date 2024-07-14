local M = {}

---Choose the closer destination between two destinations
---@param dest1 number[]?
---@param dest2 number[]?
---@return number[]|nil
function M.choose_closer(dest1, dest2)
	if not dest1 then
		return dest2
	end
	if not dest2 then
		return dest1
	end

	local current_pos = vim.api.nvim_win_get_cursor(0)
	local line_width = vim.api.nvim_win_get_width(0)
	local dist1 = math.abs(dest1[2] - current_pos[2]) + math.abs(dest1[1] - current_pos[1]) * line_width
	local dist2 = math.abs(dest2[2] - current_pos[2]) + math.abs(dest2[1] - current_pos[1]) * line_width
	if dist1 <= dist2 then
		return dest1
	else
		return dest2
	end
end

---Check if a node has length larger than 0
---@param node table
---@return boolean
function M.node_has_length(node)
	local start_pos, end_pos = node:get_buf_position()
	return start_pos[1] ~= end_pos[1] or start_pos[2] ~= end_pos[2]
end

---Check if range1 contains range2
---If range1 == range2, return true
---@param range1 integer[][] 0-based range
---@param range2 integer[][] 0-based range
---@return boolean
function M.range_contains(range1, range2)
	return (range2[1][1] > range1[1][1] or (range2[1][1] == range1[1][1] and range2[1][2] >= range1[1][2]))
		and (range2[1][1] < range1[2][1] or (range2[1][1] == range1[2][1] and range2[1][2] <= range1[2][2]))
		and (range2[2][1] > range1[1][1] or (range2[2][1] == range1[1][1] and range2[2][2] >= range1[1][2]))
		and (range2[2][1] < range1[2][1] or (range2[2][1] == range1[2][1] and range2[2][2] <= range1[2][2]))
end

---Check if the cursor position is in the given range
---@param range integer[][] 0-based range
---@param cursor integer[] 1,0-based cursor position
---@return boolean
function M.in_range(range, cursor)
	local cursor0 = { cursor[1] - 1, cursor[2] }
	return (cursor0[1] > range[1][1] or (cursor0[1] == range[1][1] and cursor0[2] >= range[1][2]))
		and (cursor0[1] < range[2][1] or (cursor0[1] == range[2][1] and cursor0[2] <= range[2][2]))
end

---Find the parent (a previous node that contains the current node) of the node
---@param node table current node
---@return table|nil
function M.node_find_parent(node)
	local range_start, range_end = node:get_buf_position()
	local prev = node.parent.snippet and node.parent.snippet.prev.prev
	while prev do
		local range_start_prev, range_end_prev = prev:get_buf_position()
		if M.range_contains({ range_start_prev, range_end_prev }, { range_start, range_end }) then
			return prev
		end
		prev = prev.parent.snippet and prev.parent.snippet.prev.prev
	end
end

---Check if the cursor is at the end of a node
---@param range table 0-based range
---@param cursor number[] 1,0-based cursor position
---@return boolean
function M.cursor_at_end_of_range(range, cursor)
	return range[2][1] + 1 == cursor[1] and range[2][2] == cursor[2]
end

---Jump to the closer destination between a snippet and tabout
---@param snip_dest number[]
---@param tabout_dest number[]?
---@param direction number 1 or -1
---@return boolean true if a jump is performed
function M.jump_to_closer(snip_dest, tabout_dest, direction)
	direction = direction or 1
	local dest = M.choose_closer(snip_dest, tabout_dest)
	if not dest then
		return false
	end
	if vim.deep_equal(dest, tabout_dest) then
		require("utils").tabout.jump(direction)
	else
		require("luasnip").jump(direction)
	end
	return true
end

function M.clamp_format_items(field, min_width, max_width, items)
	if not items[field] or not type(items) == "string" then
		return
	end
	-- In case that min_width > max_width
	if min_width > max_width then
		min_width, max_width = max_width, min_width
	end
	local field_str = items[field]
	local field_width = vim.fn.strdisplaywidth(field_str)
	if field_width > max_width then
		local former_width = math.floor(max_width * 0.6)
		local latter_width = math.max(0, max_width - former_width - 1)
		items[field] = string.format("%s...%s", field_str:sub(1, former_width), field_str:sub(-latter_width))
	elseif field_width < min_width then
		items[field] = string.format("%-" .. min_width .. "s", field_str)
	end
end

function M.backspace_autoindent(fallback)
	local ts_indent = require("nvim-treesitter.indent")
	local cmp = require("cmp")
	local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
	if cursor_row == 1 and cursor_col == 0 then
		return
	end
	cmp.close()
	local current_line = vim.api.nvim_buf_get_lines(0, cursor_row - 1, cursor_row, true)[1]
	local ok, get_indent = pcall(ts_indent.get_indent, cursor_row)
	if not ok then
		get_indent = 0
	end
	if vim.fn.strcharpart(current_line, get_indent - 1, cursor_col - get_indent + 1):gsub("%s+", "") == "" then
		if get_indent > 0 and cursor_col > get_indent then
			local new_line = vim.fn.strcharpart(current_line, 0, get_indent)
				.. vim.fn.strcharpart(current_line, cursor_col)

			vim.api.nvim_buf_set_lines(0, cursor_row - 1, cursor_row, true, { new_line })
			vim.api.nvim_win_set_cursor(0, { cursor_row, math.min(get_indent or 0, vim.fn.strcharlen(new_line)) })
		elseif cursor_row > 1 and (get_indent > 0 and cursor_col + 1 > get_indent) then
			local prev_line = vim.api.nvim_buf_get_lines(0, cursor_row - 2, cursor_row - 1, true)[1]
			if vim.trim(prev_line) == "" then
				local prev_indent = ts_indent.get_indent(cursor_row - 1) or 0
				local new_line = vim.fn.strcharpart(current_line, 0, prev_indent)
					.. vim.fn.strcharpart(current_line, cursor_col)

				vim.api.nvim_buf_set_lines(0, cursor_row - 2, cursor_row, true, { new_line })
				vim.api.nvim_win_set_cursor(0, {
					cursor_row - 1,
					math.max(0, math.min(prev_indent, vim.fn.strcharlen(new_line))),
				})
			else
				local len = vim.fn.strcharlen(prev_line)
				local new_line = prev_line .. vim.fn.strcharpart(current_line, cursor_col)

				vim.api.nvim_buf_set_lines(0, cursor_row - 2, cursor_row, true, { new_line })
				vim.api.nvim_win_set_cursor(0, { cursor_row - 1, math.max(0, len) })
			end
		else
			fallback()
		end
	else
		fallback()
	end
end

return M
