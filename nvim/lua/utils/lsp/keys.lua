local M = {}
local handler_keys = require("lazy.core.handler.keys")
local fzf = require("fzf-lua")

function M.lsp_keymaps(client, bufnr)
	if not handler_keys.resolve then
		return {}
	end

	local skip = { mode = true, id = true, ft = true, rhs = true, lhs = true }
	local keymaps = handler_keys.resolve({
		{ "gd", fzf.lsp_definitions, desc = "Definition", has = "textDocument/definition" },
		{ "<leader>gl", vim.lsp.codelens.run, desc = "Run Codelens", has = "textDocument/codeLens" },
		{ "<leader>gd", fzf.lsp_declarations, desc = "Declaration", has = "textDocument/declaration" },
		{ "<leader>gs", fzf.lsp_document_symbols, desc = "Document Symbols", has = "textDocument/documentSymbol" },
		{ "<leader>gS", fzf.lsp_live_workspace_symbols, desc = "Workspace Symbols", has = "workspace/symbol" },
		{ "<leader>gi", fzf.lsp_incoming_calls, desc = "Incoming Calls", has = "callHierarchy/incomingCalls" },
		{ "<leader>go", fzf.lsp_outgoing_calls, desc = "Outgoing Calls", has = "callHierarchy/outgoingCalls" },
		{ "<leader>gf", fzf.lsp_finder, desc = "Lsp Finder" },
		{ "K", vim.lsp.buf.hover, desc = "Hover Document", has = "textDocument/hover" },
		{ "<leader>gx", fzf.diagnostics_document, desc = "Buffer Diagnostics", has = "workspace/diagnostic" },
		{ "<leader>gX", fzf.diagnostics_workspace, desc = "Workspace Diagnostics", has = "workspace/diagnostic" },
		{ "<leader>gr", "<cmd>Trouble lsp_references<cr>", desc = "References", has = "textDocument/references" },
		{ "<leader>gc", vim.lsp.buf.code_action, desc = "Code Action", has = "textDocument/codeAction" },
		{
			"gD",
			"<cmd>Trouble lsp_type_definitions<cr>",
			desc = "Type Definitions",
			has = "textDocument/typeDefinition",
		},
		{
			"<leader>gy",
			"<cmd>Trouble lsp_implementations<cr>",
			desc = "Implementation",
			has = "textDocument/implementation",
		},
		{
			"<C-k>",
			vim.lsp.buf.signature_help,
			desc = "Signature Help",
			mode = { "i" },
			has = "textDocument/signatureHelp",
		},
		{
			"<leader>ga",
			function()
				vim.lsp.buf.add_workspace_folder()
				vim.notify("Added to Workspace")
			end,
			desc = "Add Workspace",
			has = "workspace/workspaceFolders",
		},
		{
			"<leader>gq",
			function()
				vim.lsp.buf.remove_workspace_folder()
				vim.notify("Folder has been Removed")
			end,
			desc = "Remove Workspace",
			has = "workspace/workspaceFolders",
		},
		{
			"<leader>gn",
			vim.lsp.buf.rename,
			desc = "Rename Symbol",
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

return setmetatable(M, {
	__call = function(m, ...)
		return m.lsp_keymaps(...)
	end,
})
