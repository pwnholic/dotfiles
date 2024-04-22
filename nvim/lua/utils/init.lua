local M = {}

function M.buffer_matches(patterns, bufnr)
	bufnr = bufnr or 0

	local buf_matchers = {
		filetype = function()
			return vim.bo[bufnr].filetype
		end,
		buftype = function()
			return vim.bo[bufnr].buftype
		end,
		bufname = function()
			return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
		end,
	}

	for kind, pattern_list in pairs(patterns) do
		for _, pattern in ipairs(pattern_list) do
			if buf_matchers[kind](bufnr):find(pattern) then
				return true
			end
		end
	end

	return false
end

return M
