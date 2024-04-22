local M = {}

M.keys = {
	{
		"<leader>ut",
		function()
			local tsc = require("treesitter-context")
			tsc.toggle()
			local function ts_get_upvalue_ctx(func, name)
				local i = 1
				while true do
					local n, v = debug.getupvalue(func, i)
					if not n then
						break
					end
					if n == name then
						return v
					end
					i = i + 1
				end
			end
			if ts_get_upvalue_ctx(tsc.toggle, "enabled") then
				vim.notify("Enabled Treesitter Context", vim.diagnostic.severity.INFO, { title = "Option" })
			else
				vim.notify("Disabled Treesitter Context", vim.diagnostic.severity.INFO, { title = "Option" })
			end
		end,
		desc = "Toggle Treesitter Context",
	},
}

function M.setup()
	require("treesitter-context").setup({
		enable = true,
		max_lines = 3,
		line_numbers = false,
		multiline_threshold = 20, -- Maximum number of lines to show for a single context
		trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
	})
end

return M
