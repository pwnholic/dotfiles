local lazy_util = require("lazy.util")

local M = {}

---@alias Placeholder {n:number, text:string}

---@param snippet string
---@param fn fun(placeholder:Placeholder):string
---@return string
function M.snippet_replace(snippet, fn)
	return snippet:gsub("%$%b{}", function(m)
		local n, name = m:match("^%${(%d+):(.+)}$")
		return n and fn({ n = n, text = name }) or m
	end) or snippet
end

-- This function resolves nested placeholders in a snippet.
---@param snippet string
---@return string
function M.snippet_preview(snippet)
	local ok, parsed = pcall(function()
		return vim.lsp._snippet_grammar.parse(snippet)
	end)
	return ok and tostring(parsed)
		or M.snippet_replace(snippet, function(placeholder)
			return M.snippet_preview(placeholder.text)
		end):gsub("%$0", "")
end

-- This function replaces nested placeholders in a snippet with LSP placeholders.
function M.snippet_fix(snippet)
	local texts = {} ---@type table<number, string>
	return M.snippet_replace(snippet, function(placeholder)
		texts[placeholder.n] = texts[placeholder.n] or M.snippet_preview(placeholder.text)
		return "${" .. placeholder.n .. ":" .. texts[placeholder.n] .. "}"
	end)
end

---@param entry cmp.Entry
function M.auto_brackets(entry)
	local cmp = require("cmp")
	local Kind = cmp.lsp.CompletionItemKind
	local item = entry:get_completion_item()
	if vim.tbl_contains({ Kind.Function, Kind.Method }, item.kind) then
		local cursor = vim.api.nvim_win_get_cursor(0)
		local prev_char = vim.api.nvim_buf_get_text(0, cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2] + 1, {})[1]
		if prev_char ~= "(" and prev_char ~= ")" then
			local keys = vim.api.nvim_replace_termcodes("()<left>", false, false, true)
			vim.api.nvim_feedkeys(keys, "i", true)
		end
	end
end

-- This function adds missing documentation to snippets.
-- The documentation is a preview of the snippet.
---@param window cmp.CustomEntriesView|cmp.NativeEntriesView
function M.add_missing_snippet_docs(window)
	local cmp = require("cmp")
	local Kind = cmp.lsp.CompletionItemKind
	local entries = window:get_entries()
	for _, entry in ipairs(entries) do
		if entry:get_kind() == Kind.Snippet then
			local item = entry:get_completion_item()
			if not item.documentation and item.insertText then
				item.documentation = {
					kind = cmp.lsp.MarkupKind.Markdown,
					value = string.format("```%s\n%s\n```", vim.bo.filetype, M.snippet_preview(item.insertText)),
				}
			end
		end
	end
end

-- This is a better implementation of `cmp.confirm`:
--  * check if the completion menu is visible without waiting for running sources
--  * create an undo point before confirming
-- This function is both faster and more reliable.
---@param opts? {select: boolean, behavior: cmp.ConfirmBehavior}
function M.confirm(opts)
	local cmp = require("cmp")
	opts = vim.tbl_extend("force", {
		select = true,
		behavior = cmp.ConfirmBehavior.Insert,
	}, opts or {})
	return function(fallback)
		if cmp.core.view:visible() or vim.fn.pumvisible() == 1 then
			require("utils").create_undo()
			if cmp.confirm(opts) then
				return
			end
		end
		return fallback()
	end
end

function M.expand(snippet)
	-- Native sessions don't support nested snippet sessions.
	-- Always use the top-level session.
	-- Otherwise, when on the first placeholder and selecting a new completion,
	-- the nested session will be used instead of the top-level session.
	-- See: https://github.com/LazyVim/LazyVim/issues/3199
	local session = vim.snippet.active() and vim.snippet._session or nil

	local ok, err = pcall(vim.snippet.expand, snippet)
	if not ok then
		local fixed = M.snippet_fix(snippet)
		ok = pcall(vim.snippet.expand, fixed)

		local msg = ok and "Failed to parse snippet,\nbut was able to fix it automatically."
			or ("Failed to parse snippet.\n" .. err)

		lazy_util.warn(string.format("%s ```%s\n%s ```", msg, vim.bo.filetype, snippet), { title = "vim.snippet" })
	end

	-- Restore top-level session when needed
	if session then
		vim.snippet._session = session
	end
end

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

return M
