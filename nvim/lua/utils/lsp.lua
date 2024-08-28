local utils = require("utils")
local methods = vim.lsp.protocol.Methods

local M = {}

M.root_patterns = {
	".git/",
	".svn/",
	".bzr/",
	".hg/",
	".project/",
	".pro",
	".sln",
	".vcxproj",
	"Makefile",
	"makefile",
	"MAKEFILE",
	".gitignore",
	".editorconfig",
}

---@type lsp_client_config_t
---@diagnostic disable-next-line: missing-fields
M.default_config = {
	root_patterns = M.root_patterns,
	capabilities = {
		textDocument = {
			completion = {
				dynamicRegistration = false,
				completionItem = {
					snippetSupport = true,
					commitCharactersSupport = true,
					deprecatedSupport = true,
					preselectSupport = true,
					tagSupport = { valueSet = { 1 } },
					insertReplaceSupport = true,
					resolveSupport = {
						properties = {
							"documentation",
							"detail",
							"additionalTextEdits",
							"sortText",
							"filterText",
							"insertText",
							"textEdit",
							"insertTextFormat",
							"insertTextMode",
						},
					},
					insertTextModeSupport = {
						valueSet = {
							1, -- asIs
							2, -- adjustIndentation
						},
					},
					labelDetailsSupport = true,
				},
				contextSupport = true,
				insertTextMode = 1,
				completionList = {
					itemDefaults = {
						"commitCharacters",
						"editRange",
						"insertTextFormat",
						"insertTextMode",
						"data",
					},
				},
			},
		},
	},
}

---@class vim.lsp.ClientConfig: lsp_client_config_t
---@class lsp_client_config_t
---@field cmd? (string[]|fun(dispatchers: table):table)
---@field cmd_cwd? string
---@field cmd_env? (table)
---@field detached? boolean
---@field workspace_folders? (table)
---@field capabilities? lsp.ClientCapabilities
---@field handlers? table<string,function>
---@field settings? table
---@field commands? table
---@field init_options? table
---@field name? string
---@field get_language_id? fun(bufnr: integer, filetype: string): string
---@field offset_encoding? string
---@field on_error? fun(code: integer)
---@field before_init? function
---@field on_init? function
---@field on_exit? fun(code: integer, signal: integer, client_id: integer)
---@field on_attach? fun(client: vim.lsp.Client, bufnr: integer)
---@field trace? 'off'|'messages'|'verbose'|nil
---@field flags? table
---@field root_dir? string
---@field root_patterns? string[]

---Wrapper of `vim.lsp.start()`, starts and attaches LSP client for
---the current buffer
---@param config lsp_client_config_t
---@param opts table?
---@return integer? client_id id of attached client or nil if failed
function M.start(config, opts)
	if vim.b.bigfile or vim.bo.bt == "nofile" then
		return
	end
	local cmd_type = type(config.cmd)
	local cmd_exec = cmd_type == "table" and config.cmd[1]
	if cmd_type == "table" and vim.fn.executable(cmd_exec or "") == 0 then
		return
	end
	local name = cmd_exec
	local bufname = vim.api.nvim_buf_get_name(0)
	local root_dir = vim.fn.fnamemodify(
		vim.fs.root(bufname, vim.list_extend(config.root_patterns or {}, M.default_config.root_patterns or {}))
			or vim.fs.dirname(bufname),
		"%:p"
	)
	if not vim.uv.fs_stat(root_dir) then
		return
	end

	return vim.lsp.start(
		---@diagnostic disable-next-line: param-type-mismatch
		vim.tbl_deep_extend("keep", config or {}, { name = name, root_dir = root_dir }, M.default_config),
		opts
	)
end

---@class lsp_soft_stop_opts_t
---@field retry integer?
---@field interval integer?
---@field on_close fun(client: vim.lsp.Client)

---Soft stop LSP client with retries
---@param client_or_id integer|vim.lsp.Client
---@param opts lsp_soft_stop_opts_t?
function M.soft_stop(client_or_id, opts)
	local client = type(client_or_id) == "number" and vim.lsp.get_client_by_id(client_or_id) or client_or_id --[[@as vim.lsp.Client]]
	if not client then
		return
	end
	opts = opts or {}
	opts.retry = opts.retry or 4
	opts.interval = opts.interval or 500
	opts.on_close = opts.on_close or function() end

	if opts.retry <= 0 then
		client.stop(true)
		opts.on_close(client)
		return
	end
	client.stop()
	---@diagnostic disable-next-line: invisible
	if client.is_stopped() then
		opts.on_close(client)
		return
	end
	vim.defer_fn(function()
		opts.retry = opts.retry - 1
		M.soft_stop(client, opts)
	end, opts.interval)
end

---Restart and reattach LSP client
---@param client_or_id integer|vim.lsp.Client
function M.restart(client_or_id)
	local client = type(client_or_id) == "number" and vim.lsp.get_client_by_id(client_or_id) or client_or_id --[[@as vim.lsp.Client]]
	if not client then
		return
	end
	local config = client.config
	local attached_buffers = client.attached_buffers
	M.soft_stop(client, {
		on_close = function()
			for buf, _ in pairs(attached_buffers) do
				if not vim.api.nvim_buf_is_valid(buf) then
					return
				end
				vim.api.nvim_buf_call(buf, function()
					M.start(config)
				end)
			end
		end,
	})
end

function M.on_attach(on_attach, name)
	return vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(args)
			local buffer = args.buf ---@type number
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if client and (not name or client.name == name) then
				return on_attach(client, buffer)
			end
		end,
	})
end

---@class lsp_command_parsed_arg_t : parsed_arg_t
---@field apply boolean|nil
---@field async boolean|nil
---@field bufnr integer|nil
---@field context table|nil
---@field cursor_position table|nil
---@field defaults table|nil
---@field diagnostics table|nil
---@field disable boolean|nil
---@field enable boolean|nil
---@field filter function|nil
---@field float boolean|table|nil
---@field format function|nil
---@field formatting_options table|nil
---@field global boolean|nil
---@field groups table|nil
---@field header string|table|nil
---@field id integer|nil
---@field local boolean|nil
---@field name string|nil
---@field namespace integer|nil
---@field new_name string|nil
---@field open boolean|nil
---@field options table|nil
---@field opts table|nil
---@field pat string|nil
---@field prefix function|string|table|nil
---@field query table|nil
---@field range table|nil
---@field severity integer|nil
---@field severity_map table|nil
---@field severity_sort boolean|nil
---@field show-status boolean|nil
---@field source boolean|string|nil
---@field str string|nil
---@field suffix function|string|table|nil
---@field timeout_ms integer|nil
---@field title string|nil
---@field toggle boolean|nil
---@field win_id integer|nil
---@field winnr integer|nil
---@field wrap boolean|nil

