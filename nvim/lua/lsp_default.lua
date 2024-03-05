local methods = vim.lsp.protocol.Methods

local function lsp_custom_lightbulb(client, bufnr)
	local lb_name = "my_custom_lightbulb"
	local lb_namespace = vim.api.nvim_create_namespace(lb_name)
	local lb_icon = "💡"
	local lb_group = vim.api.nvim_create_augroup(lb_name, {})

	local timer = vim.uv.new_timer()
	assert(timer, "Timer was not initialized")

	local updated_bufnr = nil
	local function update_extmark(_bufnr, line)
		if not _bufnr or not vim.api.nvim_buf_is_valid(_bufnr) then
			return
		end
		vim.api.nvim_buf_clear_namespace(_bufnr, lb_namespace, 0, -1)
		if not line or vim.startswith(vim.api.nvim_get_mode().mode, "i") then
			return
		end
		-- Swallow errors.
		pcall(vim.api.nvim_buf_set_extmark, _bufnr, lb_namespace, line, -1, {
			virt_text = { { " " .. lb_icon, "DiagnosticSignHint" } },
			hl_mode = "combine",
		})
		updated_bufnr = _bufnr
	end

	--- Queries the LSP servers for code actions and updates the lightbulb
	--- accordingly.
	local function render(_bufnr)
		local cursor = vim.api.nvim_win_get_cursor(0)[1] - 1
		local diagnostics = vim.lsp.diagnostic.get_line_diagnostics(_bufnr, cursor)
		local params = vim.lsp.util.make_range_params()

		params.context = { diagnostics = diagnostics, triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Automatic }
		vim.lsp.buf_request(_bufnr, methods.textDocument_codeAction, params, function(_, res, _)
			if vim.api.nvim_get_current_buf() ~= _bufnr then
				return
			end
			update_extmark(_bufnr, (res and #res > 0 and cursor) or nil)
		end)
	end

	local function update(_bufnr)
		timer:stop()
		update_extmark(updated_bufnr)
		timer:start(100, 0, function()
			timer:stop()
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(_bufnr) and vim.api.nvim_get_current_buf() == _bufnr then
					render(_bufnr)
				end
			end)
		end)
	end

	if client.supports_method(methods.textDocument_codeAction) then
		local buf_group_name = lb_name .. tostring(bufnr)
		local lb_buf_group = vim.api.nvim_create_augroup(buf_group_name, { clear = true })

		if pcall(vim.api.nvim_get_autocmds, { group = buf_group_name, buffer = bufnr }) then
			return
		end

		vim.api.nvim_create_autocmd("CursorMoved", {
			group = lb_buf_group,
			desc = "Update lightbulb when moving the cursor in normal/visual mode",
			buffer = bufnr,
			callback = function()
				update(bufnr)
			end,
		})

		vim.api.nvim_create_autocmd({ "InsertEnter", "BufLeave" }, {
			group = lb_buf_group,
			desc = "Update lightbulb when entering insert mode or leaving the buffer",
			buffer = bufnr,
			callback = function()
				update_extmark(bufnr, nil)
			end,
		})
	end

	vim.api.nvim_create_autocmd("LspDetach", {
		group = lb_group,
		desc = "Detach code action lightbulb",
		callback = function(args)
			pcall(vim.api.nvim_del_augroup_by_name, lb_name .. tostring(args.buf))
		end,
	})
end

local function lsp_custom_rename()
	local renameHandler = vim.lsp.handlers[methods.textDocument_rename]
	vim.lsp.handlers[methods.textDocument_rename] = function(err, result, ctx, config)
		renameHandler(err, result, ctx, config)
		if err or not result then
			return
		end
		local changes = result.changes or result.documentChanges or {}
		local changedFiles = vim.tbl_keys(changes)
		changedFiles = vim.tbl_filter(function(file)
			return #changes[file] > 0
		end, changedFiles)
		changedFiles = vim.tbl_map(function(file)
			return "- " .. vim.fs.basename(file)
		end, changedFiles)
		local changeCount = 0
		for _, change in pairs(changes) do
			changeCount = changeCount + #(change.edits or change)
		end
		local msg = string.format("%s instance%s", changeCount, (changeCount > 1 and "s" or ""))
		if #changedFiles > 1 then
			msg = msg .. (" in %s files:\n"):format(#changedFiles) .. table.concat(changedFiles, "\n")
		end
		return vim.notify_once(string.format("Renamed with LSP %s", msg), 2)
	end
end

local function lsp_custom_utils(client, bufnr)
	local enabled = true
	if client.supports_method(methods.textDocument_inlayHint) then
		vim.keymap.set("n", "<leader>uh", function()
			enabled = not enabled
			if enabled then
				vim.notify("Disabled Inlay Hint", vim.diagnostic.severity.WARN, { title = "Inlay Hint" })
				vim.lsp.inlay_hint.enable(bufnr, false)
			else
				vim.notify("Enabled Inlay Hint", vim.diagnostic.severity.WARN, { title = "Inlay Hint" })
				vim.lsp.inlay_hint.enable(bufnr, true)
			end
		end, { desc = "Toggle inlay hint" })
	else
		return vim.notify_once("Method [textDocument/inlayHint] not supported!", 2)
	end

	if client.server_capabilities.documentSymbolProvider then
		vim.g.navic_silence = true
		require("nvim-navic").attach(client, bufnr)
	else
		return vim.notify_once("Document symbol provider not supported winbar will be disabled!", 2)
	end

	if client.supports_method(methods.textDocument_codeLens) then
		vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
			buffer = bufnr,
			group = vim.api.nvim_create_augroup("CodeLensRefersh", { clear = true }),
			callback = vim.lsp.codelens.refresh,
		})
	else
		return vim.notify_once("Method [textDocument/codeLens] not supported!", 2)
	end

	if client.supports_method(methods.textDocument_documentHighlight) then
		local cursor_hl_group = vim.api.nvim_create_augroup("cursor_highlights", { clear = true })
		vim.api.nvim_create_autocmd({ "CursorHold", "InsertLeave", "BufEnter" }, {
			group = cursor_hl_group,
			desc = "Highlight references under the cursor",
			buffer = bufnr,
			callback = vim.lsp.buf.document_highlight,
		})

		vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
			group = cursor_hl_group,
			desc = "Clear highlight references",
			buffer = bufnr,
			callback = vim.lsp.buf.clear_references,
		})
	else
		vim.notify_once("Method [textDocument/documentHighlight] not supported!", 2)
		return
	end
