return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{
				"rcarriga/nvim-dap-ui",
				opts = {
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
				},
				keys = function()
					local function dapui(name)
						return function()
							require("dapui").float_element(name, { width = vim.o.columns, height = vim.o.lines, enter = true, position = "center" })
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
				end,
			},
			{ "theHamsta/nvim-dap-virtual-text", opts = { enabled_commands = true, all_frames = true } },
		},
		config = function()
			local dap, dapui, icons = require("dap"), require("dapui"), require("icons").dap
			vim.fn.sign_define("DapBreakpoint", { text = icons.Breakpoint, texthl = "DiagnosticSignHint" })
			vim.fn.sign_define("DapBreakpointCondition", { text = icons.BreakpointCondition, texthl = "DiagnosticSignInfo" })
			vim.fn.sign_define("DapBreakpointRejected", { text = icons.BreakpointRejected, texthl = "DiagnosticSignWarn" })
			vim.fn.sign_define("DapLogPoint", { text = icons.LogPoint, texthl = "DiagnosticSignOk" })
			vim.fn.sign_define("DapStopped", { text = icons.Stopped, texthl = "DiagnosticSignError" })
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open({})
				require("nvim-dap-virtual-text").refresh()
			end
			dap.listeners.after.disconnect["dapui_config"] = function()
				require("dap.repl").close()
				dapui.close()
				require("nvim-dap-virtual-text").refresh()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function(event)
				vim.notify(string.format("program '%s' was terminated.", vim.fn.fnamemodify(event.config.program, ":t")), 2)
				require("nvim-dap-virtual-text").refresh()
				dapui.close({})
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close({})
				require("nvim-dap-virtual-text").refresh()
			end
			dap.adapters = {
				codelldb = {
					type = "server", -- change to executeable
					port = "${port}",
					executable = {
						command = require("mason-registry").get_package("codelldb"):get_install_path() .. "/codelldb",
						args = { "--port", "${port}" },
					},
				},
				node2 = {
					type = "executable",
					command = "node",
					args = { require("mason-registry").get_package("node-debug2-adapter"):get_install_path() .. "/out/src/nodeDebug.js" },
				},
			}

			local cache = { cpp = { args = {} } }
			dap.configurations = {
				cpp = {
					{
						type = "codelldb",
						name = "Launch file",
						request = "launch",
						program = function()
							local program
							vim.ui.input({
								prompt = "Enter path to executable: ",
								default = require("mason-registry").get_package("codelldb"):get_install_path() .. "/codelldb" or cache.cpp.program,
								completion = "file",
							}, function(input)
								program = input
								cache.cpp.program = program
								vim.cmd.stopinsert()
							end)
							return vim.fn.fnamemodify(program, ":p")
						end,
						args = function()
							local args = ""
							local fpath_base = vim.fn.expand("%:p:r")
							vim.ui.input({
								prompt = "Enter arguments: ",
								default = cache.cpp.program and cache.cpp.args[cache.cpp.program] or cache.cpp.args[fpath_base],
								completion = "file",
							}, function(input)
								args = input
								cache.cpp.args[cache.cpp.program or fpath_base] = args
								vim.cmd.stopinsert()
							end)
							return vim.split(args, " ")
						end,
						cwd = "${workspaceFolder}",
						stopOnEntry = false,
					},
				},
				c = dap.configurations.cpp,
				rust = dap.configurations.cpp,
				typescript = {
					{
						name = "Attach to docker",
						type = "node2",
						request = "attach",
						port = 9229,
						host = "localhost",
						sourceMaps = true,
						localRoot = "${workspaceFolder}",
						remoteRoot = "/app",
						sourceMapPathOverrides = {
							["./*"] = "${workspaceFolder}/src/*",
						},
					},
					{
						name = "Attach",
						type = "node2",
						request = "attach",
						port = 9229,
						host = "localhost",
						sourceMaps = true,
						sourceMapPathOverrides = {
							["./*"] = "${workspaceFolder}/src/*",
						},
					},
					{
						name = "Attach to Jest",
						type = "node2",
						request = "attach",
						port = 9228,
						host = "localhost",
						sourceMaps = true,
						sourceMapPathOverrides = {
							["./*"] = "${workspaceFolder}/src/*",
						},
					},
					{
						name = "Jest Neotest",
						type = "pwa-node",
						request = "launch",
						runtimeExecutable = "node",
						runtimeArgs = {
							"-r",
							"tsconfig-paths/register",
							"-r",
							"ts-node/register node_modules/.bin/jest",
							"--runInBand",
							"--no-coverage",
						},
						rootPath = "${workspaceFolder}",
						cwd = "${workspaceFolder}",
						console = "integratedTerminal",
						internalConsoleOptions = "neverOpen",
						sourceMaps = true,
						sourceMapPathOverrides = {
							["./*"] = "${workspaceFolder}/src/*",
						},
					},
				},
				javascript = dap.configurations.typescript,
			}
		end,
		keys = function()
			local dap, ui, widget = require("dap"), require("dapui"), require("dap.ui.widgets")
			return {
                -- stylua: ignore start
				{ "<leader>dC", function() dap.set_breakpoint(vim.fn.input("[Condition] > ")) end, desc = "Conditional Breakpoint" },
				{ "<leader>dE", function() ui.eval(vim.fn.input("[Expression] > ")) end, desc = "Evaluate Input" },
				{ "<leader>dR", function() dap.run_to_cursor() end, desc = "Run to Cursor" },
				{ "<leader>dS", function() widget.scopes() end, desc = "Scopes" },
				{ "<leader>dU", function() ui.toggle() end, desc = "Toggle UI" },
				{ "<leader>dX", function() dap.close() end, desc = "Quit" },
				{ "<leader>db", function() dap.step_back() end, desc = "Step Back" },
				{ "<leader>dc", function() dap.continue() end, desc = "Continue" },
				{ "<leader>dd", function() dap.disconnect() end, desc = "Disconnect" },
				{ "<leader>de", function() ui.eval() end, mode = { "n", "v"}, desc = "Evaluate", },
				{ "<leader>dg", function() dap.session() end, desc = "Get Session" },
				{ "<leader>dh", function() widget.hover() end, desc = "Hover Variables" },
				{ "<leader>di", function() dap.step_into() end, desc = "Step Into" },
				{ "<leader>do", function() dap.step_over() end, desc = "Step Over" },
				{ "<leader>dp", function() dap.pause.toggle() end, desc = "Pause" },
				{ "<leader>dr", function() dap.repl.toggle({ height = 10 },"botright split") end, desc = "Toggle REPL" },
				{ "<leader>ds", function() dap.continue() end, desc = "Start" },
				{ "<leader>dt", function() dap.toggle_breakpoint() end, desc = "Toggle Breakpoint" },
				{ "<leader>du", function() dap.step_out() end, desc = "Step Out" },
				{ "<leader>dx", function() dap.terminate() end, desc = "Terminate" },
				-- stylua: ignore end
			}
		end,
	},
	{ "nvim-neotest/neotest-go", ft = "go" },
	{ "llllvvuu/neotest-foundry", ft = "solidity" },
	{
		"nvim-neotest/neotest",
		config = function()
			require("neotest").setup({
				adapters = {
					require("neotest-go")({ experimental = { test_table = true }, args = { "-count=1", "-timeout=60s" } }),
					require("neotest-foundry")({
						foundryCommand = "forge test",
						foundryConfig = nil,
						env = {}, -- table | function
						cwd = function()
							return require("directory").get_cwd()
						end,
						filterDir = function(name)
							return not vim.tbl_contains({ "node_modules", "cache", "out", "artifacts", "docs", "doc" }, name)
						end,
					}),
				},
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
			})
		end,
		keys = function()
			local test = require("neotest")
			return {
            -- stylua: ignore start
			{ "<leader>tF", function() test.run.run({ vim.fn.expand("%"), strategy = "dap" }) end, desc = "Test Debug File" },
			{ "<leader>tL", function() test.run.run_last({ strategy = "dap" }) end, desc = "Debug Last Test" },
			{ "<leader>ta", function() test.run.attach() end, desc = "Test Attach" },
			{ "<leader>tf", function() test.run.run(vim.fn.expand("%")) end, desc = "Test File" },
			{ "<leader>tl", function() test.run.run_last() end, desc = "Run Last" },
			{ "<leader>tn", function() test.run.run() end, desc = "Nearest Test" },
			{ "<leader>tN", function() test.run.run({ strategy = "dap" }) end, desc = "Debug Nearest" },
			{ "<leader>to", function() test.output_panel.toggle() end, desc = "Output Panel" },
			{ "<leader>tx", function() test.run.stop() end, desc = "Test Stop" },
			{ "<leader>ts", function() test.summary.toggle() end, desc = "Test Summary" },
				-- stylua: ignore end
			}
		end,
	},
	{
		"mfussenegger/nvim-lint",
		event = "LspAttach",
		opts = {
			events = { "BufWritePost" },
			linters_by_ft = {
				lua = { "selene" },
				go = { "golangcilint" },
			},
			linters = {
				selene = {
					condition = function(ctx)
						return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
					end,
				},
				golangcilint = {
					condition = function(ctx)
						return vim.fs.find({ ".golangci.yml" }, { path = ctx.filename, upward = true })[1]
					end,
				},
			},
		},
		config = function(_, opts)
			local M = {}

			local lint = require("lint")
			for name, linter in pairs(opts.linters) do
				if type(linter) == "table" and type(lint.linters[name]) == "table" then
					lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
				else
					lint.linters[name] = linter
				end
			end
			lint.linters_by_ft = opts.linters_by_ft

			function M.debounce(ms, fn)
				local timer = vim.loop.new_timer()
				return function(...)
					local argv = { ... }
					timer:start(ms, 0, function()
						timer:stop()
						vim.schedule_wrap(fn)(table.unpack(argv))
					end)
				end
			end

			function M.lint()
				local names = lint._resolve_linter_by_ft(vim.bo.filetype)

				-- Add fallback linters.
				if #names == 0 then
					vim.list_extend(names, lint.linters_by_ft["_"] or {})
				end

				-- Add global linters.
				vim.list_extend(names, lint.linters_by_ft["*"] or {})

				-- Filter out linters that don't exist or don't match the condition.
				local ctx = { filename = vim.api.nvim_buf_get_name(0) }
				ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
				names = vim.tbl_filter(function(name)
					local linter = lint.linters[name]
					if not linter then
						vim.notify("Linter not found: " .. name, 3, { title = "nvim-lint" })
					end
					return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
				end, names)

				-- Run linters.
				if #names > 0 then
					lint.try_lint(names)
				end
			end

			vim.api.nvim_create_autocmd(opts.events, {
				group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
				callback = M.debounce(1000, M.lint),
			})
		end,
	},

	{
		"rest-nvim/rest.nvim",
		keys = { { "<leader>tr", "<Plug>RestNvim<cr>", desc = "Test REST" } },
		config = function()
			require("rest-nvim").setup({
				result_split_horizontal = false,
				result_split_in_place = false,
				stay_in_current_window_after_split = false,
				skip_ssl_verification = false,
				encode_url = true,
				highlight = { enabled = true, timeout = 200 },
				result = {
					show_url = false,
					show_curl_command = false,
					show_http_info = true,
					show_headers = true,
					show_statistics = false,
					formatters = {
						json = "jq",
						html = function(body)
							return vim.fn.system({ "tidy", "-i", "-q", "-" }, body)
						end,
					},
				},
				yank_dry_run = true,
				search_back = true,
			})
		end,
	},
}
