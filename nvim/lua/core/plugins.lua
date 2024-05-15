local function rq(name)
	return require("configs." .. name)
end

return {
	-- lib
	{ "nvim-lua/plenary.nvim", lazy = true },
	{ "MunifTanjim/nui.nvim", lazy = true },
	{
		"nvim-tree/nvim-web-devicons",
		lazy = true,
		config = function()
			rq("nvim-web-devicons")
		end,
	},

	-- completion
	{
		"hrsh7th/nvim-cmp",
		keys = { "<leader>uk", "<leader>ue" },
		lazy = true,
		config = function()
			rq("nvim-cmp")
		end,
	},
	{ "hrsh7th/cmp-cmdline", event = "CmdlineEnter" },
	{ "hrsh7th/cmp-nvim-lsp", event = "InsertEnter" },
	{ "hrsh7th/cmp-calc", event = "InsertEnter" },
	{ "lukas-reineke/cmp-rg", event = "InsertEnter" },
	{ "saadparwaiz1/cmp_luasnip", event = "InsertEnter" },
	{
		"tzachar/cmp-fuzzy-path",
		event = { "CmdlineEnter", "InsertEnter" },
		dependencies = {
			{ "tzachar/fuzzy.nvim" },
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
	},
	{
		"L3MON4D3/LuaSnip",
		build = "make install_jsregexp",
		keys = function()
			return {}
		end,
		event = "ModeChanged *:[iRss\x13vV\x16]*",
		config = function()
			rq("luasnip")
		end,
	},

	-- coding shit
	{
		"mfussenegger/nvim-dap",
		config = function()
			rq("nvim-dap").setup()
		end,
		keys = rq("nvim-dap").keys,
		dependencies = {
			{
				"rcarriga/nvim-dap-ui",
				keys = rq("nvim-dap-ui").keys,
				config = function()
					rq("nvim-dap-ui").setup()
				end,
			},
			{ "theHamsta/nvim-dap-virtual-text", opts = { enabled_commands = true, all_frames = true } },
		},
	},
	{ "nvim-neotest/neotest-go", ft = "go" },
	{
		"nvim-neotest/neotest",
		dependencies = { "nvim-neotest/nvim-nio", "antoinemadec/FixCursorHold.nvim" },
		keys = rq("neotest").keys,
		config = function()
			rq("neotest").setup()
		end,
	},

	{ "Bekaboo/deadcolumn.nvim", event = "BufRead", config = true },
	{ "tpope/vim-dadbod", dependencies = { "kristijanhusak/vim-dadbod-ui" }, cmd = "DBUI" },
	{
		"JoosepAlviste/nvim-ts-context-commentstring",
		opts = { enable_autocmd = false },
		lazy = true,
	},
	{
		"numToStr/Comment.nvim",
		keys = rq("comment").keys,
		config = function()
			rq("comment").setup()
		end,
	},

	{ "echasnovski/mini.bufremove", keys = rq("mini-bufremove").keys },

	{
		"altermo/ultimate-autopair.nvim",
		event = "InsertEnter",
		config = function()
			rq("ultimate-autopair")
		end,
	},

	{
		"kylechui/nvim-surround",
		keys = rq("nvim-surround").keys,
		config = function()
			rq("nvim-surround").setup()
		end,
	},
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		keys = rq("trouble").keys,
		config = function()
			rq("trouble").setup()
		end,
	},
	{
		"ibhagwan/fzf-lua",
		cmd = "FzfLua",
		keys = rq("fzf-lua").keys,
		init = function()
			rq("fzf-lua").init()
		end,
		config = function()
			rq("fzf-lua").setup()
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		event = "BufRead",
		config = function()
			rq("gitsign")
		end,
	},

	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		keys = rq("harpoon").keys,
		config = function()
			rq("harpoon").setup()
		end,
	},
	{
		"rebelot/heirline.nvim",
		event = "VeryLazy",
		config = function()
			rq("heirline")
		end,
	},
	{
		"SmiteshP/nvim-navic",
		event = "LspAttach",
		opts = { highlight = true, lazy_update_context = true, icons = require("utils.icons").kinds },
	},

	-- languages
	{
		"ray-x/go.nvim",
		ft = { "go", "gomod" },
		branch = "master",
		--build = ':lua require("go.install").update_all_sync()',
		config = function()
			rq("go")
		end,
	},
	{
		"pmizio/typescript-tools.nvim",
		ft = { "javascript", "typescript" },
		config = function()
			rq("typescript-tools")
		end,
	},
	{
		"mrcjkb/rustaceanvim",
		ft = "rust",
		config = function()
			rq("rustocean")
		end,
	},

	-- lsp

	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		config = function()
			rq("mason")
		end,
	},
	{
		"neovim/nvim-lspconfig",
		event = "FileType",
		config = function()
			rq("lspconfig")
		end,
	},
	{
		"epwalsh/obsidian.nvim",
		version = "*",
		lazy = true,
		ft = "markdown",
		config = function()
			rq("obsidian")
		end,
	},
	{
		"stevearc/oil.nvim",
		cmd = "Oil",
		keys = rq("oil").keys,
		config = function()
			rq("oil").setup()
		end,
	},
	{
		"akinsho/toggleterm.nvim",
		keys = rq("toggleterm").keys,
		config = function()
			rq("toggleterm").setup()
		end,
	},
	{
		"willothy/flatten.nvim",
		lazy = false,
		priority = 1001,
		config = function()
			rq("flatten")
		end,
	},

	--- treesitter
	{
		"echasnovski/mini.ai",
		event = "VeryLazy",
		config = function()
			rq("mini-ai")
		end,
	},
	{
		"Wansmer/treesj",
		keys = {
			{ "<leader>kj", desc = "Join Block" },
			{ "<leader>kr", desc = "Split Recursive" },
			{ "<leader>ks", desc = "Just Split" },
		},
		config = function()
			rq("treesj")
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
		event = { "FileType", "VeryLazy" },
		init = function(plugin)
			require("lazy.core.loader").add_to_rtp(plugin)
			require("nvim-treesitter.query_predicates")
		end,
		keys = {
			{ "<leader><space>", desc = "Incremental Selection" },
			{ "<bs>", desc = "Decrement Selection", mode = "x" },
		},
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			config = function()
				rq("nvim-treesitter-textobjects")
			end,
		},
		build = ":TSUpdate",
		config = function()
			rq("nvim-treesitter")
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "BufRead",
		keys = rq("nvim-treesitter-context").keys,
		config = function()
			rq("nvim-treesitter-context").setup()
		end,
	},
	{ "NvChad/nvim-colorizer.lua", event = "BufRead", config = true },
	{
		"HiPhish/rainbow-delimiters.nvim",
		event = "BufReadPre",
		config = function()
			rq("rainbow-delimiters")
		end,
	},
	{
		"nvimdev/dashboard-nvim",
		event = "VimEnter",
		config = function()
			rq("dashboard")
		end,
	},

	{
		"RRethy/vim-illuminate",
		event = "BufRead",
		config = function()
			rq("vim-illuminate")
		end,
		keys = { "]]", "[[" },
	},

	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = "BufRead",
		config = function()
			rq("indent-blankline")
		end,
	},
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"rcarriga/nvim-notify",
			init = function()
				vim.notify = require("notify")
			end,
			config = function()
				rq("nvim-notify")
			end,
		},
		config = function()
			rq("noice")
		end,
	},
	{
		"folke/which-key.nvim",
		event = "BufEnter",
		config = function()
			rq("which-key")
		end,
	},
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1002,
		config = function()
			rq("tokyonight")
		end,
	},

	{
		"rest-nvim/rest.nvim",
		ft = "http",
		keys = { { "<leader>rr", ft = "http" }, { "<leader>rl", ft = "http" } },
		-- dependencies = {
		-- 	"vhyrro/luarocks.nvim",
		-- 	priority = 1000,
		-- 	config = true,
		-- 	opts = { rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" } },
		-- },
		config = function()
			rq("rest")
		end,
	},
	{
		"stevearc/conform.nvim",
		cmd = "ConformInfo",
		event = "BufWritePre",
		keys = { "<leader>uf" },
		init = function()
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
		config = function()
			rq("conform")
		end,
	},
}
