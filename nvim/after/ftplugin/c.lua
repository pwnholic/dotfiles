local ok, cmp = pcall(require, "cmp")
if not ok then
	return
end

cmp.setup.filetype({ "c", "cpp" }, {
	sorting = {
		priority_weight = 100,
		comparators = {
			require("cmp_fuzzy_path.compare"),
			function(lhs, rhs)
				local diff
				if lhs.completion_item.score and rhs.completion_item.score then
					diff = (rhs.completion_item.score * rhs.score) - (lhs.completion_item.score * lhs.score)
				else
					diff = rhs.score - lhs.score
				end
				return (diff < 0)
			end,
			cmp.config.compare.offset,
			cmp.config.compare.exact,
			cmp.config.compare.score,
			cmp.config.compare.recently_used,
			cmp.config.compare.locality,
			cmp.config.compare.kind,
		},
	},
})

require("utils.lsp").start({
	root_patterns = {
		"Makefile",
		"configure.ac",
		"configure.in",
		"config.h.in",
		"meson.build",
		"meson_options.txt",
		"build.ninja",
	},
	capabilities = { offsetEncoding = { "utf-16" } },
	name = "clangd",
	cmd = {
		vim.fn.stdpath("data") .. "/mason/bin/clangd",
		"--background-index",
		"--clang-tidy",
		"--header-insertion=iwyu",
		"--completion-style=detailed",
		"--function-arg-placeholders",
		"--fallback-style=llvm",
	},
	init_options = {
		usePlaceholders = true,
		completeUnimported = true,
		clangdFileStatus = true,
	},
})
