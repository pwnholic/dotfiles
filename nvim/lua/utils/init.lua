local M = {}

---Convert a snake_case string to camelCase
---@param str string?
---@return string?
function M.snake_to_camel(str)
	if not str then
		return nil
	end
	return (str:gsub("^%l", string.upper):gsub("_%l", string.upper):gsub("_", ""))
end

---Convert a camelCase string to snake_case
---@param str string
---@return string|nil
function M.camel_to_snake(str)
	if not str then
		return nil
	end
	return (str:gsub("%u", "_%1"):gsub("^_", ""):lower())
end

M.CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
function M.create_undo()
	if vim.api.nvim_get_mode().mode == "i" then
		vim.api.nvim_feedkeys(M.CREATE_UNDO, "n", false)
	end
end

---@type fun(name: string): table
function M.get_highlight(name)
	return vim.api.nvim_get_hl(0, { name = name, link = false })
end

function M.bufremove(buf)
	buf = buf or 0
	buf = buf == 0 and vim.api.nvim_get_current_buf() or buf

	if vim.bo.modified then
		local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
		if choice == 0 or choice == 3 then -- 0 for <Esc>/<C-c> and 3 for Cancel
			return
		end
		if choice == 1 then -- Yes
			vim.cmd.write()
		end
	end

	for _, win in ipairs(vim.fn.win_findbuf(buf)) do
		vim.api.nvim_win_call(win, function()
			if not vim.api.nvim_win_is_valid(win) or vim.api.nvim_win_get_buf(win) ~= buf then
				return
			end
			-- Try using alternate buffer
			local alt = vim.fn.bufnr("#")
			if alt ~= buf and vim.fn.buflisted(alt) == 1 then
				vim.api.nvim_win_set_buf(win, alt)
				return
			end

			-- Try using previous buffer
			local has_previous = pcall(vim.cmd, "bprevious")
			if has_previous and buf ~= vim.api.nvim_win_get_buf(win) then
				return
			end

			-- Create new listed buffer
			local new_buf = vim.api.nvim_create_buf(true, false)
			vim.api.nvim_win_set_buf(win, new_buf)
		end)
	end
	if vim.api.nvim_buf_is_valid(buf) then
		pcall(vim.cmd, "bdelete! " .. buf)
	end
end

local terminals = {}
function M.terminal(cmd, opts)
	opts = vim.tbl_deep_extend("force", {
		ft = "lazyterm",
		size = { width = 1, height = 1 },
		backdrop = nil,
	}, opts or {}, { persistent = true })

	local termkey = vim.inspect({ cmd = cmd or "shell", cwd = opts.cwd, env = opts.env, count = vim.v.count1 })

	if terminals[termkey] and terminals[termkey]:buf_valid() then
		terminals[termkey]:toggle()
	else
		terminals[termkey] = require("lazy.util").float_term(cmd, opts)
		local buf = terminals[termkey].buf
		vim.b[buf].lazyterm_cmd = cmd
		if opts.esc_esc == false then
			vim.keymap.set("t", "<esc>", "<esc>", { buffer = buf, nowait = true })
		end
		if opts.ctrl_hjkl == false then
			vim.keymap.set("t", "<c-h>", "<c-h>", { buffer = buf, nowait = true })
			vim.keymap.set("t", "<c-j>", "<c-j>", { buffer = buf, nowait = true })
			vim.keymap.set("t", "<c-k>", "<c-k>", { buffer = buf, nowait = true })
			vim.keymap.set("t", "<c-l>", "<c-l>", { buffer = buf, nowait = true })
		end

		vim.keymap.set("n", "gf", function()
			local f = vim.fn.findfile(vim.fn.expand("<cfile>"))
			if f ~= "" then
				vim.cmd("close")
				vim.cmd("e " .. f)
			end
		end, { buffer = buf })

		vim.api.nvim_create_autocmd("BufEnter", {
			buffer = buf,
			callback = function()
				vim.cmd.startinsert()
			end,
		})

		vim.cmd("noh")
	end

	return terminals[termkey]
end

function M.foldtext()
	local ok = pcall(vim.treesitter.get_parser, vim.api.nvim_get_current_buf())
	local ret = ok and vim.treesitter.foldtext and vim.treesitter.foldtext()
	if not ret or type(ret) == "string" then
		ret = { { vim.api.nvim_buf_get_lines(0, vim.v.lnum - 1, vim.v.lnum, false)[1], {} } }
	end
	table.insert(ret, { " " .. "..." })

	if not vim.treesitter.foldtext then
		return table.concat(
			vim.tbl_map(function(line)
				return line[1]
			end, ret),
			" "
		)
	end
	return ret
end

M.skip_foldexpr = {} ---@type table<number,boolean>
local skip_check = assert(vim.uv.new_check())

function M.foldexpr()
	local buf = vim.api.nvim_get_current_buf()

	-- still in the same tick and no parser
	if M.skip_foldexpr[buf] then
		return "0"
	end

	-- don't use treesitter folds for non-file buffers
	if vim.bo[buf].buftype ~= "" then
		return "0"
	end

	-- as long as we don't have a filetype, don't bother
	-- checking if treesitter is available (it won't)
	if vim.bo[buf].filetype == "" then
		return "0"
	end

	local ok = pcall(vim.treesitter.get_parser, buf)

	if ok then
		return vim.treesitter.foldexpr()
	end

	-- no parser available, so mark it as skip
	-- in the next tick, all skip marks will be reset
	M.skip_foldexpr[buf] = true
	skip_check:start(function()
		M.skip_foldexpr = {}
		skip_check:stop()
	end)
	return "0"
end

---Compiled vim regex that decides if a command is a TUI app
M.TUI_REGEX = vim.regex(
	[[\v^(sudo(\s+--?(\w|-)+((\s+|\=)\S+)?)*\s+)?]]
		.. [[(/usr/bin/)?]]
		.. [[(n?vim?|vimdiff|emacs(client)?|lem|nano]]
		.. [[|helix|kak|tmux|lazygit|h?top|gdb|fzf|nmtui|sudoedit|ssh)]]
)

---Check if any of the processes in terminal buffer `buf` is a TUI app
---@param buf integer? buffer handler
---@return boolean?
function M.running_tui(buf)
	local cmds = M.fg_cmds(buf)
	for _, cmd in ipairs(cmds) do
		if M.TUI_REGEX:match_str(cmd) then
			return true
		end
	end
	return false
end

---Get the command running in the foreground in the terminal buffer 'buf'
---@param buf integer? terminal buffer handler, default to 0 (current)
---@return string[]: command running in the foreground
function M.fg_cmds(buf)
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

function M.has_plugin(plugin)
	return require("lazy.core.config").spec.plugins[plugin]
end

return setmetatable(M, {
	__index = function(self, key)
		self[key] = require("utils." .. key)
		return self[key]
	end,
})