---Parse arguments passed to LSP commands
---@param fargs string[] list of arguments
---@param fn_name_alt string|nil alternative function name
---@return string|nil fn_name corresponding LSP / diagnostic function name
---@return lsp_command_parsed_arg_t parsed the parsed arguments
local function parse_cmdline_args(fargs, fn_name_alt)
	local fn_name = fn_name_alt or fargs[1] and table.remove(fargs, 1) or nil
	local parsed = utils.command.parse_cmdline_args(fargs)
	return fn_name, parsed
end

---@type string<table, subcommand_arg_handler_t>
local subcommand_arg_handler = {
	---LSP command argument handler for functions that receive a range
	---@param args lsp_command_parsed_arg_t
	---@param tbl table information passed to the command
	---@return table args
	range = function(args, tbl)
		args.range = args.range
			or tbl.range > 0 and {
				["start"] = { tbl.line1, 0 },
				["end"] = { tbl.line2, 999 },
			}
			or nil
		return args
	end,
	---Extract the first item from a table, expand it to absolute path if possible
	---@param args lsp_command_parsed_arg_t
	---@return any
	item = function(args)
		for _, item in pairs(args) do
			return type(item) == "string" and vim.uv.fs_realpath(item) or item
		end
	end,
	---Convert the args of the form '<id_1> (<name_1>) <id_2> (<name_2) ...' to
	---list of client ids
	---@param args lsp_command_parsed_arg_t
	---@return integer[]
	lsp_client_ids = function(args)
		local ids = {}
		for _, arg in ipairs(args) do
			local id = tonumber(arg:match("^%d+"))
			if id then
				table.insert(ids, id)
			end
		end
		return ids
	end,
}

---@type table<string, subcommand_completion_t>
local subcommand_completions = {
	bufs = function()
		return vim.tbl_map(tostring, vim.api.nvim_list_bufs())
	end,
	---Get completion for LSP clients
	---@return string[]
	lsp_clients = function(arglead)
		-- Only return candidate list if the argument is empty or ends with '='
		-- to avoid giving wrong completion when argument is incomplete
		if arglead ~= "" and not vim.endswith(arglead, "=") then
			return {}
		end
		return vim.tbl_map(function(client)
			return string.format("%d (%s)", client.id, client.name)
		end, vim.lsp.get_clients())
	end,
	---Get completion for LSP client ids
	---@return integer[]
	lsp_client_ids = function(arglead)
		if arglead ~= "" and not vim.endswith(arglead, "=") then
			return {}
		end
		return vim.tbl_map(function(client)
			return client.id
		end, vim.lsp.get_clients())
	end,
	---Get completion for LSP client names
	---@return integer[]
	lsp_client_names = function(arglead)
		if arglead ~= "" and not vim.endswith(arglead, "=") then
			return {}
		end
		return vim.tbl_map(function(client)
			return client.name
		end, vim.lsp.get_clients())
	end,
}

---@type table<string, string[]|fun(): any[]>
local subcommand_opt_vals = {
	bool = { "v:true", "v:false" },
	severity = { "WARN", "INFO", "ERROR", "HINT" },
	bufs = subcommand_completions.bufs,
	lsp_clients = subcommand_completions.lsp_clients,
	lsp_client_ids = subcommand_completions.lsp_client_ids,
	lsp_client_names = subcommand_completions.lsp_client_names,
	lsp_methods = {
		methods.callHierarchy_incomingCalls,
		methods.callHierarchy_outgoingCalls,
		methods.textDocument_codeAction,
		methods.textDocument_completion,
		methods.textDocument_declaration,
		methods.textDocument_definition,
		methods.textDocument_diagnostic,
		methods.textDocument_documentHighlight,
		methods.textDocument_documentSymbol,
		methods.textDocument_formatting,
		methods.textDocument_hover,
		methods.textDocument_implementation,
		methods.textDocument_inlayHint,
		methods.textDocument_publishDiagnostics,
		methods.textDocument_rangeFormatting,
		methods.textDocument_references,
		methods.textDocument_rename,
		methods.textDocument_semanticTokens_full,
		methods.textDocument_semanticTokens_full_delta,
		methods.textDocument_signatureHelp,
		methods.textDocument_typeDefinition,
		methods.window_logMessage,
		methods.window_showMessage,
		methods.window_showDocument,
		methods.window_showMessageRequest,
		methods.workspace_applyEdit,
		methods.workspace_configuration,
		methods.workspace_executeCommand,
		methods.workspace_inlayHint_refresh,
		methods.workspace_symbol,
		methods.workspace_workspaceFolders,
	},
}

---@alias subcommand_arg_handler_t fun(args: lsp_command_parsed_arg_t, tbl: table): ...?
---@alias subcommand_params_t string[]
---@alias subcommand_opts_t table
---@alias subcommand_fn_override_t fun(...?): ...?
---@alias subcommand_completion_t fun(arglead: string, cmdline: string, cursorpos: integer): string[]

---@class subcommand_info_t
---@field arg_handler subcommand_arg_handler_t?
---@field params subcommand_params_t?
---@field opts subcommand_opts_t?
---@field fn_override subcommand_fn_override_t?
---@field completion subcommand_completion_t?

