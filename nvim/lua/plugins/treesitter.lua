return {

	{
		"nvim-treesitter/nvim-treesitter",
		version = false, -- last release is way too old and doesn't work on Windows
		build = ":TSUpdate",
		event = "VeryLazy",
		lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
		init = function(plugin)
			-- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
			-- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
			-- no longer trigger the **nvim-treesitter** module to be loaded in time.
			-- Luckily, the only things that those plugins need are the custom queries, which we make available
			-- during startup.
			require("lazy.core.loader").add_to_rtp(plugin)
			require("nvim-treesitter.query_predicates")
		end,
		cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
		keys = {
			{ "<c-space>", desc = "Increment Selection" },
			{ "<bs>", desc = "Decrement Selection", mode = "x" },
		},
		opts_extend = { "ensure_installed" },
		---@type TSConfig
		---@diagnostic disable-next-line: missing-fields
		opts = {
			--sync_install =true,
			highlight = { enable = true },
			indent = { enable = true },
			ensure_installed = "all",
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = false,
					node_decremental = "<bs>",
				},
			},
			textobjects = {
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["af"] = { query = "@function.outer", desc = "Around Func" },
						["if"] = { query = "@function.inner", desc = "Inside Func" },
						["al"] = { query = "@loop.outer", desc = "Around Loop" },
						["il"] = { query = "@loop.inner", desc = "Inside Loop" },
						["ak"] = { query = "@class.outer", desc = "Around Class" },
						["ik"] = { query = "@class.inner", desc = "Inside Class" },
						["ap"] = { query = "@parameter.outer", desc = "Around Param" },
						["ip"] = { query = "@parameter.inner", desc = "Inside Param" },
						["a/"] = { query = "@comment.outer", desc = "Around Comment" },
						["ab"] = { query = "@block.outer", desc = "Around Block" },
						["ib"] = { query = "@block.inner", desc = "Inside Block" },
						["ac"] = { query = "@conditional.outer", desc = "Around Cond" },
						["ic"] = { query = "@conditional.inner", desc = "Inside Cond" },
					},
				},
				move = {
					enable = true,
					goto_next_start = {
						["]f"] = { query = "@function.outer", desc = "Func Next Start" },
						["]c"] = { query = "@class.outer", desc = "Class Next Start" },
						["]a"] = { query = "@parameter.inner", desc = "Param Next Start" },
						["]b"] = { query = "@block.outer", desc = "Block Next Start" },
						["]l"] = { query = "@loop.outer", desc = "Loop Next Start" },
						["]k"] = { query = "@conditional.outer", desc = "Cond Next Start" },
					},
					goto_next_end = {
						["]F"] = { query = "@function.outer", desc = "Func Next End" },
						["]C"] = { query = "@class.outer", desc = "Class Next End" },
						["]A"] = { query = "@parameter.inner", desc = "Param Next End" },
						["]B"] = { query = "@block.outer", desc = "Block Next End" },
						["]L"] = { query = "@loop.outer", desc = "Loop Next End" },
						["]K"] = { query = "@conditional.outer", desc = "Cond Next End" },
					},
					goto_previous_start = {
						["[f"] = { query = "@function.outer", desc = "Func Prev Start" },
						["[c"] = { query = "@class.outer", desc = "Class Prev Start" },
						["[a"] = { query = "@parameter.inner", desc = "Param Prev Start" },
						["[b"] = { query = "@block.outer", desc = "Blokc Prev Start" },
						["[l"] = { query = "@loop.outer", desc = "Loop Prev Start" },
						["[k"] = { query = "@conditional.outer", desc = "Cond Prev Start" },
					},
					goto_previous_end = {
						["[F"] = { query = "@function.outer", desc = "Func Prev End" },
						["[C"] = { query = "@class.outer", desc = "Prev Prev End" },
						["[A"] = { query = "@parameter.inner", desc = "Param Prev End" },
						["[B"] = { query = "@block.outer", desc = "Blokc Prev End" },
						["[L"] = { query = "@loop.outer", desc = "Loop Prev End" },
						["[K"] = { query = "@conditional.outer", desc = "Cond Prev End" },
					},
				},
			},
		},
		---@param opts TSConfig
		config = function(_, opts)
			if type(opts.ensure_installed) == "table" then
				opts.ensure_installed = require("utils").dedup(opts.ensure_installed)
			end
			require("nvim-treesitter.configs").setup(opts)
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		event = "VeryLazy",
		enabled = true,
		config = function()
			local utils = require("utils")
			-- If treesitter is already loaded, we need to run config again for textobjects
			if utils.is_loaded("nvim-treesitter") then
				local opts = utils.opts("nvim-treesitter")
				require("nvim-treesitter.configs").setup({ textobjects = opts.textobjects })
			end

			-- When in diff mode, we want to use the default
			-- vim text objects c & C instead of the treesitter ones.
			local move = require("nvim-treesitter.textobjects.move") ---@type table<string,fun(...)>
			local configs = require("nvim-treesitter.configs")
			for name, fn in pairs(move) do
				if name:find("goto") == 1 then
					move[name] = function(q, ...)
						if vim.wo.diff then
							local config = configs.get_module("textobjects.move")[name] ---@type table<string,string>
							for key, query in pairs(config or {}) do
								if q == query and key:find("[%]%[][cC]") then
									vim.cmd("normal! " .. key)
									return
								end
							end
						end
						return fn(q, ...)
					end
				end
			end
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "BufReadPre",
		opts = { mode = "cursor", max_lines = 3 },
		keys = {
			{
				"<leader>ut",
				function()
					local tsc = require("treesitter-context")
					tsc.toggle()
				end,
				desc = "Toggle Treesitter Context",
			},
		},
	},
}
