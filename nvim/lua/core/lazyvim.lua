local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazy_path)

---@diagnostic disable-next-line: undefined-field
if not vim.uv.fs_stat(lazy_path) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazy_path,
	})
end

require("lazy").setup(require("core.plugins"), {
	defaults = { lazy = true, version = "*" },
	install = { missing = true, colorscheme = { "tokyonight" } },
	change_detection = { enabled = true, notify = false },
	checker = { enabled = true, notify = false, frequency = (3600 * 24) * 7 },
	ui = {
		border = "single",
		icons = { ft = " ", lazy = "󰂠 ", loaded = " ", not_loaded = " " },
	},
	performance = {
		cache = { enabled = true },
		reset_packpath = true,
		rtp = {
			reset = true,
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
