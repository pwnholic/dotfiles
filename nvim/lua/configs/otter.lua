local ot = require("otter")

ot.setup({ buffers = { set_filetype = true } })

---Use otter for LSP actions only in markdown code blocks
---@param action string
---@return function
local function action_fallback(action)
	return function()
		return require("utils.markup").in_codeblock() and ot["ask_" .. action]() or vim.lsp.buf[action]()
	end
end

vim.api.nvim_create_autocmd("FileType", {
	desc = "Activate otter for filetypes with injections.",
	group = vim.api.nvim_create_augroup("OtterActivate", {}),
	pattern = { "markdown", "norg", "org" },
	callback = function(info)
		vim.schedule(function()
			local buf = info.buf
			if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].ma or not require("utils.ts").is_active(buf) then
				return
			end
			-- Enable completion only, disable diagnostics
			ot.activate({ "python", "bash", "lua" }, true, false)
      -- stylua: ignore start
      vim.api.nvim_buf_create_user_command(buf, 'OtterRename', ot.ask_rename, {})
      vim.api.nvim_buf_create_user_command(buf, 'OtterHover', ot.ask_hover, {})
      vim.api.nvim_buf_create_user_command(buf, 'OtterReferences', ot.ask_references, {})
      vim.api.nvim_buf_create_user_command(buf, 'OtterTypeDefinition', ot.ask_type_definition, {})
      vim.api.nvim_buf_create_user_command(buf, 'OtterDefinition', ot.ask_definition, {})
      vim.api.nvim_buf_create_user_command(buf, 'OtterFormat', ot.ask_format, {})
      vim.api.nvim_buf_create_user_command(buf, 'OtterDocumentSymbols', ot.ask_document_symbols, {})
      vim.keymap.set('n', '<Leader>r', action_fallback('rename'),          { buffer = buf })
      vim.keymap.set('n', 'K',         action_fallback('hover'),           { buffer = buf })
      vim.keymap.set('n', 'g/',        action_fallback('references'),      { buffer = buf })
      vim.keymap.set('n', 'gD',        action_fallback('type_definition'), { buffer = buf })
      vim.keymap.set('n', 'gd',        action_fallback('definition'),      { buffer = buf })
      vim.keymap.set('n', 'gq;',       action_fallback('format'),          { buffer = buf })
			-- stylua: ignore end
		end)
	end,
})

-- Use otter to provide completions in code blocks
local cmp_ok, cmp = pcall(require, "cmp")
if cmp_ok then
	cmp.setup({
		sources = table.insert(require("cmp.config").get().sources, { name = "otter" }),
	})
end
