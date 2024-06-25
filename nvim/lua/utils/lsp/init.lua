local M = {}

local utils = require("utils")

---@type lsp_client_config_t
---@diagnostic disable-next-line: missing-fields
M.default_config = { root_patterns = utils.root.root_patterns }

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
	local root_dir = utils.root.proj_dir(
		bufname,
		vim.list_extend(config.root_patterns or {}, M.default_config.root_patterns or {})
	) or vim.fs.dirname(bufname)

	local default_capabilities = vim.tbl_deep_extend(
		"force",
		vim.lsp.protocol.make_client_capabilities(),
		require("cmp_nvim_lsp").default_capabilities(),
		{
			textDocument = {
				foldingRange = { dynamicRegistration = false, lineFoldingOnly = true },
				semanticTokens = { augmentsSyntaxTokens = false },
				formatting = { dynamicRegistration = false },
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
						insertTextModeSupport = { valueSet = { 1, 2 } },
						labelDetailsSupport = true,
					},
					contextSupport = true,
					insertTextMode = 1,
					completionList = {
						itemDefaults = { "commitCharacters", "editRange", "insertTextFormat", "insertTextMode", "data" },
					},
				},
			},
			general = { positionEncodings = { "utf-8" } },
			experimental = {
				hoverActions = true,
				hoverRange = true,
				serverStatusNotification = true,
				snippetTextEdit = true,
				codeActionGroup = true,
				ssr = true,
			},
		}
	)

	return vim.lsp.start(
		---@diagnostic disable-next-line: param-type-mismatch
		vim.tbl_deep_extend("keep", config or {}, {
			name = name,
			root_dir = root_dir,
			capabilities = default_capabilities,
		}, M.default_config),
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
function M.lsp_restart(client_or_id)
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

---@param opts? lsp.Client.filter
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

---@param on_attach fun(client:vim.lsp.Client, buffer)
---@param name? string
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

M.action = setmetatable({}, {
	__index = function(_, action)
		return function()
			vim.lsp.buf.code_action({
				apply = true,
				context = {
					only = { action },
					diagnostics = {},
				},
			})
		end
	end,
})

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

return setmetatable(M, {
	__index = function(self, key)
		self[key] = require("utils.lsp." .. key)
		return self[key]
	end,
})
