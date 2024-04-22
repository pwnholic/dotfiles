local diagIcons = require("utils.icons").diagnostics
for name, icon in pairs(diagIcons) do
	name = "DiagnosticSign" .. name
	vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
end

vim.diagnostic.config({
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = diagIcons.Error,
			[vim.diagnostic.severity.WARN] = diagIcons.Warn,
			[vim.diagnostic.severity.INFO] = diagIcons.Hint,
			[vim.diagnostic.severity.HINT] = diagIcons.Info,
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
			local icons = {}
			for key, value in pairs(diagIcons) do
				icons[key:upper()] = value
			end
			return string.format(" %s : %s ", icons[vim.diagnostic.severity[d.severity]], d.message)
		end,
	},
	float = {
		header = setmetatable({}, {
			__index = function(_, k)
				local icon, hl = require("nvim-web-devicons").get_icon_by_filetype(vim.bo.filetype)
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

local hide = vim.diagnostic.handlers.virtual_text.hide
local show = vim.diagnostic.handlers.virtual_text.show
vim.diagnostic.handlers.virtual_text = {
	show = function(ns, bufnr, diagnostics, opts)
		table.sort(diagnostics, function(diag1, diag2)
			return diag1.severity > diag2.severity
		end)
		return show(ns, bufnr, diagnostics, opts)
	end,
	hide = hide,
}
