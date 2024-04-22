local M = {}

function M.setup()
	require("neotest").setup({
		adapters = {
			require("neotest-go")({
				experimental = { test_table = true },
				args = { "-count=1", "-timeout=60s" },
			}),
			default_strategy = "integrated",
			status = { enabled = true, signs = true, virtual_text = true },
			icons = {
				passed = " ",
				running = " ",
				failed = " ",
				unknown = " ",
				watching = "󰈈 ",
				running_animated = vim.tbl_map(function(s)
					return s .. " "
				end, { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }),
			},
			run = { enabled = true },
			running = { concurrent = true },
			state = { enabled = true },
			output = { open_on_run = true },
			output_panel = { enabled = true, open = "botright split | resize 15" },
			quickfix = {
				open = function()
					if require("lazy.core.config").spec.plugins["trouble.nvim"] ~= nil then
						require("trouble").toggle("quickfix")
					else
						vim.cmd.copen()
					end
				end,
			},
		},
	})
end

function M.keys()
	local test = require("neotest")
	return {
		{
			"<leader>tF",
			function()
				test.run.run({ vim.fn.expand("%"), strategy = "dap" })
			end,
			desc = "Test Debug File",
		},
		{
			"<leader>tL",
			function()
				test.run.run_last({ strategy = "dap" })
			end,
			desc = "Debug Last Test",
		},
		{
			"<leader>ta",
			function()
				test.run.attach()
			end,
			desc = "Test Attach",
		},
		{
			"<leader>tf",
			function()
				test.run.run(vim.fn.expand("%"))
			end,
			desc = "Test File",
		},
		{
			"<leader>tl",
			function()
				test.run.run_last()
			end,
			desc = "Run Last",
		},
		{
			"<leader>tn",
			function()
				test.run.run()
			end,
			desc = "Nearest Test",
		},
		{
			"<leader>tN",
			function()
				test.run.run({ strategy = "dap" })
			end,
			desc = "Debug Nearest",
		},
		{
			"<leader>to",
			function()
				test.output_panel.toggle()
			end,
			desc = "Output Panel",
		},
		{
			"<leader>tx",
			function()
				test.run.stop()
			end,
			desc = "Test Stop",
		},
		{
			"<leader>ts",
			function()
				test.summary.toggle()
			end,
			desc = "Test Summary",
		},
	}
end

return M
