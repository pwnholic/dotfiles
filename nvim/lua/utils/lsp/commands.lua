local lsp_utils = require("utils.lsp.utils")

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
	local parsed = lsp_utils.parse_cmdline_args(fargs)
	return fn_name, parsed
end

---Convert a snake_case string to camelCase
---@param str string?
---@return string?
local function snake_to_camel(str)
	if not str then
		return nil
	end
	return (str:gsub("^%l", string.upper):gsub("_%l", string.upper):gsub("_", ""))
end

---Convert a camelCase string to snake_case
---@param str string
---@return string|nil
local function camel_to_snake(str)
	if not str then
		return nil
	end
	return (str:gsub("%u", "_%1"):gsub("^_", ""):lower())
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
local subcommand_completion = {
	bufs = function()
		return vim.api.nvim_list_bufs()
	end,
	---Get completion for LSP clients
	---@return string[]
	lsp_clients = function(arglead)
		if arglead ~= "" then
			return {}
		end
		return vim.tbl_map(function(client)
			return string.format("%d (%s)", client.id, client.name)
		end, vim.lsp.get_clients())
	end,
	---Get completion for LSP client ids
	---@return integer[]
	lsp_client_ids = function(arglead)
		if arglead ~= "" then
			return {}
		end
		return vim.tbl_map(function(client)
			return client.id
		end, vim.lsp.get_clients())
	end,
	---Get completion for LSP client names
	---@return integer[]
	lsp_client_names = function(arglead)
		if arglead ~= "" then
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
	bufs = subcommand_completion.bufs,
	lsp_clients = subcommand_completion.lsp_clients,
	lsp_client_ids = subcommand_completion.lsp_client_ids,
	lsp_client_names = subcommand_completion.lsp_client_names,
	lsp_methods = {
		"callHierarchy/incomingCalls",
		"callHierarchy/outgoingCalls",
		"textDocument/codeAction",
		"textDocument/completion",
		"textDocument/declaration",
		"textDocument/definition",
		"textDocument/diagnostic",
		"textDocument/documentHighlight",
		"textDocument/documentSymbol",
		"textDocument/formatting",
		"textDocument/hover",
		"textDocument/implementation",
		"textDocument/inlayHint",
		"textDocument/publishDiagnostics",
		"textDocument/rangeFormatting",
		"textDocument/references",
		"textDocument/rename",
		"textDocument/semanticTokens/full",
		"textDocument/semanticTokens/full/delta",
		"textDocument/signatureHelp",
		"textDocument/typeDefinition",
		"window/logMessage",
		"window/showMessage",
		"window/showDocument",
		"window/showMessageRequest",
		"workspace/applyEdit",
		"workspace/configuration",
		"workspace/executeCommand",
		"workspace/inlayHint/refresh",
		"workspace/symbol",
		"workspace/workspaceFolders",
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

local subcommands = {
	---LSP subcommands
	---@type table<string, subcommand_info_t>
	lsp = {
		references = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.context, args.options
			end,
			opts = { "context", "options.on_list" },
		},
		rename = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.new_name or args[1], args.options
			end,
			opts = { "new_name", "options.filter", "options.name" },
		},
		workspace_symbol = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.query, args.options
			end,
			opts = { "query", "options.on_list" },
		},
		format = {
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
			arg_handler = subcommand_arg_handler.item,
			completion = function(_, _, _)
				return vim.tbl_map(function(path)
					local short = vim.fn.fnamemodify(path, ":p:~:.")
					return short ~= "" and short or "./"
				end, vim.lsp.buf.list_workspace_folders())
			end,
		},
		execute_command = { arg_handler = subcommand_arg_handler.item },
		type_definition = { opts = { "reuse_win", ["on_list"] = subcommand_opt_vals.bool } },
		declaration = { opts = { "reuse_win", ["on_list"] = subcommand_opt_vals.bool } },
		definition = { opts = { "reuse_win", ["on_list"] = subcommand_opt_vals.bool } },
		document_symbol = { opts = { ["on_list"] = subcommand_opt_vals.bool } },
		implementation = { opts = { ["on_list"] = subcommand_opt_vals.bool } },
		hover = {},
		document_highlight = {},
		clear_references = {},
		list_workspace_folders = {
			fn_override = function()
				vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end,
		},
		incoming_calls = {},
		outgoing_calls = {},
		signature_help = {},
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
			opts = { ["bufnr"] = subcommand_opt_vals.bufs, "namespace" },
		},
		enable = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.bufnr, args.namespace
			end,
			opts = { ["bufnr"] = subcommand_opt_vals.bufs, "namespace" },
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
				vim.notify(vim.inspect(vim.diagnostic.get(...)))
			end,
		},
		get_namespace = {
			arg_handler = subcommand_arg_handler.item,
			opts = { "namespace" },
			fn_override = function(...)
				vim.notify(vim.inspect(vim.diagnostic.get_namespace(...)))
			end,
		},
		get_namespaces = {
			fn_override = function()
				vim.notify(vim.inspect(vim.diagnostic.get_namespaces()))
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
				vim.notify(vim.inspect(vim.diagnostic.get_next(...)))
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
				vim.notify(vim.inspect(vim.diagnostic.get_next_pos(...)))
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
				vim.notify(vim.inspect(vim.diagnostic.get_prev(...)))
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
				vim.notify(vim.inspect(vim.diagnostic.get_prev_pos(...)))
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
			opts = { "namespace", ["bufnr"] = subcommand_opt_vals.bufs },
		},
		is_disabled = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.bufnr, args.namespace
			end,
			opts = { "namespace", ["bufnr"] = subcommand_opt_vals.bufs },
			fn_override = function(...)
				vim.notify(vim.inspect(vim.diagnostic.is_disabled(...)))
			end,
		},
		match = {
			---@param args lsp_command_parsed_arg_t
			arg_handler = function(args)
				return args.str, args.pat, args.groups, args.severity_map, args.defaults
			end,
			opts = { "str", "pat", "groups", "severity_map", "defaults" },
			fn_override = function(...)
				vim.notify(vim.inspect(vim.diagnostic.match(...)))
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
			opts = { "namespace", ["bufnr"] = subcommand_opt_vals.bufs },
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
			opts = { "namespace", "winnr", "open", "title", ["severity"] = subcommand_opt_vals.severity },
		},
		setqflist = {
			opts = { "namespace", "open", "title", ["severity"] = subcommand_opt_vals.severity },
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
		local subcommand = camel_to_snake(cmdline:match("^%s*" .. meta .. "(%w+)"))
			or cmdline:match("^%s*" .. meta .. "%s+(%S+)")
		if not subcommand_info_list[subcommand] then
			return {}
		end
		-- Use subcommand's completion function if it exists
		if subcommand_info_list[subcommand].completion then
			return subcommand_info_list[subcommand].completion(arglead, cmdline, cursorpos)
		end
		-- Complete with subcommand's options or params
		local subcommand_info = subcommand_info_list[subcommand]
		if subcommand_info then
			return lsp_utils.complete(subcommand_info.params, subcommand_info.opts)(arglead, cmdline, cursorpos)
		end
		return {}
	end
end

---Setup commands
---@param meta string meta command name
---@param subcommand_info_list table<string, subcommand_info_t> subcommands information
---@param fn_scope table|fun(name: string): function scope of corresponding functions for subcommands
---@return nil
local function setup_commands(meta, subcommand_info_list, fn_scope)
	-- metacommand -> MetaCommand abbreviation
	require("utils.keys").command_abbrev(meta:lower(), meta)
	-- Format: MetaCommand sub_command opts ...
	vim.api.nvim_create_user_command(meta, command_meta(subcommand_info_list, fn_scope), {
		bang = true,
		range = true,
		nargs = "*",
		complete = command_complete(meta, subcommand_info_list),
	})
	-- Format: MetaCommandSubcommand opts ...
	for subcommand, _ in pairs(subcommand_info_list) do
		vim.api.nvim_create_user_command(
			meta .. snake_to_camel(subcommand),
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
local function setup_lsp_stopidle()
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
						lsp_utils.lsp_soft_stop(client)
					end
				end
			end, 60000)
		end,
	})
end

---Set up LSP and diagnostic
---@return nil
local function setup()
	setup_lsp_stopidle()
	setup_commands("Lsp", subcommands.lsp, function(name)
		return vim.lsp[name] or vim.lsp.buf[name]
	end)
	setup_commands("Diagnostic", subcommands.diagnostic, vim.diagnostic)
end

return { setup = setup }