M.subcommands = {
	---LSP subcommands
	---@type table<string, subcommand_info_t>
	lsp = {
		info = {
			opts = {
				"filter",
				["filter.bufnr"] = subcommand_opt_vals.bufs,
				["filter.id"] = subcommand_opt_vals.lsp_client_ids,
				["filter.name"] = subcommand_opt_vals.lsp_client_names,
				["filter.method"] = subcommand_opt_vals.lsp_methods,
			},
			arg_handler = function(args)
				return args.filter
			end,
			fn_override = function(filter)
				local clients = vim.lsp.get_clients(filter)
				for _, client in ipairs(clients) do
					vim.print({
						id = client.id,
						name = client.name,
						root_dir = client.config.root_dir,
						attached_buffers = vim.tbl_keys(client.attached_buffers),
					})
				end
			end,
		},
		restart = {
			completion = subcommand_completions.lsp_clients,
			arg_handler = subcommand_arg_handler.lsp_client_ids,
			fn_override = function(ids)
				-- Restart all clients attached to current buffer if no ids are given
				local clients = not vim.tbl_isempty(ids)
						and vim.tbl_map(function(id)
							return vim.lsp.get_client_by_id(id)
						end, ids)
					or vim.lsp.get_clients({ bufnr = 0 })
				for _, client in ipairs(clients) do
					utils.lsp.restart(client)
					vim.notify(string.format("[LSP] restarted client %d (%s)", client.id, client.name))
				end
			end,
		},
		get_clients_by_id = {
			completion = subcommand_completions.lsp_clients,
			arg_handler = function(args)
				return tonumber(args[1]:match("^%d+"))
			end,
			fn_override = function(id)
				vim.print(vim.lsp.get_client_by_id(id))
			end,
		},
		get_clients = {
			opts = {
				"filter",
				["filter.bufnr"] = subcommand_opt_vals.bufs,
				["filter.id"] = subcommand_opt_vals.lsp_client_ids,
				["filter.name"] = subcommand_opt_vals.lsp_client_names,
				["filter.method"] = subcommand_opt_vals.lsp_methods,
			},
			arg_handler = function(args)
				return args.filter
			end,
			fn_override = function(filter)
				local clients = vim.lsp.get_clients(filter)
				for _, client in ipairs(clients) do
					vim.print(client)
				end
			end,
		},
		stop = {
			completion = subcommand_completions.lsp_clients,
			arg_handler = subcommand_arg_handler.lsp_client_ids,
			fn_override = function(ids)
				-- Stop all clients attached to current buffer if no ids are given
				local clients = not vim.tbl_isempty(ids)
						and vim.tbl_map(function(id)
							return vim.lsp.get_client_by_id(id)
						end, ids)
					or vim.lsp.get_clients({ bufnr = 0 })
				for _, client in ipairs(clients) do
					utils.lsp.soft_stop(client, {
						on_close = function()
							vim.notify(string.format("[LSP] stopped client %d (%s)", client.id, client.name))
						end,
					})
				end
			end,
		},
		references = {
			has = methods.textDocument_references,
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.context, args.options
			end,
			opts = { "context", "options.on_list" },
		},
		rename = {
			has = methods.textDocument_rename,
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.new_name or args[1], args.options
			end,
			opts = {
				"new_name",
				"options.filter",
				"options.name",
			},
		},
		workspace_symbol = {
			has = methods.workspace_symbol,
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.query, args.options
			end,
			opts = { "query", "options.on_list" },
		},
		format = {
			has = methods.textDocument_formatting,
			arg_handler = subcommand_arg_handler.range,
			opts = {
				"id",
				"name",
				"range",
				"filter",
				"timeout_ms",
				"formatting_options",
				"formatting_options.tabSize",
				["formatting_options.insertSpaces"] = subcommand_opt_vals.bool,
				["formatting_options.trimTrailingWhitespace"] = subcommand_opt_vals.bool,
				["formatting_options.insertFinalNewline"] = subcommand_opt_vals.bool,
				["formatting_options.trimFinalNewlines"] = subcommand_opt_vals.bool,
				["bufnr"] = subcommand_opt_vals.bufs,
				["async"] = subcommand_opt_vals.bool,
			},
		},
		code_action = {
			has = methods.textDocument_codeAction,
			opts = {
				"filter",
				"range",
				"context.only",
				"context.triggerKind",
				"context.diagnostics",
				["apply"] = subcommand_opt_vals.bool,
			},
		},
		add_workspace_folder = {
			has = methods.workspace_workspaceFolders,
			arg_handler = subcommand_arg_handler.item,
			completion = function(arglead, _, _)
				local basedir = arglead == "" and vim.fn.getcwd() or arglead
				local incomplete = nil ---@type string|nil
				if not vim.uv.fs_stat(basedir) then
					basedir = vim.fn.fnamemodify(basedir, ":h")
					incomplete = vim.fn.fnamemodify(arglead, ":t")
				end
				local subdirs = {}
				for name, type in vim.fs.dir(basedir) do
					if type == "directory" and name ~= "." and name ~= ".." then
						table.insert(
							subdirs,
							vim.fn.fnamemodify(vim.fn.resolve(vim.fs.joinpath(basedir, name)), ":p:~:.")
						)
					end
				end
				if incomplete then
					return vim.tbl_filter(function(s)
						return s:find(incomplete, 1, true)
					end, subdirs)
				end
				return subdirs
			end,
		},
		remove_workspace_folder = {
			has = methods.workspace_workspaceFolders,
			arg_handler = subcommand_arg_handler.item,
			completion = function(_, _, _)
				return vim.tbl_map(function(path)
					local short = vim.fn.fnamemodify(path, ":p:~:.")
					return short ~= "" and short or "./"
				end, vim.lsp.buf.list_workspace_folders())
			end,
		},
		execute_command = {
			has = methods.workspace_executeCommand,
			arg_handler = subcommand_arg_handler.item,
		},
		type_definition = {
			has = methods.textDocument_typeDefinition,
			opts = {
				"reuse_win",
				["on_list"] = subcommand_opt_vals.bool,
			},
		},
		declaration = {
			has = methods.textDocument_declaration,
			opts = {
				"reuse_win",
				["on_list"] = subcommand_opt_vals.bool,
			},
		},
		definition = {
			has = methods.textDocument_definition,
			opts = {
				"reuse_win",
				["on_list"] = subcommand_opt_vals.bool,
			},
		},
		document_symbol = {
			has = methods.textDocument_documentSymbol,
			opts = {
				["on_list"] = subcommand_opt_vals.bool,
			},
		},
		implementation = {
			has = methods.textDocument_implementation,
			opts = {
				["on_list"] = subcommand_opt_vals.bool,
			},
		},
		hover = {
			has = methods.textDocument_hover,
		},
		document_highlight = {
			has = methods.textDocument_documentHighlight,
		},
		clear_references = {
			has = methods.textDocument_documentHighlight,
		},
		list_workspace_folders = {
			has = methods.workspace_workspaceFolders,
			fn_override = function()
				vim.print(vim.lsp.buf.list_workspace_folders())
			end,
		},
		incoming_calls = {
			has = methods.callHierarchy_incomingCalls,
		},
		outgoing_calls = {
			has = methods.callHierarchy_outgoingCalls,
		},
		signature_help = {
			has = methods.textDocument_signatureHelp,
		},
		codelens_clear = {
			has = methods.textDocument_codeLens,
			fn_override = function(args)
				vim.lsp.codelens.clear(args.client_id, args.bufnr)
			end,
			opts = {
				["client_id"] = subcommand_opt_vals.lsp_clients,
				["bufnr"] = subcommand_opt_vals.bufs,
			},
		},
		codelens_display = {
			has = methods.textDocument_codeLens,
			fn_override = function(args)
				vim.lsp.codelens.display(args.lenses, args.bufnr, args.client_id)
			end,
			opts = {
				["client_id"] = subcommand_opt_vals.lsp_clients,
				["bufnr"] = subcommand_opt_vals.bufs,
				"lenses",
			},
		},
		codelens_get = {
			has = methods.textDocument_codeLens,
			fn_override = function(args)
				vim.lsp.codelens.get(args[1])
			end,
			completion = subcommand_completions.bufs,
		},
		codelens_on_codelens = {
			has = methods.textDocument_codeLens,
			fn_override = function(args)
				vim.lsp.codelens.on_codelens(args.err, args.result, args.ctx)
			end,
			opts = { "err", "result", "ctx" },
		},
		codelens_refresh = {
			has = methods.textDocument_codeLens,
			fn_override = function(args)
				vim.lsp.codelens.refresh(args.opts)
			end,
			opts = {
				"opts",
				["opts.bufnr"] = subcommand_opt_vals.bufs,
			},
		},
		codelens_run = {
			has = methods.textDocument_codeLens,
			fn_override = vim.lsp.codelens.run,
		},
		codelens_save = {
			has = methods.textDocument_codeLens,
			fn_override = function(args)
				vim.lsp.codelens.save(args.lenses, args.bufnr, args.client_id)
			end,
			opts = {
				"lenses",
				["bufnr"] = subcommand_opt_vals.bufs,
				["client_id"] = subcommand_opt_vals.lsp_clients,
			},
		},
		inlay_hint_enable = {
			has = methods.textDocument_inlayHint,
			fn_override = function(args)
				vim.lsp.inlay_hint.enable(true, args.filter)
			end,
			opts = {
				"filter",
				["filter.bufnr"] = subcommand_opt_vals.bufs,
			},
		},
		inlay_hint_disable = {
			has = methods.textDocument_inlayHint,
			fn_override = function(args)
				vim.lsp.inlay_hint.enable(false, args.filter)
			end,
			opts = {
				"filter",
				["filter.bufnr"] = subcommand_opt_vals.bufs,
			},
		},
		inlay_hint_toggle = {
			has = methods.textDocument_inlayHint,
			fn_override = function(args)
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(), args.filter)
			end,
			opts = {
				"filter",
				["filter.bufnr"] = subcommand_opt_vals.bufs,
			},
		},
		inlay_hint_get = {
			has = methods.textDocument_inlayHint,
			fn_override = function(args)
				vim.print(vim.lsp.inlay_hint.get(args.filter))
			end,
			opts = {
				"filter",
				"filter.range",
				["filter.bufnr"] = subcommand_opt_vals.bufs,
			},
		},
		inlay_hint_is_enabled = {
			has = methods.textDocument_inlayHint,
			fn_override = function(args)
				vim.print(vim.lsp.inlay_hint.is_enabled(args.filter))
			end,
			opts = {
				"filter",
				["filter.bufnr"] = subcommand_opt_vals.bufs,
			},
		},
		semantic_tokens_force_refresh = {
			has = methods.textDocument_semanticTokens_full,
			fn_override = function(args)
				vim.lsp.semantic_tokens.force_refresh(args[1])
			end,
			completion = subcommand_completions.bufs,
		},
		semantic_tokens_get_at_pos = {
			has = methods.textDocument_semanticTokens_full,
			fn_override = function(args)
				vim.print(vim.lsp.semantic_tokens.get_at_pos(args.bufnr or 0, args.row, args.col))
			end,
			opts = {
				["bufnr"] = subcommand_opt_vals.bufs,
				"row",
				"col",
			},
		},
		semantic_tokens_highlight_token = {
			has = methods.textDocument_semanticTokens_full,
			fn_override = function(args)
				vim.lsp.semantic_tokens.highlight_token(
					args.token,
					args.bufnr or 0,
					args.client_id,
					args.hl_group,
					args.opts
				)
			end,
			opts = {
				"token",
				["bufnr"] = subcommand_opt_vals.bufs,
				["client_id"] = subcommand_opt_vals.lsp_clients,
				["hl_group"] = function()
					return vim.fn.getcompletion(":hi ", "cmdline")
				end,
				"opts",
				"opts.priority",
			},
		},
		semantic_tokens_start = {
			has = methods.textDocument_semanticTokens_full,
			fn_override = function(args)
				vim.lsp.semantic_tokens.start(args.bufnr or 0, args.client_id, args.opts)
			end,
			opts = {
				["bufnr"] = subcommand_opt_vals.bufs,
				["client_id"] = subcommand_opt_vals.lsp_clients,
				"opts",
				"opts.debounce",
			},
		},
		semantic_tokens_stop = {
			has = methods.textDocument_semanticTokens_full,
			fn_override = function(args)
				vim.lsp.semantic_tokens.stop(args.bufnr or 0, args.client_id)
			end,
			opts = {
				["bufnr"] = subcommand_opt_vals.bufs,
				["client_id"] = subcommand_opt_vals.lsp_clients,
			},
		},
	},

	---Diagnostic subcommands
	---@type table<string, subcommand_info_t>
	diagnostic = {
		config = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.opts, args.namespace
			end,
			opts = {
				"namespace",
				"opts.virtual_text.source",
				"opts.virtual_text.spacing",
				"opts.virtual_text.prefix",
				"opts.virtual_text.suffix",
				"opts.virtual_text.format",
				"opts.signs.priority",
				"opts.signs.text",
				"opts.signs.text.ERROR",
				"opts.signs.text.WARN",
				"opts.signs.text.INFO",
				"opts.signs.text.HINT",
				"opts.signs.numhl",
				"opts.signs.numhl.ERROR",
				"opts.signs.numhl.WARN",
				"opts.signs.numhl.INFO",
				"opts.signs.numhl.HINT",
				"opts.signs.linehl",
				"opts.signs.linehl.ERROR",
				"opts.signs.linehl.WARN",
				"opts.signs.linehl.INFO",
				"opts.signs.linehl.HINT",
				"opts.float",
				"opts.float.namespace",
				"opts.float.scope",
				"opts.float.pos",
				"opts.float.severity_sort",
				"opts.float.header",
				"opts.float.source",
				"opts.float.format",
				"opts.float.prefix",
				"opts.float.suffix",
				"opts.severity_sort",
				["opts.underline"] = subcommand_opt_vals.bool,
				["opts.underline.severity"] = subcommand_opt_vals.severity,
				["opts.virtual_text"] = subcommand_opt_vals.bool,
				["opts.virtual_text.severity"] = subcommand_opt_vals.severity,
				["opts.signs"] = subcommand_opt_vals.bool,
				["opts.signs.severity"] = subcommand_opt_vals.severity,
				["opts.float.bufnr"] = subcommand_opt_vals.bufs,
				["opts.float.severity"] = subcommand_opt_vals.severity,
				["opts.update_in_insert"] = subcommand_opt_vals.bool,
				["opts.severity_sort.reverse"] = subcommand_opt_vals.bool,
			},
		},
		disable = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.bufnr, args.namespace
			end,
			opts = {
				["bufnr"] = subcommand_opt_vals.bufs,
				"namespace",
			},
		},
		enable = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.bufnr, args.namespace
			end,
			opts = {
				["bufnr"] = subcommand_opt_vals.bufs,
				"namespace",
			},
		},
		fromqflist = {
			arg_handler = subcommand_arg_handler.item,
			opts = { "list" },
			fn_override = function(...)
				vim.diagnostic.show(nil, 0, vim.diagnostic.fromqflist(...))
			end,
		},
		get = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.bufnr, args.opts
			end,
			opts = {
				["bufnr"] = subcommand_opt_vals.bufs,
				"opts.namespace",
				"opts.lnum",
				["opts.severity"] = subcommand_opt_vals.severity,
			},
			fn_override = function(...)
				vim.print(vim.diagnostic.get(...))
			end,
		},
		get_namespace = {
			arg_handler = subcommand_arg_handler.item,
			opts = { "namespace" },
			fn_override = function(...)
				vim.print(vim.diagnostic.get_namespace(...))
			end,
		},
		get_namespaces = {
			fn_override = function()
				vim.print(vim.diagnostic.get_namespaces())
			end,
		},
		get_next = {
			opts = {
				"wrap",
				"win_id",
				"namespace",
				"cursor_position",
				"float.namespace",
				"float.scope",
				"float.pos",
				"float.header",
				"float.source",
				"float.format",
				"float.prefix",
				"float.suffix",
				"float.severity_sort",
				["severity"] = subcommand_opt_vals.severity,
				["float"] = subcommand_opt_vals.bool,
				["float.bufnr"] = subcommand_opt_vals.bufs,
				["float.severity"] = subcommand_opt_vals.severity,
			},
			fn_override = function(...)
				vim.print(vim.diagnostic.get_next(...))
			end,
		},
		get_next_pos = {
			opts = {
				"wrap",
				"win_id",
				"namespace",
				"cursor_position",
				"float.namespace",
				"float.scope",
				"float.pos",
				"float.header",
				"float.source",
				"float.format",
				"float.prefix",
				"float.suffix",
				"float.severity_sort",
				["severity"] = subcommand_opt_vals.severity,
				["float"] = subcommand_opt_vals.bool,
				["float.bufnr"] = subcommand_opt_vals.bufs,
				["float.severity"] = subcommand_opt_vals.severity,
			},
			fn_override = function(...)
				vim.print(vim.diagnostic.get_next_pos(...))
			end,
		},
		get_prev = {
			opts = {
				"wrap",
				"win_id",
				"namespace",
				"cursor_position",
				"float.namespace",
				"float.scope",
				"float.pos",
				"float.header",
				"float.source",
				"float.format",
				"float.prefix",
				"float.suffix",
				"float.severity_sort",
				["severity"] = subcommand_opt_vals.severity,
				["float"] = subcommand_opt_vals.bool,
				["float.bufnr"] = subcommand_opt_vals.bufs,
				["float.severity"] = subcommand_opt_vals.severity,
			},
			fn_override = function(...)
				vim.print(vim.diagnostic.get_prev(...))
			end,
		},
		get_prev_pos = {
			opts = {
				"wrap",
				"win_id",
				"namespace",
				"cursor_position",
				"float.namespace",
				"float.scope",
				"float.pos",
				"float.header",
				"float.source",
				"float.format",
				"float.prefix",
				"float.suffix",
				"float.severity_sort",
				["severity"] = subcommand_opt_vals.severity,
				["float"] = subcommand_opt_vals.bool,
				["float.bufnr"] = subcommand_opt_vals.bufs,
				["float.severity"] = subcommand_opt_vals.severity,
			},
			fn_override = function(...)
				vim.print(vim.diagnostic.get_prev_pos(...))
			end,
		},
		goto_next = {
			opts = {
				"wrap",
				"win_id",
				"namespace",
				"cursor_position",
				"float.namespace",
				"float.scope",
				"float.pos",
				"float.header",
				"float.source",
				"float.format",
				"float.prefix",
				"float.suffix",
				"float.severity_sort",
				["severity"] = subcommand_opt_vals.severity,
				["float"] = subcommand_opt_vals.bool,
				["float.bufnr"] = subcommand_opt_vals.bufs,
				["float.severity"] = subcommand_opt_vals.severity,
			},
		},
		goto_prev = {
			opts = {
				"wrap",
				"win_id",
				"namespace",
				"cursor_position",
				"float.namespace",
				"float.scope",
				"float.pos",
				"float.header",
				"float.source",
				"float.format",
				"float.prefix",
				"float.suffix",
				"float.severity_sort",
				["severity"] = subcommand_opt_vals.severity,
				["float"] = subcommand_opt_vals.bool,
				["float.bufnr"] = subcommand_opt_vals.bufs,
				["float.severity"] = subcommand_opt_vals.severity,
			},
		},
		hide = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.namespace, args.bufnr
			end,
			opts = {
				"namespace",
				["bufnr"] = subcommand_opt_vals.bufs,
			},
		},
		is_enabled = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.bufnr, args.namespace
			end,
			opts = {
				"namespace",
				["bufnr"] = subcommand_opt_vals.bufs,
			},
			fn_override = function(...)
				vim.print(vim.diagnostic.is_enabled(...))
			end,
		},
		match = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.str, args.pat, args.groups, args.severity_map, args.defaults
			end,
			opts = {
				"str",
				"pat",
				"groups",
				"severity_map",
				"defaults",
			},
			fn_override = function(...)
				vim.print(vim.diagnostic.match(...))
			end,
		},
		open_float = {
			opts = {
				"pos",
				"scope",
				"header",
				"format",
				"prefix",
				"suffix",
				"namespace",
				["bufnr"] = subcommand_opt_vals.bufs,
				["source"] = subcommand_opt_vals.bool,
				["severity"] = subcommand_opt_vals.severity,
				["severity_sort"] = subcommand_opt_vals.bool,
			},
		},
		reset = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.namespace, args.bufnr
			end,
			opts = {
				"namespace",
				["bufnr"] = subcommand_opt_vals.bufs,
			},
		},
		set = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.namespace, args.bufnr, args.diagnostics, args.opts
			end,
			opts = {
				"namespace",
				"diagnostics",
				"opts.virtual_text.source",
				"opts.virtual_text.spacing",
				"opts.virtual_text.prefix",
				"opts.virtual_text.suffix",
				"opts.virtual_text.format",
				"opts.signs.priority",
				"opts.float",
				"opts.float.namespace",
				"opts.float.scope",
				"opts.float.pos",
				"opts.float.severity_sort",
				"opts.float.header",
				"opts.float.source",
				"opts.float.format",
				"opts.float.prefix",
				"opts.float.suffix",
				"opts.severity_sort",
				["bufnr"] = subcommand_opt_vals.bufs,
				["opts.signs"] = subcommand_opt_vals.bool,
				["opts.signs.severity"] = subcommand_opt_vals.severity,
				["opts.underline"] = subcommand_opt_vals.bool,
				["opts.underline.severity"] = subcommand_opt_vals.severity,
				["opts.virtual_text"] = subcommand_opt_vals.bool,
				["opts.virtual_text.severity"] = subcommand_opt_vals.severity,
				["opts.float.bufnr"] = subcommand_opt_vals.bufs,
				["opts.float.severity"] = subcommand_opt_vals.severity,
				["opts.update_in_insert"] = subcommand_opt_vals.bool,
				["opts.severity_sort.reverse"] = subcommand_opt_vals.bool,
			},
		},
		setloclist = {
			opts = {
				"namespace",
				"winnr",
				"open",
				"title",
				["severity"] = subcommand_opt_vals.severity,
			},
		},
		setqflist = {
			opts = {
				"namespace",
				"open",
				"title",
				["severity"] = subcommand_opt_vals.severity,
			},
		},
		show = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.namespace, args.bufnr, args.diagnostics, args.opts
			end,
			opts = {
				"namespace",
				"diagnostics",
				"opts.virtual_text.source",
				"opts.virtual_text.spacing",
				"opts.virtual_text.prefix",
				"opts.virtual_text.suffix",
				"opts.virtual_text.format",
				"opts.signs.priority",
				"opts.float",
				"opts.float.namespace",
				"opts.float.scope",
				"opts.float.pos",
				"opts.float.severity_sort",
				"opts.float.header",
				"opts.float.source",
				"opts.float.format",
				"opts.float.prefix",
				"opts.float.suffix",
				"opts.severity_sort",
				["bufnr"] = subcommand_opt_vals.bufs,
				["opts.signs"] = subcommand_opt_vals.bool,
				["opts.signs.severity"] = subcommand_opt_vals.severity,
				["opts.underline"] = subcommand_opt_vals.bool,
				["opts.underline.severity"] = subcommand_opt_vals.severity,
				["opts.virtual_text"] = subcommand_opt_vals.bool,
				["opts.virtual_text.severity"] = subcommand_opt_vals.severity,
				["opts.float.bufnr"] = subcommand_opt_vals.bufs,
				["opts.float.severity"] = subcommand_opt_vals.severity,
				["opts.update_in_insert"] = subcommand_opt_vals.bool,
				["opts.severity_sort.reverse"] = subcommand_opt_vals.bool,
			},
		},
		toqflist = {
			arg_handler = subcommand_arg_handler.item,
			opts = { "diagnostics" },
			fn_override = function(...)
				vim.fn.setqflist(vim.diagnostic.toqflist(...))
			end,
		},
	},
}

