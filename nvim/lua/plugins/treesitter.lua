return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	event = { "LazyFile", "VeryLazy" },
	opts = { ensure_installed = "all", sync_install = false, auto_install = true, ignore_install = {} },
}
