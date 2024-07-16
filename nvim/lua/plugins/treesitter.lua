return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	event = { "LazyFile", "VeryLazy" },
	opts = { ensure_installed = "all", sync_install = true, auto_install = true, ignore_install = {} },
}
