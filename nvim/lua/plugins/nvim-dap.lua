return {
	"mfussenegger/nvim-dap",
	dependencies = {
		{
			"rcarriga/nvim-dap-ui",
			keys = {
                    -- stylua: ignore start
					{ "<leader>du", function() require("dapui").toggle({}) end, desc = "Dap UI" },
					{ "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "v" } },
				-- stylua: ignore end
			},
			opts = function()
				return {
					layouts = {
						{
							elements = {
								{ id = "scopes", size = 0.25 },
								{ id = "breakpoints", size = 0.25 },
								{ id = "stacks", size = 0.25 },
								{ id = "watches", size = 0.25 },
							},
							position = "left",
							size = 40,
						},
						{
							elements = { { id = "repl", size = 0.5 }, { id = "console", size = 0.5 } },
							position = "bottom",
							size = 10,
						},
					},
				}
			end,
			config = function(_, opts)
				local dap = require("dap")
				local dapui = require("dapui")
				dapui.setup(opts)
				dap.listeners.after.event_initialized["dapui_config"] = function()
					dapui.open({})
				end
				dap.listeners.before.event_terminated["dapui_config"] = function()
					dapui.close({})
				end
				dap.listeners.before.event_exited["dapui_config"] = function()
					dapui.close({})
				end
			end,
		},
		{
			"theHamsta/nvim-dap-virtual-text",
			opts = function()
				return { all_frames = true, virt_lines = true }
			end,
		},
	},
	keys = function()
		---@param config {args?:string[]|fun():string[]?}
		local function get_args(config)
			local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
			config = vim.deepcopy(config)
			---@cast args string[]
			config.args = function()
				local new_args = vim.fn.input("Run with args: ", table.concat(args, " ")) --[[@as string]]
				return vim.split(vim.fn.expand(new_args) --[[@as string]], " ")
			end
			return config
		end

		return {
                -- stylua: ignore start
				{ "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Breakpoint Condition" },
				{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
				{ "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
				{ "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
				{ "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
				{ "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
				{ "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
				{ "<leader>dj", function() require("dap").down() end, desc = "Down" },
				{ "<leader>dk", function() require("dap").up() end, desc = "Up" },
				{ "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
				{ "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
				{ "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
				{ "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
				{ "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
				{ "<leader>ds", function() require("dap").session() end, desc = "Session" },
				{ "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
				{ "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
			-- stylua: ignore end
		}
	end,
	config = function()
		local dap = require("dap")

		dap.adapters.delve = {
			type = "server",
			port = "${port}",
			executable = { command = "dlv", args = { "dap", "-l", "127.0.0.1:${port}" } },
		}

		dap.configurations.go = {
			{ type = "delve", name = "Debug", request = "launch", program = "${file}" },
			{ type = "delve", name = "Debug test", request = "launch", mode = "test", program = "${file}" },
			{
				type = "delve",
				name = "Debug test (go.mod)",
				request = "launch",
				mode = "test",
				program = "./${relativeFileDirname}",
			},
		}

		dap.adapters.python = function(cb, config)
			if config.request == "attach" then
				local port = (config.connect or config).port
				local host = (config.connect or config).host or "127.0.0.1"
				cb({
					type = "server",
					port = assert(port, "`connect.port` is required for a python `attach` configuration"),
					host = host,
					options = {
						source_filetype = "python",
					},
				})
			else
				cb({
					type = "executable",
					command = "debugpy",
					args = { "-m", "debugpy-adapter" },
					options = {
						source_filetype = "python",
					},
				})
			end
		end

		dap.configurations.python = {
			{
				type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
				request = "launch",
				name = "Launch file",
				program = "${file}", -- This configuration will launch the current file if used.
				pythonPath = function()
					local cwd = vim.fn.getcwd()
					if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
						return cwd .. "/venv/bin/python"
					elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
						return cwd .. "/.venv/bin/python"
					else
						return "/usr/bin/python"
					end
				end,
			},
		}
	end,
}