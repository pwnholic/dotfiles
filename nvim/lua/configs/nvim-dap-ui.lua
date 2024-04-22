local M = {}

M.opts_cfg = {
	floating = { border = "solid" },
	layouts = {
		{
			elements = {
				{ id = "scopes", size = 0.2 },
				{ id = "breakpoints", size = 0.2 },
				{ id = "stacks", size = 0.2 },
				{ id = "watches", size = 0.2 },
				{ id = "console", size = 0.2 },
			},
			position = "right",
			size = 55,
		},
		{ elements = { { id = "repl", size = 1 } }, position = "bottom", size = 8 },
	},
}

function M.setup()
	require("dapui").setup(M.opts_cfg)
end

function M.keys()
	local function dapui(name)
		return function()
			require("dapui").float_element(
				name,
				{ width = vim.o.columns, height = vim.o.lines, enter = true, position = "center" }
			)
		end
	end
	return {
		{ "<leader>dfs", dapui("scopes"), desc = "Scope Float" },
		{ "<leader>dfr", dapui("repl"), desc = "Repl Float" },
		{ "<leader>dfc", dapui("console"), desc = "Console Float" },
		{ "<leader>dfb", dapui("breakpoints"), desc = "Breakpoint Float" },
		{ "<leader>dfS", dapui("stacks"), desc = "Stacks Float" },
		{ "<leader>dfw", dapui("watches"), desc = "Watches Float" },
	}
end

return M