---Get meta command function
---@param subcommand_info_list subcommand_info_t[] subcommands information
---@param fn_scope table|fun(name: string): function scope of corresponding functions for subcommands
---@param fn_name_alt string|nil name of the function to call given no subcommand
---@return function meta_command_fn
local function command_meta(subcommand_info_list, fn_scope, fn_name_alt)
	---Meta command function, calls the appropriate subcommand with args
	---@param tbl table information passed to the command
	return function(tbl)
		local fn_name, cmdline_args = parse_cmdline_args(tbl.fargs, fn_name_alt)
		if not fn_name then
			return
		end
		local fn = subcommand_info_list[fn_name] and subcommand_info_list[fn_name].fn_override
			or type(fn_scope) == "table" and fn_scope[fn_name]
			or type(fn_scope) == "function" and fn_scope(fn_name)
		if type(fn) ~= "function" then
			return
		end
		local arg_handler = subcommand_info_list[fn_name].arg_handler or function(...)
			return ...
		end
		fn(arg_handler(cmdline_args, tbl))
	end
end

---Get command completion function
---@param meta string meta command name
---@param subcommand_info_list subcommand_info_t[] subcommands information
---@return function completion_fn
local function command_complete(meta, subcommand_info_list)
	---Command completion function
	---@param arglead string leading portion of the argument being completed
	---@param cmdline string entire command line
	---@param cursorpos number cursor position in it (byte index)
	---@return string[] completion completion results
	return function(arglead, cmdline, cursorpos)
		-- If subcommand is not specified, complete with subcommands
		if cmdline:sub(1, cursorpos):match("^%A*" .. meta .. "%s+%S*$") then
			return vim.tbl_filter(
				function(cmd)
					return cmd:find(arglead, 1, true) == 1
				end,
				vim.tbl_filter(function(key)
					local info = subcommand_info_list[key] ---@type subcommand_info_t|table|nil
					return info
							and (info.arg_handler or info.params or info.opts or info.fn_override or info.completion)
							and true
						or false
				end, vim.tbl_keys(subcommand_info_list))
			)
		end
		-- If subcommand is specified, complete with its options or params
		local subcommand = utils.camel_to_snake(cmdline:match("^%s*" .. meta .. "(%w+)"))
			or cmdline:match("^%s*" .. meta .. "%s+(%S+)")
		if not subcommand_info_list[subcommand] then
			return {}
		end
		-- Use subcommand's custom completion function if it exists
		if subcommand_info_list[subcommand].completion then
			return subcommand_info_list[subcommand].completion(arglead, cmdline, cursorpos)
		end
		-- Complete with subcommand's options or params
		local subcommand_info = subcommand_info_list[subcommand]
		if subcommand_info then
			return utils.command.complete(subcommand_info.params, subcommand_info.opts)(arglead, cmdline, cursorpos)
		end
		return {}
	end
