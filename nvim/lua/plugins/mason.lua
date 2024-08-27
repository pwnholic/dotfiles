return {
	"williamboman/mason.nvim",
	cmd = "Mason",
	build = ":MasonUpdate",
	opts = function()
		return {
			PATH = "prepend",
			max_concurrent_installers = 20,
			ensure_installed = {
				"lua-language-server",
				"stylua",
				"selene",

				"gopls",
				"goimports-reviser",
				"delve",
				"go-debug-adapter",

				"clangd",
				"clang-format",
				"codelldb",

				"debugpy",
				"ruff",
				"basedpyright",

				"vtsls",
				"prettier",
				"js-debug-adapter",

				"rust-analyzer",
				"bacon",

				"vscode-solidity-server",
				"solhint",

				"marksman",
				"vale",

				"sqls",
				"sqlfluff",
			},
		}
	end,
	---@param opts MasonSettings | {ensure_installed: string[]}
	config = function(_, opts)
		require("mason").setup(opts)
		local mr = require("mason-registry")
		mr:on("package:install:success", function()
			vim.defer_fn(function()
				-- trigger FileType event to possibly load this newly installed LSP server
				require("lazy.core.handler.event").trigger({
					event = "FileType",
					buf = vim.api.nvim_get_current_buf(),
				})
			end, 100)
		end)

		mr.refresh(function()
			for _, tool in ipairs(opts.ensure_installed) do
				local p = mr.get_package(tool)
				if not p:is_installed() then
					p:install()
				end
			end
		end)
	end,
}
