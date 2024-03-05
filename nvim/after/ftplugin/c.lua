vim.opt_local.spell = false
vim.opt_local.commentstring = "// %s"
vim.opt_local.path = { "/usr/include/**", "/usr/local/include/**" }

local map = vim.keymap.set
map("n", "<leader>js", vim.cmd.ClangdSwitchSourceHeader, { desc = "Switch Source Header" })
map("n", "<leader>ja", vim.cmd.ClangdAST, { desc = "AST Grep" })
map("n", "<leader>ji", vim.cmd.ClangdSymbolInfo, { desc = "Symbol Info" })
map("n", "<leader>jh", vim.cmd.ClangdTypeHierarchy, { desc = "Type Hierrarchy" })

local ok, cmp = pcall(require, "cmp")
if ok then
	cmp.setup.filetype("c", {
		comparators = {
			priority_weight = 100,
			comparators = {
				function(lhs, rhs)
					return lhs:get_kind() > rhs:get_kind()
				end,
				cmp.config.compare.offset,
				cmp.config.compare.exact,
				require("clangd_extensions.cmp_scores"),
				function(lhs, rhs)
					lhs:get_kind()
					local _, lhs_under = lhs.completion_item.label:find("^_+")
					local _, rhs_under = rhs.completion_item.label:find("^_+")
					lhs_under = lhs_under or 0
					rhs_under = rhs_under or 0
					return lhs_under < rhs_under
				end,
				cmp.config.compare.kind,
				cmp.config.compare.locality,
				cmp.config.compare.recently_used,
				cmp.config.compare.sort_text,
				cmp.config.compare.order,
			},
		},
	})
end
