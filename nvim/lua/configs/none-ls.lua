local null_ls = require("null-ls")

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local diagIcons = require("utils.icons").diagnostics

null_ls.setup({
	default_timeout = 5000,
	sources = {
		null_ls.builtins.formatting.stylua,
		-- null_ls.builtins.diagnostics.selene,

		null_ls.builtins.formatting.goimports,
		-- null_ls.builtins.diagnostics.golangci_lint,

		-- null_ls.builtins.formatting.markdownlint,
		null_ls.builtins.formatting.prettier,
		null_ls.builtins.formatting.black,
		null_ls.builtins.formatting.clang_format,
	},
	debug = false,
	on_attach = function(client, bufnr)
		if not vim.api.nvim_buf_is_loaded(bufnr) then
			return
		else
			if client.server_capabilities.documentFormattingProvider then
                -- stylua: ignore start
				local get_available_formatter = #require("null-ls.generators").get_available( vim.bo[bufnr].filetype, require("null-ls.methods").internal.FORMATTING) > 0
				if (client.name == "null-ls" and get_available_formatter) or client.name ~= "null-ls" then
					vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr()"
					vim.keymap.set("n", "<leader>gF", function() vim.lsp.buf.format({ async = true }) end, { desc = "Format this code" })
				else
					vim.bo[bufnr].formatexpr = nil
				end
				-- stylua: ignore end
			end

			if client.supports_method("textDocument/formatting") then
				vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
				vim.api.nvim_create_autocmd("BufWritePost", {
					group = augroup,
					buffer = bufnr,
					callback = function()
						vim.lsp.buf_request(
							bufnr,
							"textDocument/formatting",
							vim.lsp.util.make_formatting_params({}),
							function(err, res, _)
								if err then
									local err_msg = type(err) == "string" and err or err.message
									-- you can modify the log message / level (or ignore it completely)
									vim.notify("formatting: " .. err_msg, vim.log.levels.WARN)
									return
								end

								-- don't apply results if buffer is unloaded or has been modified
								if not vim.api.nvim_buf_is_loaded(bufnr) or vim.bo.modified then
									return
								end

								if res then
									vim.lsp.util.apply_text_edits(
										res,
										bufnr,
										client and client.offset_encoding or "utf-16"
									)
									vim.api.nvim_buf_call(bufnr, function()
										vim.cmd("silent noautocmd update")
									end)
								end
							end
						)
					end,
				})
			end
		end
	end,
	diagnostic_config = {
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
	},
	diagnostics_format = "[#{c}] #{m} (#{s})",
})
