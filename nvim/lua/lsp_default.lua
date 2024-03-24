local methods = vim.lsp.protocol.Methods
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local function lsp_custom_code_action(bufnr)
	local code_action = {
		code_action_icon = "💡",
		delay = 30, -- second
		sign = true,
		sign_priority = 40,
		virtual_text = true,
		sign_name = "MyCustomLightBulb",
		sign_group = "MyCodeAction",
		need_check_diagnostic = { ["go"] = true, ["python"] = true },
		hl_group = "CodeActionVirtulText",
	}

	local function code_action_update_virtual_text(line, actions)
		local namespace = vim.api.nvim_create_namespace(code_action.sign_group)
		pcall(vim.api.nvim_buf_clear_namespace, 0, namespace, 0, -1)
		vim.api.nvim_buf_del_extmark(bufnr, namespace, 1)
		if line then
			pcall(vim.api.nvim_buf_set_extmark, 0, namespace, line, -1, {
				virt_text = {
					{
						string.rep(" ", 3) .. code_action.code_action_icon .. string.rep(" ", 2) .. actions[1].title,
						code_action.hl_group,
					},
				},
				hl_mode = "combine",
			})
		end
	end

	local function code_action_update_sign(line)
		if vim.tbl_isempty(vim.fn.sign_getdefined(code_action.sign_name)) then
			vim.fn.sign_define(
				code_action.sign_name,
				{ text = code_action.code_action_icon, texthl = code_action.hl_group }
			)
		end
		local winid = vim.api.nvim_get_current_win()
		if code_action[winid] == nil then
			code_action[winid] = {}
		end
		-- only show code action on the current line, remove all others
		if code_action[winid].lightbulb_line and code_action[winid].lightbulb_line > 0 then
			vim.fn.sign_unplace(code_action.sign_group, { id = code_action[winid].lightbulb_line, buffer = "%" })
		end

		if line then
			local id = vim.fn.sign_place(
				line,
				code_action.sign_group,
				code_action.sign_name,
				"%",
				{ lnum = line + 1, priority = code_action.sign_priority }
			)
			code_action[winid].lightbulb_line = id
		end
	end

	local function code_action_render_virtual_text(line, diagnostics)
		return function(_, actions, _)
			if actions == nil or type(actions) ~= "table" or vim.tbl_isempty(actions) then
				-- no actions cleanup
				if code_action.virtual_text then
					code_action_update_virtual_text(nil)
				end
				if code_action.sign then
					code_action_update_sign(nil)
				end
			else
				if code_action.sign then
					if code_action.need_check_diagnostic[vim.bo.filetype] then
						if next(diagnostics) == nil then
							-- no diagnostic, no code action sign..
							code_action_update_sign(nil)
						else
							code_action_update_sign(line)
						end
					else
						code_action_update_sign(line)
					end
				end

				if not code_action.virtual_text then
					return
				end
				if code_action.need_check_diagnostic[vim.bo.filetype] and not next(diagnostics) then
					code_action_update_virtual_text()
				else
					code_action_update_virtual_text(line, actions)
				end
			end

			vim.defer_fn(function()
				if code_action.virtual_text then
					code_action_update_virtual_text(nil)
				end
				if code_action.sign then
					code_action_update_sign(nil)
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
	local callback = code_action_render_virtual_text(line, get_diagnostic)
	return vim.lsp.buf_request(bufnr, methods.textDocument_codeAction, params, callback)
end

local function lsp_custom_rename()
	local rename_origin = vim.lsp.handlers[methods.textDocument_rename]
	vim.lsp.handlers[methods.textDocument_rename] = function(err, result, ctx, config)
		local rename = rename_origin(err, result, ctx, config)
		if err or not result then
			return
		end
		local changes = result.changes or result.documentChanges or {}
		local changed_files = vim.tbl_keys(changes)
		changed_files = vim.tbl_filter(function(file)
			return #changes[file] > 0
		end, changed_files)
		changed_files = vim.tbl_map(function(file)
			return "- " .. vim.fs.basename(file)
		end, changed_files)
		local change_count = 0
		for _, change in pairs(changes) do
			change_count = change_count + #(change.edits or change)
		end
		local msg = string.format("%s instance%s", change_count, (change_count > 1 and "s" or ""))
		if #changed_files > 1 then
			msg = msg .. (" in %s files:\n"):format(#changed_files) .. table.concat(changed_files, "\n")
		end
		vim.notify_once(string.format("Renamed with LSP %s", msg), 2)
		return rename
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

	if client.supports_method(methods.textDocument_codeAction) then
		autocmd({ "CursorHold", "CursorHoldI" }, {
			group = augroup("MyCodeAction", { clear = false }),
			buffer = bufnr,
			callback = function()
				lsp_custom_code_action(bufnr)
			end,
		})
	else
		return vim.notify_once("Method [textDocument/codeAction] not supported!", 2)
	end

	if client.supports_method(methods.textDocument_documentSymbol) then
		vim.g.navic_silence = true
		require("nvim-navic").attach(client, bufnr)
	else
		return vim.notify_once("Document symbol provider not supported winbar will be disabled!", 2)
	end

	if client.supports_method(methods.textDocument_codeLens) then
		autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
			buffer = bufnr,
			group = augroup("CodeLensRefersh", { clear = true }),
			callback = vim.lsp.codelens.refresh,
		})
	else
		return vim.notify_once("Method [textDocument/codeLens] not supported!", 2)
	end

	if client.supports_method(methods.textDocument_documentHighlight) then
		local cursor_hl_group = augroup("cursor_highlights", { clear = true })
		autocmd({ "CursorHold", "InsertLeave", "BufEnter" }, {
			group = cursor_hl_group,
			desc = "Highlight references under the cursor",
			buffer = bufnr,
			callback = vim.lsp.buf.document_highlight,
		})

		autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
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

