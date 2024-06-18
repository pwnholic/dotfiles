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
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{
				"rcarriga/nvim-dap-ui",
				keys = {
					{
						"<leader>du",
						function()
							require("dapui").toggle({})
						end,
						desc = "Dap UI",
					},
					{
						"<leader>de",
						function()
							require("dapui").eval()
						end,
						desc = "Eval",
						mode = { "n", "v" },
					},
				},
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

			-- virtual text for the debugger
			{
				"theHamsta/nvim-dap-virtual-text",
				opts = {
					enabled_commands = true,
					all_frames = true,
				},
			},
		},

		keys = {
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
				end,
				desc = "Breakpoint Condition",
			},
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle Breakpoint",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Continue",
			},
			{
				"<leader>da",
				function()
					require("dap").continue({ before = get_args })
				end,
				desc = "Run with Args",
			},
			{
				"<leader>dC",
				function()
					require("dap").run_to_cursor()
				end,
				desc = "Run to Cursor",
			},
			{
				"<leader>dg",
				function()
					require("dap").goto_()
				end,
				desc = "Go to Line (No Execute)",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Step Into",
			},
			{
				"<leader>dj",
				function()
					require("dap").down()
				end,
				desc = "Down",
			},
			{
				"<leader>dk",
				function()
					require("dap").up()
				end,
				desc = "Up",
			},
			{
				"<leader>dl",
				function()
					require("dap").run_last()
				end,
				desc = "Run Last",
			},
			{
				"<leader>do",
				function()
					require("dap").step_out()
				end,
				desc = "Step Out",
			},
			{
				"<leader>dO",
				function()
					require("dap").step_over()
				end,
				desc = "Step Over",
			},
			{
				"<leader>dp",
				function()
					require("dap").pause()
				end,
				desc = "Pause",
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.toggle()
				end,
				desc = "Toggle REPL",
			},
			{
				"<leader>ds",
				function()
					require("dap").session()
				end,
				desc = "Session",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate",
			},
			{
				"<leader>dw",
				function()
					require("dap.ui.widgets").hover()
				end,
				desc = "Widgets",
			},
		},

		config = function()
			local dap = require("dap")
			local vscode = require("dap.ext.vscode")
			local json = require("plenary.json")
			local icons = require("utils.icons").dap
            -- stylua: ignore start
			vim.fn.sign_define("DapBreakpoint", { text = icons.Breakpoint, texthl = "DiagnosticSignHint" })
			vim.fn.sign_define( "DapBreakpointCondition", { text = icons.BreakpointCondition, texthl = "DiagnosticSignInfo" })
			vim.fn.sign_define( "DapBreakpointRejected", { text = icons.BreakpointRejected, texthl = "DiagnosticSignWarn" })
			vim.fn.sign_define("DapLogPoint", { text = icons.LogPoint, texthl = "DiagnosticSignOk" })
			vim.fn.sign_define("DapStopped", { text = icons.Stopped, texthl = "DiagnosticSignError" })
			-- stylua: ignore end

			vscode.json_decode = function(str)
				return vim.json.decode(json.json_strip_comments(str))
			end

			dap.adapters.delve = function(callback, config)
				local stdout = vim.uv.new_pipe()
				local handle
				local pid_or_err
				local host = config.host or "127.0.0.1"
				local port = config.port or "38697"
				local addr = string.format("%s:%s", host, port)
				local opts = {
					stdio = { nil, stdout },
					args = { "dap", "-l", addr },
					detached = true,
				}
				handle, pid_or_err = vim.uv.spawn("dlv", opts, function(code)
					stdout:close()
					handle:close()
					if code ~= 0 then
						print("dlv exited with code", code)
					end
				end)
				assert(handle, "Error running dlv: " .. tostring(pid_or_err))
				stdout:read_start(function(err, chunk)
					assert(not err, err)
					if chunk then
						vim.schedule(function()
							require("dap.repl").append(chunk)
						end)
					end
				end)
				-- Wait for delve to start
				vim.defer_fn(function()
					callback({ type = "server", host = "127.0.0.1", port = port })
				end, 1000 * 5)
			end

			dap.configurations.go = {
				{
					type = "delve",
					name = "Debug",
					request = "launch",
					program = "${file}",
				},
				{
					type = "delve",
					name = "Debug Package",
					request = "launch",
					program = "${fileDirname}",
				},
				{
					type = "delve",
					name = "Attach",
					mode = "local",
					request = "attach",
					processId = require("dap.utils").pick_process,
				},
				{
					type = "delve",
					name = "Debug test",
					request = "launch",
					mode = "test",
					program = "${file}",
				},
				{
					type = "delve",
					name = "Debug test (go.mod)",
					request = "launch",
					mode = "test",
					program = "./${relativeFileDirname}",
				},
			}
		end,
	},
}