end

local capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), {
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
			completionList = { itemDefaults = { "commitCharacters", "editRange", "insertTextFormat", "insertTextMode", "data" } },
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
		commands = {
			commands = {
				"rust-analyzer.runSingle",
				"rust-analyzer.debugSingle",
				"rust-analyzer.showReferences",
				"rust-analyzer.gotoLocation",
				"editor.action.triggerParameterHints",
			},
		},
	},
})

local function fzflsp(builtin, opts)
	local params = { builtin = builtin, opts = opts }
	return function()
		builtin = params.builtin
		opts = params.opts
		opts = vim.tbl_deep_extend("force", {
			fzf_opts = { ["--info"] = "right", ["--no-preview"] = true, ["--preview-window"] = "hidden", ["--ansi"] = true },
		}, opts or {})
		require("fzf-lua")[builtin](opts)
	end
end

local function lsp_keymaps(client, buffer)
	local handler_keys = require("lazy.core.handler.keys")
	if not handler_keys.resolve then
		return {}
	end

	local skip = { mode = true, id = true, ft = true, rhs = true, lhs = true }
	local keymaps = handler_keys.resolve({
        -- stylua: ignore start
		{ "gd", "<cmd>Trouble lsp_definitions<cr>", desc = "Definition", has = methods.textDocument_definition },
		{ "gD", "<cmd>Trouble lsp_type_definitions<cr>", desc = "Type Definitions", has = methods.textDocument_typeDefinition },
		{ "<leader>gr", "<cmd>Trouble lsp_references<cr>", desc = "References", has = methods.textDocument_references },
		{ "<leader>gy", "<cmd>Trouble lsp_implementations<cr>", desc = "Implementation", has = methods.textDocument_implementation },
		{ "<leader>gl", vim.lsp.codelens.run, desc = "Run Codelens", has = methods.textDocument_codeLens },
		{ "<leader>gd", fzflsp("lsp_declarations"), desc = "Declaration", has = methods.textDocument_declaration },
		{ "<leader>gs", fzflsp("lsp_document_symbols"), desc = "Document Symbols", has = methods.textDocument_documentSymbol },
		{ "<leader>gS", fzflsp("lsp_live_workspace_symbols"), desc = "Workspace Symbols", has = methods.workspace_symbol },
		{ "<leader>gc", vim.lsp.buf.code_action, desc = "Code Action", has = methods.textDocument_codeAction },
		{ "<leader>gi", fzflsp("lsp_incoming_calls"), desc = "Incoming Calls", has = methods.callHierarchy_incomingCalls },
		{ "<leader>go", fzflsp("lsp_outgoing_calls"), desc = "Outgoing Calls", has = methods.callHierarchy_outgoingCalls },
		{ "<leader>gn", vim.lsp.buf.rename, desc = "Rename Symbol", has = methods.textDocument_rename },
		{ "K", vim.lsp.buf.hover, desc = "Hover Document", has = methods.textDocument_hover },
		{ "<C-k>", vim.lsp.buf.signature_help, desc = "Signature Help", mode = { "i" }, has = methods.textDocument_signatureHelp },
		{ "<leader>gx", fzflsp("diagnostics_document"), desc = "Buffer Diagnostics", has = methods.workspace_diagnostic },
		{ "<leader>gX", fzflsp("diagnostics_workspace"), desc = "Workspace Diagnostics", has = methods.workspace_diagnostic },
		{ "<leader>ga", function() vim.lsp.buf.add_workspace_folder() vim.notify("Added to Workspace") end, desc = "Add Workspace", has = methods.workspace_workspaceFolders },
		{ "<leader>gq", function() vim.lsp.buf.remove_workspace_folder() vim.notify("Folder has been Removed") end, desc = "Remove Workspace", has = methods.workspace_workspaceFolders },
		{ "<leader>gw", function() for _, list in pairs(vim.lsp.buf.list_workspace_folders()) do vim.notify(tostring(list), 2, { title = "List Workspace" }) end end, desc = "List Workspace", has = methods.workspace_workspaceFolders },
		-- stylua: ignore end
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
			opts.buffer = buffer
			vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
		end
	end
end

return {
	default = {
		on_attach = function(client, bufnr)
			if vim.b.bigfile or vim.b.midfile then
				return vim.lsp.buf_detach_client(bufnr, client.id)
			else
				lsp_custom_rename()
				lsp_custom_utils(client, bufnr)
				lsp_custom_lightbulb(client, bufnr)
				lsp_keymaps(client, bufnr)
			end
		end,
		capabilities = capabilities,
	},
	lsp_keymaps = lsp_keymaps,
}
