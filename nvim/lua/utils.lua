local M = {}

M.skip_foldexpr = {} ---@type table<number,boolean>
function M.fold_expr()
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

function M.fold_text()
	local ok = pcall(vim.treesitter.get_parser, vim.api.nvim_get_current_buf())
	local ret = ok and vim.treesitter.foldtext and vim.treesitter.foldtext()
	if not ret or type(ret) == "string" then
		ret = { { vim.api.nvim_buf_get_lines(0, vim.v.lnum - 1, vim.v.lnum, false)[1], {} } }
	end
	local line_count = vim.v.foldend - vim.v.foldstart + 1
	table.insert(ret, { string.rep(" ", 4) .. tostring(line_count) .. " lines folded" })

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

local diagIcons = require("icons").diagnostics
M.diagnostic_conf = {
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = diagIcons.Error,
			[vim.diagnostic.severity.WARN] = diagIcons.Warn,
			[vim.diagnostic.severity.INFO] = diagIcons.Hint,
			[vim.diagnostic.severity.HINT] = diagIcons.Info,
		},
		numhl = {
			[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
			[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
			[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
			[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
		},
	},
	virtual_text = {
		spacing = 4,
		source = "if_many",
		prefix = "",
		format = function(d)
			local icons = {}
			for key, value in pairs(diagIcons) do
				icons[key:upper()] = value
			end
			return string.format(" %s : %s ", icons[vim.diagnostic.severity[d.severity]], d.message)
		end,
	},
	float = {
		header = setmetatable({}, {
			__index = function(_, k)
				local icon, hl = require("nvim-web-devicons").get_icon_by_filetype(vim.bo.filetype)
				local arr = {
					function()
						return string.format("Diagnostics: %s  %s", icon, vim.bo.filetype)
					end,
					function()
						return hl
					end,
				}
				return arr[k]()
			end,
		}),
		format = function(d)
			return string.format("[%s] : %s", d.source, d.message)
		end,
		source = "if_many",
		severity_sort = true,
		wrap = true,
		border = "single",
		max_width = math.floor(vim.o.columns / 2),
		max_height = math.floor(vim.o.lines / 3),
	},
}

-- TOGGLE STUFF START --
function M.toggle_option(option, silent, values)
	if values then
		if vim.opt_local[option]:get() == values[1] then
			vim.opt_local[option] = values[2]
		else
			vim.opt_local[option] = values[1]
		end
		return vim.notify("Set " .. option .. " to " .. vim.opt_local[option]:get(), 2, { title = "Option" })
	end
	vim.opt_local[option] = not vim.opt_local[option]:get()
	if not silent then
		if vim.opt_local[option]:get() then
			vim.notify("Enabled " .. option, 2, { title = "Option" })
		else
			vim.notify("Disabled " .. option, 2, { title = "Option" })
		end
	end
end

local nu = { number = true, relativenumber = true }

function M.toggle_number()
	if vim.opt_local.number:get() or vim.opt_local.relativenumber:get() then
		nu = { number = vim.opt_local.number:get(), relativenumber = vim.opt_local.relativenumber:get() }
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.notify("Disabled line numbers", 2, { title = "Option" })
	else
		vim.opt_local.number = nu.number
		vim.opt_local.relativenumber = nu.relativenumber
		vim.notify("Enabled line numbers", 2, { title = "Option" })
	end
end

local enabled = true
function M.toggle_diagnostics()
	enabled = not enabled
	if enabled then
		vim.notify("Enabled diagnostic", 2, { title = "Diagnostics" })
		vim.diagnostic.enable()
	else
		vim.notify("Disabled diagnostic", 2, { title = "Diagnostics" })
		vim.diagnostic.disable()
	end
end

function M.close_float_window()
	local count = 0
	local current_win = vim.api.nvim_get_current_win()
	-- Close current win only if it's a floating window
	if vim.api.nvim_win_get_config(current_win).relative ~= "" then
		vim.api.nvim_win_close(current_win, true)
		return
	end
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		if vim.api.nvim_win_is_valid(win) then
			local config = vim.api.nvim_win_get_config(win)
			-- Close floating windows that can be focused
			if config.relative ~= "" and config.focusable then
				vim.api.nvim_win_close(win, false) -- do not force
				count = count + 1
			end
		end
	end
	if count == 0 then -- Fallback
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("q", true, true, true), "n", false)
	end
end

---Get keymap definition
function M.get_keys_def(mode, lhs)
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

function M.keys_fallback_fn(def)
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

function M.amend_keys(modes, lhs, rhs, opts)
	modes = type(modes) ~= "table" and { modes } or modes --[=[@as string[]]=]
	for _, mode in ipairs(modes) do
		local fallback = M.keys_fallback_fn(M.get_keys_def(mode, lhs))
		vim.keymap.set(mode, lhs, function()
			rhs(fallback)
		end, opts)
	end
end

---List of programs considered as TUI apps
M.tui = {
	fzf = true,
	nvi = true,
	vim = true,
	nvim = true,
	sudo = true,
	nano = true,
	helix = true,
	emacs = true,
	vimdiff = true,
	lazygit = true,
}

---Check if any of the processes in terminal buffer `buf` is a TUI app
function M.running_tui(buf)
	local proc_names = M.proc_names(buf)
	for _, proc_name in ipairs(proc_names) do
		if M.tui[proc_name] then
			return true
		end
	end
end

---Get list of names of the processes running in the terminal
function M.proc_names(buf)
	buf = buf or 0
	if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].bt ~= "terminal" then
		return {}
	end
	local channel = vim.bo[buf].channel
	local chan_valid, pid = pcall(vim.fn.jobpid, channel)
	if not chan_valid then
		return {}
	end
	return vim.split(vim.fn.system("ps h -o comm -g " .. pid), "\n", { trimempty = true })
end

return M
