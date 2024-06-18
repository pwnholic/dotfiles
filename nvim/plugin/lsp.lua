local utils = require("utils")

utils.lsp.on_attach(function(client, buffer)
	utils.lsp.keys(client, buffer)
end)

local register_capability = vim.lsp.handlers["client/registerCapability"]
vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
	local ret = register_capability(err, res, ctx)
	local client = vim.lsp.get_client_by_id(ctx.client_id)
	if client then
		for buffer in pairs(client.attached_buffers) do
			utils.lsp.keys(client, buffer)
		end
	end
	return ret
end

vim.api.nvim_create_autocmd({ "LspAttach", "DiagnosticChanged" }, {
	once = true,
	desc = "Apply lsp and diagnostic settings.",
	group = vim.api.nvim_create_augroup("LspDiagnosticSetup", {}),
	callback = function()
		utils.lsp.commands.setup_commands("Lsp", utils.lsp.commands.subcommands.lsp, function(name)
			return vim.lsp[name] or vim.lsp.buf[name]
		end)
		utils.lsp.commands.setup_commands("Diagnostic", utils.lsp.commands.subcommands.diagnostic, vim.diagnostic)

		return true
	end,
})

local lsp_autostop_pending
---Automatically stop LSP servers that no longer attaches to any buffers
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

vim.api.nvim_create_user_command("RootPath", function()
	utils.root.info()
end, { desc = "Roots for the current buffer" })

-- FIX: doesn't properly clear cache in neo-tree `set_root` (which should happen presumably on `DirChanged`),
-- probably because the event is triggered in the neo-tree buffer, therefore add `BufEnter`
-- Maybe this is too frequent on `BufEnter` and something else should be done instead??
vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost", "DirChanged", "BufEnter" }, {
	group = vim.api.nvim_create_augroup("root_cache", { clear = true }),
	callback = function(event)
		utils.root.cache[event.buf] = nil
	end,
})
