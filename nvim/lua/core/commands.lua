local user_commmand = vim.api.nvim_create_user_command
local fzf_lua = require("fzf-lua")

---Generate a completion function for user command that wraps a builtin command
---@param user_cmd string user command pattern
---@param builtin_cmd string builtin command
---@return fun(_, cmdline: string, cursorpos: integer): string[]
local function complfn(user_cmd, builtin_cmd)
	return function(_, cmdline, cursorpos)
		local cmdline_before = cmdline:sub(1, cursorpos):gsub(user_cmd, builtin_cmd, 1)
		return vim.fn.getcompletion(cmdline_before, "cmdline")
	end
end

user_commmand("Ls", function(info)
	local suffix = string.format("%s %s", info.bang and "!" or "", info.args)
	return fzf_lua.buffers({ prompt = vim.trim(info.name .. suffix) .. "> ", ls_cmd = "ls" .. suffix })
end, {
	bang = true,
	nargs = "?",
	complete = function()
		return { "+", "-", "=", "a", "u", "h", "x", "%", "#", "R", "F", "t" }
	end,
})

user_commmand("Args", function(info)
	if not info.bang and vim.tbl_isempty(info.fargs) then
		fzf_lua.args()
		return
	end
	vim.cmd.args({ args = info.fargs, bang = info.bang })
end, { bang = true, nargs = "*", complete = complfn("Args", "args") })

user_commmand("Autocmd", function(info)
	if #info.fargs <= 1 and not info.bang then
		fzf_lua.autocmds({ fzf_opts = { ["--query"] = vim.fn.shellescape(info.fargs[1] or "") } })
		return
	end
	vim.cmd.autocmd({ args = info.fargs, bang = info.bang })
end, { bang = true, nargs = "*", complete = complfn("Autocmd", "autocmd") })

user_commmand("Marks", function(info)
	fzf_lua.marks({
		fzf_opts = {
			["--query"] = vim.fn.shellescape(table.concat(
				vim.tbl_map(function(mark)
					return "^" .. mark
				end, vim.split(info.args, "", { trimempty = true })),
				" | "
			)),
		},
	})
end, { nargs = "*", complete = complfn("Marks", "marks") })

user_commmand("Highlight", function(info)
	if vim.tbl_isempty(info.fargs) then
		fzf_lua.highlights()
		return
	end
	if #info.fargs == 1 and info.fargs[1] ~= "clear" then
		local hlgroup = info.fargs[1]
		if vim.fn.hlexists(hlgroup) == 1 then
			vim.cmd.hi({ args = { hlgroup }, bang = info.bang })
		else
			fzf_lua.highlights({ fzf_opts = { ["--query"] = vim.fn.shellescape(hlgroup) } })
		end
		return
	end
	vim.cmd.hi({ args = info.fargs, bang = info.bang })
end, { bang = true, nargs = "*", complete = complfn("Highlight", "hi") })

user_commmand("Registers", function(info)
	fzf_lua.registers({
		fzf_opts = {
			["--query"] = vim.fn.shellescape(table.concat(
				vim.tbl_map(function(reg)
					return string.format("^[%s]", reg:upper())
				end, vim.split(info.args, "", { trimempty = true })),
				" | "
			)),
		},
	})
end, { nargs = "*", complete = complfn("Registers", "registers") })

user_commmand("Oldfiles", fzf_lua.oldfiles, {})

user_commmand("Changes", fzf_lua.changes, {})

user_commmand("Tags", fzf_lua.tagstack, {})

user_commmand("Jumps", fzf_lua.jumps, {})

user_commmand("Tabs", fzf_lua.tabs, {})

user_commmand("F", function(info)
	fzf_lua.files({ cwd = info.fargs[1] })
end, { nargs = "?", complete = "dir", desc = "Fuzzy find files." })
