return {
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		cmd = "ConformInfo",
		init = vim.schedule_wrap(function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end),
		opts = function()
			return {
				formatters_by_ft = { lua = { "stylua" } },
				format_after_save = { lsp_format = "fallback" },
				formatters = {},
			}
		end,
	},
	{

		"williamboman/mason.nvim",
		cmd = "Mason",
		build = ":MasonUpdate",
		opts = function()
			return {
				PATH = "prepend",
				max_concurrent_installers = 20,
				ensure_installed = {
					"lua-language-server",
					"stylua",

					"gopls",
					"goimports-reviser",
					"delve",
					"go-debug-adapter",

					"clangd",
					"clang-format",
					"codelldb",

					"debugpy",
					"ruff",
					"basedpyright",

					"vtsls",
					"prettier",
					"js-debug-adapter",

					"rust-analyzer",
					"bacon",

					"html-lsp",
					"templ",
					"css-lsp",

					"vscode-solidity-server",
					"solhint",

					"marksman",
					"vale",
				},
			}
		end,
		---@param opts MasonSettings | {ensure_installed: string[]}
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")
			mr:on("package:install:success", function()
				vim.defer_fn(function()
					-- trigger FileType event to possibly load this newly installed LSP server
					require("lazy.core.handler.event").trigger({
						event = "FileType",
						buf = vim.api.nvim_get_current_buf(),
					})
				end, 100)
			end)

			mr.refresh(function()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end)
		end,
	},
	{
		"echasnovski/mini.comment",
		event = "VeryLazy",
		dependencies = { { "JoosepAlviste/nvim-ts-context-commentstring", opts = { enable_autocmd = false } } },
		opts = function()
			return {
				pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
			}
		end,
	},

	{
		"mfussenegger/nvim-lint",
		event = "BufWritePre",
		opts = function()
			return {
				events = { "BufWritePost", "BufReadPost", "InsertLeave" },
				linters_by_ft = {
					lua = { "selene" },
				},
				---@type table<string,table>
				linters = {
					selene = {
						condition = function(ctx)
							return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
						end,
					},
				},
			}
		end,
		config = function(_, opts)
			local M = {}

			local lint = require("lint")
			for name, linter in pairs(opts.linters) do
				if type(linter) == "table" and type(lint.linters[name]) == "table" then
					lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
					if type(linter.prepend_args) == "table" then
						lint.linters[name].args = lint.linters[name].args or {}
						vim.list_extend(lint.linters[name].args, linter.prepend_args)
					end
				else
					lint.linters[name] = linter
				end
			end
			lint.linters_by_ft = opts.linters_by_ft

			function M.debounce(ms, fn)
				local timer = vim.uv.new_timer()
				return function(...)
					local argv = { ... }
					timer:start(ms, 0, function()
						timer:stop()
						vim.schedule_wrap(fn)(unpack(argv))
					end)
				end
			end

			function M.lint()
				-- Use nvim-lint's logic first:
				-- * checks if linters exist for the full filetype first
				-- * otherwise will split filetype by "." and add all those linters
				-- * this differs from conform.nvim which only uses the first filetype that has a formatter
				local names = lint._resolve_linter_by_ft(vim.bo.filetype)

				-- Create a copy of the names table to avoid modifying the original.
				names = vim.list_extend({}, names)

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
						vim.notify("Linter not found: " .. name, 2, { title = "nvim-lint" })
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
				callback = M.debounce(100, M.lint),
			})
		end,
	},
	{
		"nvim-neotest/neotest",
		dependencies = {
			{ "nvim-neotest/neotest-python", ft = "python" },
			{ "nvim-neotest/neotest-go", ft = "go" },
		},
		opts = function()
			local utils = require("utils")
			return {
				adapters = {
					["neotest-python"] = {
						runner = "pytest",
						python = ".venv/bin/python",
					},
					["neotest-golang"] = {
						go_test_args = { "-v", "-race", "-count=1", "-timeout=60s" },
						dap_go_enabled = true,
					},
				},
				status = { virtual_text = true },
				output = { open_on_run = true },
				quickfix = {
					open = function()
						if utils.has_plugin("trouble.nvim") then
							require("trouble").open({ mode = "quickfix", focus = false })
						else
							vim.cmd("copen")
						end
					end,
				},
			}
		end,
		config = function(_, opts)
			local neotest_ns = vim.api.nvim_create_namespace("neotest")
			local utils = require("utils")
			vim.diagnostic.config({
				virtual_text = {
					format = function(diagnostic)
						-- Replace newline and tab characters with space for more compact diagnostics
						local message =
							diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
						return message
					end,
				},
			}, neotest_ns)

			if utils.has_plugin("trouble.nvim") then
				opts.consumers = opts.consumers or {}
				-- Refresh and auto close trouble after running tests
				---@type neotest.Consumer
				opts.consumers.trouble = function(client)
					client.listeners.results = function(adapter_id, results, partial)
						if partial then
							return
						end
						local tree = assert(client:get_position(nil, { adapter = adapter_id }))

						local failed = 0
						for pos_id, result in pairs(results) do
							if result.status == "failed" and tree:get_key(pos_id) then
								failed = failed + 1
							end
						end
						vim.schedule(function()
							local trouble = require("trouble")
							if trouble.is_open() then
								trouble.refresh()
								if failed == 0 then
									trouble.close()
								end
							end
						end)
						return {}
					end
				end
			end

			if opts.adapters then
				local adapters = {}
				for name, config in pairs(opts.adapters or {}) do
					if type(name) == "number" then
						if type(config) == "string" then
							config = require(config)
						end
						adapters[#adapters + 1] = config
					elseif config ~= false then
						local adapter = require(name)
						if type(config) == "table" and not vim.tbl_isempty(config) then
							local meta = getmetatable(adapter)
							if adapter.setup then
								adapter.setup(config)
							elseif adapter.adapter then
								adapter.adapter(config)
								adapter = adapter.adapter
							elseif meta and meta.__call then
								adapter(config)
							else
								error("Adapter " .. name .. " does not support setup")
							end
						end
						adapters[#adapters + 1] = adapter
					end
				end
				opts.adapters = adapters
			end

			require("neotest").setup(opts)
		end,
		keys = {
            -- stylua: ignore start
			{ "<leader>tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File", },
			{ "<leader>tT", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run All Test Files", },
			{ "<leader>tr", function() require("neotest").run.run() end, desc = "Run Nearest", },
			{ "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last", },
			{ "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary", },
			{ "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output", },
			{ "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel", },
			{ "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop", },
			{ "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle Watch", },
			-- stylua: ignore end
		},
	},

	{
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
	},

	{
		"mistweaverco/kulala.nvim",
		ft = "http",
		opts = function()
			vim.api.nvim_create_user_command("KulalaRun", require("kulala").run, {})
			vim.api.nvim_create_user_command("KulalaToggle", require("kulala").toggle_view, {})
			vim.api.nvim_create_user_command("KulalaPrev", require("kulala").jump_prev, {})
			vim.api.nvim_create_user_command("KulalaNext", require("kulala").jump_next, {})
			return {
				icons = {
					inlay = {
						loading = "󱦟 ",
						done = " ",
						error = "󰬅 ",
					},
				},
				additional_curl_options = {},
			}
		end,
	},
	{
		"echasnovski/mini.ai",
		event = "VeryLazy",
		opts = function()
			local ai = require("mini.ai")
			return {
				n_lines = 500,
				custom_textobjects = {
					o = ai.gen_spec.treesitter({ -- code block
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}),
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
					t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
					d = { "%f[%d]%d+" }, -- digits
					e = { -- Word with case
						{
							"%u[%l%d]+%f[^%l%d]",
							"%f[%S][%l%d]+%f[^%l%d]",
							"%f[%P][%l%d]+%f[^%l%d]",
							"^[%l%d]+%f[^%l%d]",
						},
						"^().*()$",
					},
					i = function(ai_type)
						local spaces = (" "):rep(vim.o.tabstop)
						local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
						local indents = {} ---@type {line: number, indent: number, text: string}[]
						for l, line in ipairs(lines) do
							if not line:find("^%s*$") then
								indents[#indents + 1] =
									{ line = l, indent = #line:gsub("\t", spaces):match("^%s*"), text = line }
							end
						end
						local ret = {} ---@type (Mini.ai.region | {indent: number})[]
						for i = 1, #indents do
							if i == 1 or indents[i - 1].indent < indents[i].indent then
								local from, to = i, i
								for j = i + 1, #indents do
									if indents[j].indent < indents[i].indent then
										break
									end
									to = j
								end
								from = ai_type == "a" and from > 1 and from - 1 or from
								to = ai_type == "a" and to < #indents and to + 1 or to
								ret[#ret + 1] = {
									indent = indents[i].indent,
									from = {
										line = indents[from].line,
										col = ai_type == "a" and 1 or indents[from].indent + 1,
									},
									to = { line = indents[to].line, col = #indents[to].text },
								}
							end
						end
						return ret
					end,
					g = function(ai_type)
						local start_line, end_line = 1, vim.fn.line("$")
						if ai_type == "i" then
							-- Skip first and last blank lines for `i` textobject
							local first_nonblank, last_nonblank =
								vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
							-- Do nothing for buffer with all blanks
							if first_nonblank == 0 or last_nonblank == 0 then
								return { from = { line = start_line, col = 1 } }
							end
							start_line, end_line = first_nonblank, last_nonblank
						end

						local to_col = math.max(vim.fn.getline(end_line):len(), 1)
						return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
					end,

					u = ai.gen_spec.function_call(), -- u for "Usage"
					U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
				},
			}
		end,
		config = function(_, opts)
			require("mini.ai").setup(opts)
			vim.schedule(function()
				local objects = {
					{ " ", desc = "whitespace" },
					{ '"', desc = '" string' },
					{ "'", desc = "' string" },
					{ "(", desc = "() block" },
					{ ")", desc = "() block with ws" },
					{ "<", desc = "<> block" },
					{ ">", desc = "<> block with ws" },
					{ "?", desc = "user prompt" },
					{ "U", desc = "use/call without dot" },
					{ "[", desc = "[] block" },
					{ "]", desc = "[] block with ws" },
					{ "_", desc = "underscore" },
					{ "`", desc = "` string" },
					{ "a", desc = "argument" },
					{ "b", desc = ")]} block" },
					{ "c", desc = "class" },
					{ "d", desc = "digit(s)" },
					{ "e", desc = "CamelCase / snake_case" },
					{ "f", desc = "function" },
					{ "g", desc = "entire file" },
					{ "i", desc = "indent" },
					{ "o", desc = "block, conditional, loop" },
					{ "q", desc = "quote `\"'" },
					{ "t", desc = "tag" },
					{ "u", desc = "use/call" },
					{ "{", desc = "{} block" },
					{ "}", desc = "{} with ws" },
				}

				local ret = { mode = { "o", "x" } }
				---@type table<string, string>
				local mappings = vim.tbl_extend("force", {}, {
					around = "a",
					inside = "i",
					around_next = "an",
					inside_next = "in",
					around_last = "al",
					inside_last = "il",
				}, opts.mappings or {})
				mappings.goto_left = nil
				mappings.goto_right = nil

				for name, prefix in pairs(mappings) do
					name = name:gsub("^around_", ""):gsub("^inside_", "")
					ret[#ret + 1] = { prefix, group = name }
					for _, obj in ipairs(objects) do
						local desc = obj.desc
						if prefix:sub(1, 1) == "i" then
							desc = desc:gsub(" with ws", "")
						end
						ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
					end
				end
				require("which-key").add(ret, { notify = false })
			end)
		end,
	},
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = { "tpope/vim-dadbod", lazy = true },
		cmd = "DBUI",
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
		end,
	},
}