end

---Setup commands
---@param meta string meta command name
---@param subcommand_info_list table<string, subcommand_info_t> subcommands information
---@param fn_scope table|fun(name: string): function scope of corresponding functions for subcommands
---@return nil
function M.setup_commands(meta, subcommand_info_list, fn_scope, buffer)
	-- metacommand -> MetaCommand abbreviation
	utils.keys.command_abbrev(meta:lower(), meta)
	-- Format: MetaCommand sub_command opts ...
	vim.api.nvim_create_user_command(meta, command_meta(subcommand_info_list, fn_scope), {
		bang = true,
		range = true,
		nargs = "*",
		complete = command_complete(meta, subcommand_info_list),
	})
	-- Format: MetaCommandSubcommand opts ...
	for subcommand, cap in pairs(subcommand_info_list) do
		local has = not cap.has or M.has_lsp_methods(buffer, cap.has)
		if has then
			vim.api.nvim_create_user_command(
				meta .. utils.snake_to_camel(subcommand),
				command_meta(subcommand_info_list, fn_scope, subcommand),
				{
					bang = true,
					range = true,
					nargs = "*",
					complete = command_complete(meta, subcommand_info_list),
				}
			)
		end
	end
end

local lsp_autostop_pending
---Automatically stop LSP servers that no longer attaches to any buffers
---
---  Once `BufDelete` is triggered, wait for 60s before checking and
---  stopping servers, in this way the callback will be invoked once
---  every 60 seconds at most and can stop multiple clients at once
---  if possible, which is more efficient than checking and stopping
---  clients on every `BufDelete` events
---
---@return nil
function M.setup_lsp_stopidle()
	vim.api.nvim_create_autocmd("BufDelete", {
		group = vim.api.nvim_create_augroup("LspAutoStop", {}),
		desc = "Automatically stop idle language servers.",
		callback = function()
			if lsp_autostop_pending then
				return
			end
			lsp_autostop_pending = true
			vim.defer_fn(function()
				lsp_autostop_pending = nil
				for _, client in ipairs(vim.lsp.get_clients()) do
					if vim.tbl_isempty(client.attached_buffers) then
						utils.lsp.soft_stop(client)
					end
				end
			end, 60000)
		end,
	})
