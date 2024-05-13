local mason_install = {
	"stylua",
	"shfmt",

	"pyright",
	"gopls",
	"clangd",
	"lua-language-server",
	"rust-analyzer",
	"typescript-language-server",
	"phpactor",
	"marksman",

	"black",
	"clang-format",
	"stylua",
	"prettier",
	"goimports",

	"mdformat",
	"delve",
	"golangci-lint",
	"markdownlint",
	"selene",
	"eslint_d",
}

require("mason").setup({
	ensure_installed = mason_install,
	max_concurrent_installers = 10,
})

local mr = require("mason-registry")
mr:on("package:install:success", function()
	vim.defer_fn(function()
		require("lazy.core.handler.event").trigger({
			event = "FileType",
			buf = vim.api.nvim_get_current_buf(),
		})
	end, 100)
end)
local function ensure_installed()
	for _, tool in ipairs(mason_install) do
		local p = mr.get_package(tool)
		if not p:is_installed() then
			p:install()
		end
	end
end
if mr.refresh then
	mr.refresh(ensure_installed)
else
	ensure_installed()
end
