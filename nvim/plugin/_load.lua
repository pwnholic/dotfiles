vim.keymap.set({ "i", "c" }, "<Tab>", function()
	require("utils.cmp").jump(1)
end)
vim.keymap.set({ "i", "c" }, "<S-Tab>", function()
	require("utils.cmp").jump(-1)
end)

require("utils.lsp").on_attach(function(client, buffer)
	require("utils.lsp").keys_on_attach(client, buffer)
end)

vim.diagnostic.config({
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
			return string.format(" %s : %s ", dicons[vim.diagnostic.severity[d.severity]], d.message)
		end,
	},
	float = {
		header = setmetatable({}, {
			__index = function(_, k)
				local icon, hl = require("mini.icons").get("file", vim.api.nvim_buf_get_name(0))
				local arr = {
					function()
						return string.format("Diagnostics: %s  %s", icon, vim.bo.filetype)
					end,
					function()
						return hl
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
})

vim.api.nvim_create_autocmd({ "LspAttach", "DiagnosticChanged" }, {
	once = true,
	desc = "Apply lsp and diagnostic settings.",
	group = vim.api.nvim_create_augroup("LspDiagnosticSetup", {}),
	callback = function()
		local lsp = require("utils.lsp")
		local register_capability = vim.lsp.handlers["client/registerCapability"]
		vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
			local ret = register_capability(err, res, ctx)
			local client = vim.lsp.get_client_by_id(ctx.client_id)
			if client then
				for buffer in pairs(client.attached_buffers) do
					require("utils.lsp").keys_on_attach(client, buffer)
				end
			end
			return ret
		end

		lsp.setup_lsp_stopidle()
		lsp.setup_commands("Lsp", lsp.subcommands.lsp, function(name)
			return vim.lsp[name] or vim.lsp.buf[name]
		end)
		lsp.setup_commands("Diagnostic", lsp.subcommands.diagnostic, vim.diagnostic)
		return true
	end,
})

vim.schedule(function()
	require("utils.tmux")()
end)
