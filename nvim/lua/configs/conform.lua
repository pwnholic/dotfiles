local conform = require("conform")
local opts = {
	formatters_by_ft = {
		lua = { "stylua" },
		go = { "goimports", "gofmt" },
		javascript = { "prettier" },
		javascriptreact = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		vue = { "prettier" },
		css = { "prettier" },
		scss = { "prettier" },
		less = { "prettier" },
		html = { "prettier" },
		json = { "prettier" },
		jsonc = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
		["markdown.mdx"] = { "prettier" },
		graphql = { "prettier" },
		handlebars = { "prettier" },
		python = function(bufnr)
			if require("conform").get_formatter_info("ruff_format", bufnr).available then
				return { "ruff_format" }
			else
				return { "isort", "black" }
			end
		end,
		["_"] = { "trim_whitespace", "trim_newlines" },
	},
	format_on_save = function()
		if vim.b.bigfile then
			return
		end
		return { lsp_fallback = true, timeout_ms = 5000 }
	end,
	log_level = vim.log.levels.ERROR,
	notify_on_error = true,
}

local enabled = true
vim.keymap.set("n", "<leader>uf", function()
	enabled = not enabled
	if enabled then
		vim.notify("Enabled Formatter", 2, { title = "Formatter" })
		return conform.setup(opts)
	else
		vim.notify("Disabled Formater", 2, { title = "Formatter" })
		opts.format_on_save = false
		return conform.setup(opts)
	end
end, { desc = "Toggle formatter" })

conform.setup(opts)
