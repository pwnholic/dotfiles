local M = {}

local function lsp_code_action(bufnr)
	local code_action = {
		lb_icon = "💡",
		delay = 30, -- second
		sign = true,
		sign_priority = 40,
		virtual_text = true,
		sign_name = "MyCustomLightBulb",
		sign_group = "MyCodeAction",
		need_check_diagnostic = { ["go"] = true, ["python"] = true },
		hl_group = "CodeActionVirtulText",
	}

	local function update_virtual_text(line, actions)
		local namespace = vim.api.nvim_create_namespace(code_action.sign_group)
		pcall(vim.api.nvim_buf_clear_namespace, 0, namespace, 0, -1)
		vim.api.nvim_buf_del_extmark(bufnr, namespace, 1)
		if line then
			pcall(vim.api.nvim_buf_set_extmark, 0, namespace, line, -1, {
				virt_text = {
					{
						string.rep(" ", 3) .. code_action.lb_icon .. string.rep(" ", 2) .. actions[1].title,
						code_action.hl_group,
					},
				},
				hl_mode = "combine",
			})
		end
	end

	local function update_sign(line)
		if vim.tbl_isempty(vim.fn.sign_getdefined(code_action.sign_name)) then
			vim.fn.sign_define(code_action.sign_name, { text = code_action.lb_icon, texthl = code_action.hl_group })
		end
		local winid = vim.api.nvim_get_current_win()
		if code_action[winid] == nil then
			code_action[winid] = {}
		end
		-- only show code action on the current line, remove all others
		if code_action[winid].lightbulb_line and code_action[winid].lightbulb_line > 0 then
			vim.fn.sign_unplace(code_action.sign_group, { id = code_action[winid].lightbulb_line, buffer = "%" })
		end

		-- if line then
		-- 	local id = vim.fn.sign_place(
		-- 		line,
		-- 		code_action.sign_group,
		-- 		code_action.sign_name,
		-- 		"%",
		-- 		{ lnum = line + 1, priority = code_action.sign_priority }
		-- 	)
		-- 	code_action[winid].lightbulb_line = id
		-- end
	end

	local function render_virtual_text(line, diagnostics)
		return function(_, actions, _)
			if actions == nil or type(actions) ~= "table" or vim.tbl_isempty(actions) then
				-- no actions cleanup
				if code_action.virtual_text then
					update_virtual_text(nil)
				end
				if code_action.sign then
					update_sign(nil)
				end
			else
				if code_action.sign then
					if code_action.need_check_diagnostic[vim.bo.filetype] then
						if next(diagnostics) == nil then
							-- no diagnostic, no code action sign..
							update_sign(nil)
						else
							update_sign(line)
						end
					else
						update_sign(line)
					end
				end

				if not code_action.virtual_text then
					return
				end
				if code_action.need_check_diagnostic[vim.bo.filetype] and not next(diagnostics) then
					update_virtual_text()
				else
					update_virtual_text(line, actions)
				end
			end

			vim.defer_fn(function()
				if code_action.virtual_text then
					update_virtual_text(nil)
				end
				if code_action.sign then
					update_sign(nil)
				end
			end, code_action.delay * 1000)
		end
	end

	local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
	local get_diagnostic = vim.diagnostic.get(bufnr, { lnum = lnum })
	local win_id = vim.api.nvim_get_current_win()

	code_action[win_id] = code_action[win_id] or {}
	code_action[win_id].lightbulb_line = code_action[win_id].lightbulb_line or 0

	local params = vim.lsp.util.make_range_params()
	params.context = { diagnostics = get_diagnostic }
	local line = params.range.start.line
	local callback = render_virtual_text(line, get_diagnostic)
	return vim.lsp.buf_request(bufnr, "textDocument/codeAction", params, callback)
end

local function fzflsp(builtin, opts)
	local params = { builtin = builtin, opts = opts }
	return function()
		builtin = params.builtin
		opts = params.opts
		opts = vim.tbl_deep_extend("force", {
			fzf_opts = {
				["--info"] = "right",
				["--no-preview"] = true,
				["--preview-window"] = "hidden",
				["--ansi"] = true,
			},
		}, opts or {})
		require("fzf-lua")[builtin](opts)
	end
end

