local M = {}
local utils_ts = require("utils.ts")

---Check if the current line is a markdown code block, using regex
---to check each line
---@param lnum integer? default to current line number
function M.in_codeblock_regex(lnum, buf)
	buf = buf or 0
	lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(buf, 0, lnum - 1, false)
	local result = false
	for _, line in ipairs(lines) do
		if line:match("^```") then
			result = not result
		end
	end
	return result
end

---Check if the current line is a markdown code block
---@param lnum integer? default to current line number
---@param buf integer? default to current buffer
---@return boolean
function M.in_codeblock(lnum, buf)
	buf = buf or 0
	lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]
	if utils_ts.is_active(buf) then
		return utils_ts.in_tsnode(function(ntype)
			return ntype:match("fence") and ntype:match("code") and true or false
		end, { lnum, 0 }, buf)
	end
	return M.in_codeblock_regex(lnum, buf)
end

return M
