--- GUA NYOLONG DARI : https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/ui.lua
local M = {}

---@alias Sign {name:string, text:string, texthl:string, priority:number}

-- Returns a list of regular and extmark signs sorted by priority (low to high)
---@return Sign[]
---@param buf number
---@param lnum number
function M.get_signs(buf, lnum)
	-- Get regular signs
	---@type Sign[]
	local signs = {}
	-- Get extmark signs
	local extmarks = vim.api.nvim_buf_get_extmarks(
		buf,
		-1,
		{ lnum - 1, 0 },
		{ lnum - 1, -1 },
		{ details = true, type = "sign" }
	)

	for _, extmark in pairs(extmarks) do
		signs[#signs + 1] = {
			name = extmark[4].sign_hl_group or extmark[4].sign_name or "",
			text = extmark[4].sign_text,
			texthl = extmark[4].sign_hl_group,
			priority = extmark[4].priority,
		}
	end
	-- Sort by priority
	table.sort(signs, function(a, b)
		return (a.priority or 0) < (b.priority or 0)
	end)

	return signs
end

---@return Sign?
---@param buf number
---@param lnum number
function M.get_mark(buf, lnum)
	local marks = vim.fn.getmarklist(buf)
	vim.list_extend(marks, vim.fn.getmarklist())
	for _, mark in ipairs(marks) do
		if mark.pos[1] == buf and mark.pos[2] == lnum and mark.mark:match("[a-zA-Z]") then
			return { text = mark.mark:sub(2), texthl = "MarkIcons" }
		end
	end
end

---@param sign? Sign
---@param len? number
function M.icon(sign, len)
	sign = sign or {}
	len = len or 2
	local text = vim.fn.strcharpart(sign.text or "", 0, len) ---@type string
	text = text .. string.rep(" ", len - vim.fn.strchars(text))
	return sign.texthl and ("%#" .. sign.texthl .. "#" .. text .. "%*") or text
end

function M.statuscolumn()
	local buf = vim.api.nvim_win_get_buf(0)
	local is_file = vim.bo[buf].buftype == ""
	local show_signs = vim.wo[0].signcolumn ~= "no"

	local components = { "", "", "" }

	local show_open_folds = true
	local use_githl = true

	if show_signs then
		local signs = M.get_signs(buf, vim.v.lnum)

		---@type Sign?,Sign?,Sign?
		local left, right, fold, githl
		for _, s in ipairs(signs) do
			if s.name and (s.name:find("GitSign") or s.name:find("MiniDiffSign")) then
				right = s
				if use_githl then
					githl = s["texthl"]
				end
			else
				left = s
			end
		end

		vim.api.nvim_win_call(0, function()
			if vim.fn.foldclosed(vim.v.lnum) >= 0 then
				fold = { text = "", texthl = githl or "Folded" }
			elseif
				show_open_folds
				and not M.skip_foldexpr[buf]
				and tostring(vim.treesitter.foldexpr(vim.v.lnum)):sub(1, 1) == ">"
			then
				fold = { text = "  ", texthl = githl }
			end
		end)
		components[1] = M.icon(M.get_mark(buf, vim.v.lnum) or left)
		components[3] = is_file and M.icon(fold or right, 3) or ""
	end

	-- Numbers in Neovim are weird
	-- They show when either number or relativenumber is true
	local is_num = vim.wo[0].number
	local is_relnum = vim.wo[0].relativenumber
	if (is_num or is_relnum) and vim.v.virtnum == 0 then
		if vim.fn.has("nvim-0.11") == 1 then
			components[2] = "%l" -- 0.11 handles both the current and other lines with %l
		else
			if vim.v.relnum == 0 then
				components[2] = is_num and "%l" or "%r" -- the current line
			else
				components[2] = is_relnum and "%r" or "%l" -- other lines
			end
		end
		components[2] = "%=" .. components[2] .. " " -- right align
	end

	if vim.v.virtnum ~= 0 then
		components[2] = "%= "
	end

	return table.concat(components, "")
end

M.skip_foldexpr = {} ---@type table<number,boolean>
local skip_check = assert(vim.uv.new_check())

function M.foldexpr()
	local buf = vim.api.nvim_get_current_buf()
	if M.skip_foldexpr[buf] then
		return "0"
	end
	if vim.bo[buf].buftype ~= "" then
		return "0"
	end
	if vim.bo[buf].filetype == "" then
		return "0"
	end
	local ok = pcall(vim.treesitter.get_parser, buf)
	if ok then
		return vim.treesitter.foldexpr()
	end
	M.skip_foldexpr[buf] = true
	skip_check:start(function()
		M.skip_foldexpr = {}
		skip_check:stop()
	end)
	return "0"
end

return M
