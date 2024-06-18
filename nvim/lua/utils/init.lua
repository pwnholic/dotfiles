local M = {}

function M.get_path_separator()
	if M.is_win() then
		return "\\"
	end
	return "/"
end

function M.combine_paths(...)
	return table.concat({ ... }, M.get_path_separator())
end

function M.dedup(list)
	local ret = {}
	local seen = {}
	for _, v in ipairs(list) do
		if not seen[v] then
			table.insert(ret, v)
			seen[v] = true
		end
	end
	return ret
end

M.CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
function M.create_undo()
	if vim.api.nvim_get_mode().mode == "i" then
		vim.api.nvim_feedkeys(M.CREATE_UNDO, "n", false)
	end
end

function M.is_loaded(name)
	local Config = require("lazy.core.config")
	return Config.plugins[name] and Config.plugins[name]._.loaded
end

---Recursively build a nested table from a list of keys and a value
---@param key_parts string[] list of keys
---@param val any
---@return table
function M.build_nested(key_parts, val)
	return key_parts[1] and { [key_parts[1]] = M.build_nested({ unpack(key_parts, 2) }, val) } or val
end

---@class parsed_arg_t table

---Parse arguments from the command line into a table
---@param fargs string[] list of arguments
---@return table
function M.parse_cmdline_args(fargs)
	local parsed = {}
	-- First pass: parse arguments into a plain table
	for _, arg in ipairs(fargs) do
		local key, val = arg:match("^%-%-(%S+)=(.*)$")
		if not key then
			key = arg:match("^%-%-(%S+)$")
		end
		local val_expanded = vim.fn.expand(val)
		if type(val) == "string" and vim.uv.fs_stat(val_expanded) then
			val = val_expanded
		end
		if key and val then -- '--key=value'
			local eval_valid, eval_result = pcall(vim.fn.eval, val)
			parsed[key] = not eval_valid and val or eval_result
		elseif key and not val then -- '--key'
			parsed[key] = true
		else -- 'value'
			table.insert(parsed, arg)
		end
	end
	-- Second pass: build nested tables from dot-separated keys
	for key, val in pairs(parsed) do
		if type(key) == "string" then
			local key_parts = vim.split(key, "%.")
			parsed = vim.tbl_deep_extend("force", parsed, M.build_nested(key_parts, val))
			if #key_parts > 1 then
				parsed[key] = nil -- Remove the original dot-separated key
			end
		end
	end
	return parsed
end

---options command accepts, in the format of <optkey>=<candicate_optvals>
---or <optkey>
---@alias opts_t table
---@alias params_t string[]

---Get option keys / option names from opts table
---@param opts opts_t
---@return string[]
function M.optkeys(opts)
	local optkeys = {}
	for key, val in pairs(opts) do
		if type(key) == "number" then
			table.insert(optkeys, val)
		elseif type(key) == "string" then
			table.insert(optkeys, key)
		end
	end
	return optkeys
end

---Returns a function that can be used to complete the options of a command
---An option must be in the format of --<opt> or --<opt>=<val>
---@param opts opts_t?
---@return fun(arglead: string, cmdline: string, cursorpos: integer): string[]
function M.complete_opts(opts)
	---@param arglead string leading portion of the argument being completed
	---@param cmdline string the entire command line
	---@param cursorpos integer cursor position in the command line
	---@return string[] completion completion results
	return function(arglead, cmdline, cursorpos)
		if not opts or vim.tbl_isempty(opts) then
			return {}
		end
		local optkey, eq, optval = arglead:match("^%-%-([^%s=]+)(=?)([^%s=]*)$")
		-- Complete option values
		if optkey and eq == "=" then
			local candidate_vals = vim.tbl_map(
				tostring,
				type(opts[optkey]) == "function" and opts[optkey](arglead, cmdline, cursorpos) or opts[optkey]
			)
			return candidate_vals
					and vim.tbl_map(
						function(val)
							return "--" .. optkey .. "=" .. val
						end,
						vim.tbl_filter(function(val)
							return val:find(optval, 1, true) == 1
						end, candidate_vals)
					)
				or {}
		end
		-- Complete option keys
		return vim.tbl_filter(
			function(compl)
				return compl:find(arglead, 1, true) == 1
			end,
			vim.tbl_map(function(k)
				return "--" .. k
			end, M.optkeys(opts))
		)
	end
end

---Returns a function that can be used to complete the arguments of a command
---@param params params_t?
---@return fun(arglead: string, cmdline: string, cursorpos: integer): string[]
function M.complete_params(params)
	return function(arglead, _, _)
		return vim.tbl_filter(function(arg)
			return arg:find(arglead, 1, true) == 1
		end, params or {})
	end
end

---Returns a function that can be used to complete the arguments and options
---of a command
---@param params params_t?
---@param opts opts_t?
---@return fun(arglead: string, cmdline: string, cursorpos: integer): string[]
function M.complete(params, opts)
	local fn_compl_params = M.complete_params(params)
	local fn_compl_opts = M.complete_opts(opts)
	return function(arglead, cmdline, cursorpos)
		local param_completions = fn_compl_params(arglead, cmdline, cursorpos)
		local opt_completions = fn_compl_opts(arglead, cmdline, cursorpos)
		return vim.list_extend(param_completions, opt_completions)
	end
