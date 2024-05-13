local lsp_default = require("utils.lsp.default")

local register_capability = vim.lsp.handlers["client/registerCapability"]
vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
	local ret = register_capability(err, res, ctx)
	local bufnr = vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	lsp_default.lsp_keymaps(vim.lsp.get_client_by_id(ctx.client_id), bufnr)
	return ret
end

local ft_servers = {}
for langs, server_name in pairs(lsp_default.lang_servers) do
	ft_servers[langs] = server_name
end

return vim.schedule(function()
	local function setup_ft(ft)
		local servers = ft_servers[ft]
		if not servers then
			return false
		end
		if type(servers) ~= "table" then
			servers = { servers }
		end
		for _, server in ipairs(servers) do
			require("lspconfig")[server].setup(lsp_default.merge_setup(server))
		end
		ft_servers[ft] = nil
		vim.api.nvim_exec_autocmds("FileType", { pattern = ft })
		return true
	end

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		setup_ft(vim.bo[buf].ft)
	end

	for ft, _ in pairs(ft_servers) do
		vim.api.nvim_create_autocmd("FileType", {
			once = true,
			pattern = ft,
			group = vim.api.nvim_create_augroup("LspServerLazySetup", { clear = false }),
			callback = function()
				return setup_ft(ft)
			end,
		})
	end
end)
