return {
	{ "nvim-tree/nvim-web-devicons", lazy = true },
	{ "MunifTanjim/nui.nvim", lazy = true },
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make", lazy = true },
	{ "nvim-lua/plenary.nvim", lazy = true },
	{ "nvim-neotest/nvim-nio", lazy = true },
	{
		"vhyrro/luarocks.nvim",
		config = true,
		lazy = true,
		opts = {
			rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" },
		},
	},
}