function M.lsp_keymaps(client, bufnr)
	local handler_keys = require("lazy.core.handler.keys")
	if not handler_keys.resolve then
		return {}
	end

	local skip = { mode = true, id = true, ft = true, rhs = true, lhs = true }
	local keymaps = handler_keys.resolve({
        -- stylua: ignore start
		{ "gd", "<cmd>Trouble lsp_definitions<cr>", desc = "Definition", has = "textDocument/definition" },
		{ "gD", "<cmd>Trouble lsp_type_definitions<cr>", desc = "Type Definitions", has = "textDocument/typeDefinition" },
		{ "<leader>gr", "<cmd>Trouble lsp_references<cr>", desc = "References", has = "textDocument/references" },
		{ "<leader>gy", "<cmd>Trouble lsp_implementations<cr>", desc = "Implementation", has = "textDocument/implementation" },
		{ "<leader>gl", vim.lsp.codelens.run, desc = "Run Codelens", has = "textDocument/codeLens" },
		{ "<leader>gd", fzflsp("lsp_declarations"), desc = "Declaration", has = "textDocument/declaration" },
		{ "<leader>gs", fzflsp("lsp_document_symbols"), desc = "Document Symbols", has = "textDocument/documentSymbol" },
		{ "<leader>gS", fzflsp("lsp_live_workspace_symbols"), desc = "Workspace Symbols", has = "workspace/symbol" },
        { "<leader>gi", fzflsp("lsp_incoming_calls"), desc = "Incoming Calls", has ="callHierarchy/incomingCalls" },
		{ "<leader>go", fzflsp("lsp_outgoing_calls"), desc = "Outgoing Calls", has = "callHierarchy/outgoingCalls" },
		{ "<leader>gf", fzflsp("lsp_finder"), desc = "Lsp Finder" },
		{ "K", vim.lsp.buf.hover, desc = "Hover Document", has ="textDocument/hover"},
		{ "<C-k>", vim.lsp.buf.signature_help, desc = "Signature Help", mode = { "i" }, has = "textDocument/signatureHelp" },
		{ "<leader>gx", fzflsp("diagnostics_document"), desc = "Buffer Diagnostics", has = "workspace/diagnostic"},
		{ "<leader>gX", fzflsp("diagnostics_workspace"), desc = "Workspace Diagnostics", has =  "workspace/diagnostic" },
		{ "<leader>ga", function() vim.lsp.buf.add_workspace_folder() vim.notify("Added to Workspace") end, desc = "Add Workspace", has ="workspace/workspaceFolders"},
		{ "<leader>gq", function() vim.lsp.buf.remove_workspace_folder() vim.notify("Folder has been Removed") end, desc = "Remove Workspace", has ="workspace/workspaceFolders" },
		{ "<leader>gc", vim.lsp.buf.code_action, desc = "Code Action", has = "textDocument/codeAction" },
		-- stylua: ignore end
		{
			"<leader>gn",
			vim.lsp.buf.rename,
			desc = "Rename Symbol",
			expr = true,
			has = "textDocument/rename",
		},
		{
			"<leader>gw",
			function()
				for _, list in pairs(vim.lsp.buf.list_workspace_folders()) do
					vim.notify(tostring(list), 2, { title = "List Workspace" })
				end
			end,
			desc = "List Workspace",
			has = "workspace/workspaceFolders",
		},
		{
			"<leader>gC",
			function()
				vim.lsp.buf.code_action({
					context = { diagnostics = vim.lsp.diagnostic.get_line_diagnostics() },
					range = {
						start = vim.api.nvim_buf_get_mark(bufnr, "<"),
						["end"] = vim.api.nvim_buf_get_mark(bufnr, ">"),
					},
				})
			end,
			desc = "Range Code Action",
			has = "textDocument/codeAction",
			mode = { "v" },
		},
	})
	for _, keys in pairs(keymaps) do
		if not keys.has or client.supports_method(keys.has) then
			local opts = {}
			for k, v in pairs(keys) do
				if type(k) ~= "number" and not skip[k] then
					opts[k] = v
				end
			end
			opts.has = nil
			opts.silent = opts.silent ~= false
			opts.buffer = bufnr
			vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
		end
	end
end

M.capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), {
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
})

function M.on_attach(client, bufnr)
	if not vim.api.nvim_buf_is_loaded(bufnr) then
		return
	else
		M.lsp_keymaps(client, bufnr)

		if client.supports_method("textDocument/codeAction") then
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				group = vim.api.nvim_create_augroup("MyCodeAction", { clear = false }),
				buffer = bufnr,
				callback = function()
					lsp_code_action(bufnr)
				end,
			})
		else
			return vim.notify_once("Method [textDocument/codeAction] not supported!", 2)
		end

		if client.supports_method("textDocument/documentSymbol") then
			vim.g.navic_silence = true
			require("nvim-navic").attach(client, bufnr)
		else
			return vim.notify_once("Document symbol provider not supported winbar will be disabled!", 2)
		end

		local enabled = true
		if client.supports_method("textDocument/inlayHint") then
			vim.keymap.set("n", "<leader>uh", function()
				enabled = not enabled
				if enabled then
					vim.notify("Disabled Inlay Hint", vim.diagnostic.severity.WARN, { title = "Inlay Hint" })
					vim.lsp.inlay_hint.enable(false)
				else
					vim.notify("Enabled Inlay Hint", vim.diagnostic.severity.WARN, { title = "Inlay Hint" })
					vim.lsp.inlay_hint.enable(true)
				end
			end, { desc = "Toggle inlay hint" })
		else
			return vim.notify_once("Method [textDocument/inlayHint] not supported!", 2)
		end
	end
end

M.server_config = {
	solidity_ls_nomicfoundation = { name = "solidity_ls" },
	lua_ls = {
		settings = {
			Lua = {
				workspace = {
					library = { vim.env.VIMRUNTIME .. "/lua", vim.uv.cwd() },
					checkThirdParty = false,
					maxPreload = 1000,
					preloadFileSize = 40000,
				},
				runtime = {
					version = "LuaJIT",
					path = vim.tbl_extend("force", vim.split(package.path, ";", {}), { "lua/?.lua", "lua/?/init.lua" }),
				},
				completion = { callsnippet = "replace" },
				diagnostics = { enable = true, globals = { "vim", "describe" } },
				hint = { enable = true },
				telemetry = { enable = false },
				format = { enable = false },
			},
		},
	},
}

M.lang_servers = {
	lua = "lua_ls",
	c = "clangd",
	cpp = "clangd",
	markdown = "marksman",
	rust = "rust-analyzer",
	solidity = "solidity_ls_nomicfoundation",
	php = "phpactor",
	python = "pyright",
}

function M.merge_setup(opts)
	local config = M.server_config[opts]
	if not config then
		config = vim.deepcopy({ on_attach = M.on_attach, capabilities = M.capabilities })
	else
		config = vim.tbl_extend("force", { on_attach = M.on_attach, capabilities = M.capabilities }, config)
	end
	return config
end

return M