end

function M.get_clients(opts)
	local ret = {} ---@type vim.lsp.Client[]
	if vim.lsp.get_clients then
		ret = vim.lsp.get_clients(opts)
	else
		---@diagnostic disable-next-line: deprecated
		ret = vim.lsp.get_active_clients(opts)
		if opts and opts.method then
			---@param client vim.lsp.Client
			ret = vim.tbl_filter(function(client)
				return client.supports_method(opts.method, { bufnr = opts.bufnr })
			end, ret)
		end
	end
	return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
end

---@param method string|string[]
function M.has_lsp_methods(buffer, method)
	if type(method) == "table" then
		for _, m in ipairs(method) do
			if M.has_lsp_methods(buffer, m) then
				return true
			end
		end
		return false
	end
	local clients = M.get_clients({ bufnr = buffer })
	for _, client in ipairs(clients) do
		if client.supports_method(method) then
			return true
		end
	end
	return false
end

function M.keys_on_attach(_, buffer)
	local Keys = require("lazy.core.handler.keys")
	if not Keys.resolve then
		return {}
	end
	local keymaps = Keys.resolve({
        -- stylua: ignore start
		{ "<leader>gr", "<cmd>FzfLua lsp_references jump_to_single_result=true ignore_current_line=true<cr>", desc = "References", has = methods.textDocument_references },
		{ "gd", "<cmd>FzfLua lsp_definitions jump_to_single_result=true ignore_current_line=true<cr>", desc = "Definition", has = methods.textDocument_definition },
		{ "<leader>gd", "<cmd>FzfLua lsp_declarations jump_to_single_result=true ignore_current_line=true<cr>", desc = "Declaration", has = methods.textDocument_declaration },
		{ "gD ", "<cmd>FzfLua lsp_typedefs jump_to_single_result=true ignore_current_line=true<cr>", desc = "Type Definition", has = methods.textDocument_typeDefinition },
		{ "<leader>gi", "<cmd>FzfLua lsp_implementations jump_to_single_result=true ignore_current_line=true<cr>", desc = "Implementation", has = methods.textDocument_implementation },
		{ "<leader>gi", "<cmd>FzfLua lsp_incoming_calls jump_to_single_result=true ignore_current_line=true<cr>", desc = "Incoming Calls", has = methods.callHierarchy_incomingCalls },
		{ "<leader>go", "<cmd>FzfLua lsp_outgoing_calls jump_to_single_result=true ignore_current_line=true<cr>", desc = "Outgoing Calls", has = methods.callHierarchy_outgoingCalls },
		{ "<leader>gs", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Document Symbols", has = methods.textDocument_documentSymbol },
		{ "<leader>gw", "<cmd>FzfLua lsp_live_workspace_symbols<cr>", desc = "Workspace Symbols", has = methods.workspace_symbol },
		{ "<leader>gc", "<cmd>FzfLua lsp_code_actions<cr>", desc = "Code Actions", has = methods.textDocument_codeAction },
		{ "<leader>gf", "<cmd>FzfLua lsp_finder<cr>", desc = "Lsp Finder", nowait = true },
		{ "<leader>gx", "<cmd>FzfLua lsp_document_diagnostics<cr>", desc = "Document Diagnostic", has = methods.textDocument_diagnostic },
		{ "<leader>gX", "<cmd>FzfLua lsp_workspace_diagnostics<cr>", desc = "Workspace Diagnostic", has = methods.workspace_diagnostic },
		{ "<c-k>", vim.lsp.buf.signature_help, mode = "i", desc = "Signature Help", has = methods.textDocument_signatureHelp },
        { "K", vim.lsp.buf.hover, desc = "Hover", has = methods.textDocument_hover },
        { "<leader>ga", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "v" }, has = methods.textDocument_codeLens },
		{ "<leader>gA", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens", has = methods.textDocument_codeLens },
		{ "<leader>gn", vim.lsp.buf.rename, desc = "Rename", has = methods.textDocument_rename },
        { "]]", function() M.words.jump(vim.v.count1) end, has = methods.textDocument_documentHighlight, desc = "Next Reference" },
        { "[[", function() M.words.jump(-vim.v.count1) end, has = methods.textDocument_documentHighlight, desc = "Prev Reference" }
,
		-- stylua: ignore end
	})

	for _, keys in pairs(keymaps) do
		local has = not keys.has or M.has_lsp_methods(buffer, keys.has)
		local cond = not (keys.cond == false or ((type(keys.cond) == "function") and not keys.cond()))
		if has and cond then
			local opts = Keys.opts(keys)
			opts.cond = nil
			opts.has = nil
			opts.silent = opts.silent ~= false
			opts.buffer = buffer
			vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
		end
	end
end

M.diagnostics_config = {
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = require("utils.icons").diagnostics.ERROR,
			[vim.diagnostic.severity.WARN] = require("utils.icons").diagnostics.WARN,
			[vim.diagnostic.severity.INFO] = require("utils.icons").diagnostics.HINT,
			[vim.diagnostic.severity.HINT] = require("utils.icons").diagnostics.INFO,
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
			local dicons = {}
			for key, value in pairs(require("utils.icons").diagnostics) do
				dicons[key:upper()] = value
			end
			return string.format(
				" %s %s [%s] ",
				dicons[vim.diagnostic.severity[d.severity]],
				d.message,
				not vim.tbl_contains({ "lazy" }, vim.o.ft) and d.source or ""
			)
		end,
	},
	float = {
		header = setmetatable({}, {
			__index = function(_, k)
				local icon, icons_hl = require("mini.icons").get("file", vim.api.nvim_buf_get_name(0))
				local arr = {
					function()
						return string.format("Diagnostics: %s  %s", icon, vim.bo.filetype)
					end,
					function()
						return icons_hl
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

---@class LspCommand: lsp.ExecuteCommandParams
---@field open? boolean
---@field handler? lsp.Handler

---@param opts LspCommand
function M.execute(opts)
	local params = { command = opts.command, arguments = opts.arguments }
	if opts.open then
		require("trouble").open({ mode = "lsp_command", params = params })
	else
		return vim.lsp.buf_request(0, "workspace/executeCommand", params, opts.handler)
	end
end

---@alias LspWord {from:{[1]:number, [2]:number}, to:{[1]:number, [2]:number}} 1-0 indexed
M.words = {}
M.words.enabled = false
M.words.ns = vim.api.nvim_create_namespace("vim_lsp_references")

---@param opts? {enabled?: boolean}
function M.words.setup(opts)
	opts = opts or {}
	if not opts.enabled then
		return
	end
	M.words.enabled = true
	local handler_doc_hl = vim.lsp.handlers["textDocument/documentHighlight"]
	vim.lsp.handlers["textDocument/documentHighlight"] = function(err, result, ctx, config)
		if not vim.api.nvim_buf_is_loaded(ctx.bufnr) then
			return
		end
		vim.lsp.buf.clear_references()
		return handler_doc_hl(err, result, ctx, config)
	end

	M.on_attach(function(client, bufnr)
		if client.supports_method(methods.textDocument_documentHighlight) then
			if not ({ M.words.get() })[2] then
				vim.api.nvim_create_autocmd({ "CursorHold", "InsertLeave" }, {
					buffer = bufnr,
					callback = vim.lsp.buf.document_highlight,
				})
				vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
					buffer = bufnr,
					callback = vim.lsp.buf.clear_references,
				})
			end
		end
	end)
end

---@return LspWord[] words, number? current
function M.words.get()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local current, ret = nil, {} ---@type number?, LspWord[]
	for _, extmark in ipairs(vim.api.nvim_buf_get_extmarks(0, M.words.ns, 0, -1, { details = true })) do
		local w = {
			from = { extmark[2] + 1, extmark[3] },
			to = { extmark[4].end_row + 1, extmark[4].end_col },
		}
		ret[#ret + 1] = w
		if cursor[1] >= w.from[1] and cursor[1] <= w.to[1] and cursor[2] >= w.from[2] and cursor[2] <= w.to[2] then
			current = #ret
		end
	end
	return ret, current
end

---@param count number
---@param cycle? boolean
function M.words.jump(count, cycle)
	local words, idx = M.words.get()
	if not idx then
		return
	end
	idx = idx + count
	if cycle then
		idx = (idx - 1) % #words + 1
	end
	local target = words[idx]
	if target then
		vim.api.nvim_win_set_cursor(0, target.from)
	end
end

return M