end

---Set abbreviation that only expand when the trigger is at the position of
---a command
---@param trig string|{ [1]: string, [2]: string }
---@param command string
---@param opts table?
function M.command_abbrev(trig, command, opts)
	-- Map a range, first one if command short name,
	-- second one if command full name
	if type(trig) == "table" then
		local trig_short = trig[1]
		local trig_full = trig[2]
		for i = #trig_short, #trig_full do
			local cmd_part = trig_full:sub(1, i)
			M.command_abbrev(cmd_part, command)
		end
		return
	end
	vim.keymap.set("ca", trig, function()
		return vim.fn.getcmdcompltype() == "command" and command or trig
	end, vim.tbl_deep_extend("keep", { expr = true }, opts or {}))
end

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

---@param name string
function M.get_plugin(name)
	return require("lazy.core.config").spec.plugins[name]
end

function M.has(plugin)
	return M.get_plugin(plugin) ~= nil
end

---@param fn fun()
function M.on_very_lazy(fn)
	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		callback = function()
			fn()
		end,
	})
end

--- This extends a deeply nested list with a key in a table
--- that is a dot-separated string.
--- The nested list will be created if it does not exist.
---@generic T
---@param t T[]
---@param key string
---@param values T[]
---@return T[]?
function M.extend(t, key, values)
	local keys = vim.split(key, ".", { plain = true })
	for i = 1, #keys do
		local k = keys[i]
		t[k] = t[k] or {}
		if type(t) ~= "table" then
			return
		end
		t = t[k]
	end
	return vim.list_extend(t, values)
end

---@param name string
function M.opts(name)
	local plugin = require("lazy.core.config").spec.plugins[name]
	if not plugin then
		return {}
	end
	local Plugin = require("lazy.core.plugin")
	return Plugin.values(plugin, "opts", false)
end

---@param name string
---@param bg? boolean
---@return string?
function M.get_hexcolor(name, bg)
	---@type {foreground?:number}?
	---@diagnostic disable-next-line: deprecated
	local hl = vim.api.nvim_get_hl and vim.api.nvim_get_hl(0, { name = name, link = false })
		or vim.api.nvim_get_hl_by_name(name, true)
	---@diagnostic disable-next-line: undefined-field
	---@type string?
	local color = nil
	if hl then
		if bg then
			color = hl.bg or hl.background
		else
			color = hl.fg or hl.foreground
		end
	end
	return color and string.format("#%06x", color) or nil
end

function M.is_win()
	return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

---Check if any of the processes in terminal buffer `buf` is a TUI app
---@param buf integer? buffer handler
---@return boolean?
function M.running_tui(buf)
	local proc_cmds = M.proc_cmds(buf)
	for _, cmd in ipairs(proc_cmds) do
		if
			vim.fn.match(
				cmd,
				"\\v^(sudo(\\s+--?(\\w|-)+((\\s+|\\=)\\S+)?)*\\s+)?(/usr/bin/)?(n?vim?|vimdiff|emacs(client)?|lem|nano|helix|kak|lazygit|fzf|nmtui|sudoedit|ssh)"
			) >= 0
		then
			return true
		end
	end
end

---Get list of commands of the processes running in the terminal
---@param buf integer? terminal buffer handler, default to 0 (current)
---@return string[]: process names
function M.proc_cmds(buf)
	buf = buf or 0
	if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].bt ~= "terminal" then
		return {}
	end
	local channel = vim.bo[buf].channel
	local chan_valid, pid = pcall(vim.fn.jobpid, channel)
	if not chan_valid then
		return {}
	end
	return vim.split(vim.fn.system("ps h -o args -g " .. pid), "\n", {
		trimempty = true,
	})
end

---@class keymap_def_t
---@field lhs string
---@field lhsraw string
---@field rhs string?
---@field callback function?
---@field expr boolean?
---@field desc string?
---@field noremap boolean?
---@field script boolean?
---@field silent boolean?
---@field nowait boolean?
---@field buffer boolean?
---@field replace_keycodes boolean?

---Get keymap definition
---@param mode string
---@param lhs string
---@return keymap_def_t
function M.get_keys(mode, lhs)
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

---@param def keymap_def_t
---@return function
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

---Amend keymap
---Caveat: currently cannot amend keymap with <Cmd>...<CR> rhs
---@param modes string[]|string
---@param lhs string
---@param rhs function(fallback: function)
---@param opts table?
---@return nil
function M.amend_keys(modes, lhs, rhs, opts)
	modes = type(modes) ~= "table" and { modes } or modes --[=[@as string[]]=]
	for _, mode in ipairs(modes) do
		local fallback = M.keys_fallback_fn(M.get_keys(mode, lhs))
		vim.keymap.set(mode, lhs, function()
			rhs(fallback)
		end, opts)
	end
end

return setmetatable(M, {
	__index = function(self, key)
		self[key] = require("utils." .. key)
		return self[key]
	end,
})