local function lsp_keymaps(client, bufnr)
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
		{ "<leader>gi", fzflsp("lsp_incoming_calls"), desc = "Incoming Calls", has = methods.callHierarchy_incomingCalls },
		{ "<leader>go", fzflsp("lsp_outgoing_calls"), desc = "Outgoing Calls", has = methods.callHierarchy_outgoingCalls },
        { "<leader>gf", fzflsp("lsp_finder"),  desc = "Lsp Finder" },
		{ "<leader>gn", vim.lsp.buf.rename, desc = "Rename Symbol", has = methods.textDocument_rename },
		{ "K", vim.lsp.buf.hover, desc = "Hover Document", has = methods.textDocument_hover },
		{ "<C-k>", vim.lsp.buf.signature_help, desc = "Signature Help", mode = { "i" }, has = methods.textDocument_signatureHelp },
		{ "<leader>gx", fzflsp("diagnostics_document"), desc = "Buffer Diagnostics", has = methods.workspace_diagnostic },
		{ "<leader>gX", fzflsp("diagnostics_workspace"), desc = "Workspace Diagnostics", has = methods.workspace_diagnostic },
		{ "<leader>ga", function() vim.lsp.buf.add_workspace_folder() vim.notify("Added to Workspace") end, desc = "Add Workspace", has = methods.workspace_workspaceFolders },
		{ "<leader>gq", function() vim.lsp.buf.remove_workspace_folder() vim.notify("Folder has been Removed") end, desc = "Remove Workspace", has = methods.workspace_workspaceFolders },
		{ "<leader>gw", function() for _, list in pairs(vim.lsp.buf.list_workspace_folders()) do vim.notify(tostring(list), 2, { title = "List Workspace" }) end end, desc = "List Workspace", has = methods.workspace_workspaceFolders },
		-- stylua: ignore end
		{ "<leader>gc", vim.lsp.buf.code_action, desc = "Code Action", has = methods.textDocument_codeAction },
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
			has = methods.textDocument_codeAction,
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

return {
	default = {
		on_attach = function(client, bufnr)
			if not vim.api.nvim_buf_is_loaded(bufnr) then
				return
			else
				lsp_custom_rename()
				lsp_custom_utils(client, bufnr)
				lsp_keymaps(client, bufnr)
			end
		end,
		capabilities = capabilities,
	},
	lsp_keymaps = lsp_keymaps,
}
