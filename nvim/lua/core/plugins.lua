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
	{ "dmitmel/cmp-cmdline-history", event = "CmdlineEnter" },
	{ "chrisgrieser/cmp_yanky", event = "TextYankPost" },
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
		"folke/todo-comments.nvim",
		event = "BufRead",
		keys = rq("comment").todo_comment_keys,
		config = function()
			rq("comment").todo_comment_setup()
		end,
	},
	{
		"numToStr/Comment.nvim",
		keys = rq("comment").comment_keys,
		config = function()
			rq("comment").comment_setup()
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
		init = rq("fzf-lua").init(),
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
		"nvimtools/none-ls.nvim",
		event = "BufWritePre",
		config = function()
			rq("none-ls")
		end,
	},

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
		ft = "markdown",
		config = function()
			rq("obsidian")
		end,
	},

	{
		"lukas-reineke/headlines.nvim",
		ft = { "markdown", "norg", "rmd", "org" },
		config = function()
			rq("headlines")
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
	{ "nvim-treesitter/nvim-treesitter-textobjects", event = "BufRead" },
	{
		"windwp/nvim-ts-autotag",
		config = true,
		ft = { "html", "javascriptreact", "typescriptreact", "templ", "markdown" },
	},
	{ "RRethy/nvim-treesitter-endwise", event = "BufRead" },
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
		keys = { "<leader><space>" },
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
	{ "https://gitlab.com/HiPhish/rainbow-delimiters.nvim", event = "BufRead" },
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
		"gbprod/yanky.nvim",
		dependencies = { "kkharji/sqlite.lua" },
		keys = rq("yanky").keys,
		opts = { highlight = { timer = 250 }, ring = { storage = "sqlite" } },
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

	{ "smjonas/inc-rename.nvim", config = true, event = { "BufRead", "LspAttach" }, cmd = "IncRename" },
	{
		"abecodes/tabout.nvim",
		lazy = false,
		priority = 1000,
		event = "InsertCharPre",
		config = function()
			rq("tabout")
		end,
	},
	{
		"kevinhwang91/nvim-ufo",
		dependencies = "kevinhwang91/promise-async",
		keys = rq("nvim-ufo").keys,
		config = function()
			rq("nvim-ufo").setup()
		end,
	},
}
