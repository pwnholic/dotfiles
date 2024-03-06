return {
	{ "nvim-treesitter/nvim-treesitter-textobjects", event = "BufRead" },
	{
		"windwp/nvim-ts-autotag",
		config = true,
		ft = { "html", "javascriptreact", "typescriptreact", "templ", "markdown" },
	},
	{
		"nvim-treesitter/nvim-treesitter",
		version = false,
		build = ":TSUpdate",
		event = "FileType",
		cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
		opts = {
			highlight = { enable = true },
			indent = { enable = true },
			sync_install = false,
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
		config = function(_, opts)
			if type(opts.ensure_installed) == "table" then
				local added = {}
				opts.ensure_installed = vim.tbl_filter(function(lang)
					if added[lang] then
						return false
					end
					added[lang] = true
					return true
				end, opts.ensure_installed)
			end

			require("nvim-treesitter.configs").setup(opts)

			local ts_locals = require("nvim-treesitter.locals")
			local ts_utils = require("nvim-treesitter.ts_utils")

			local function before(r1, r2)
                -- stylua: ignore start
				if not r1 or not r2 then return false end
				if r1.start.line < r2.start.line then return true end
				if r2.start.line < r1.start.line then return false end
				if r1.start.character < r2.start.character then return true end
				return false
				-- stylua: ignore start
			end

			local references = {}
			local function goto_adjent_reference(opt)
				opt = vim.tbl_extend("force", { forward = true, wrap = true }, opt or {})
				local current_buf = vim.api.nvim_get_current_buf()
				local refs = references[current_buf]
				if not refs or #refs == 0 then
					return nil
				end

				local next, next_index
				local cursor_row, cursor_col = table.unpack(vim.api.nvim_win_get_cursor(0))
				local cursor_range = { start = { line = cursor_row - 1, character = cursor_col } }

				for i, ref in ipairs(refs) do
					local range = ref.range
					if opt.forward then
						if before(cursor_range, range) and (not next or before(range, next)) then
							next = range
							next_index = i
						end
					else
						if before(range, cursor_range) and (not next or before(next, range)) then
							next = range
							next_index = i
						end
					end
				end
				if not next and opt.wrap then
					next_index = opt.reverse and #refs or 1
					next = refs[next_index].range
				end
				vim.api.nvim_win_set_cursor(0, { next.start.line + 1, next.start.character })
				return next
			end

			local function index_of(tbl, obj)
				for i, o in ipairs(tbl) do
					if o == obj then
						return i
					end
				end
			end

			local function goto_adjacent_usage(bufnr, delta)
				local en, opt = true, { forward = delta > 0 }

				if type(en) == "table" then
					en = vim.tbl_contains(en, vim.o.ft)
				end
				if en == false then
					return goto_adjent_reference(opt)
				end

				bufnr = bufnr or vim.api.nvim_get_current_buf()
				local node_at_point = ts_utils.get_node_at_cursor()
				if not node_at_point then
					goto_adjent_reference(opt)
					return
				end

				local def_node, scope = ts_locals.find_definition(node_at_point, bufnr)
				local usages = ts_locals.find_usages(def_node, scope, bufnr)
				local index = index_of(usages, node_at_point)

				if not index then
					goto_adjent_reference(opt)
					return
				end
				local target_index = (index + delta + #usages - 1) % #usages + 1
				ts_utils.goto_node(usages[target_index])
			end

			vim.keymap.set("n", "]]", function()
				goto_adjacent_usage(vim.api.nvim_get_current_buf(), 1)
			end, { desc = "Next Usage" })
			vim.keymap.set("n", "[[", function()
				goto_adjacent_usage(vim.api.nvim_get_current_buf(), -1)
			end, { desc = "Prev Usage" })
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "BufRead",
		opts = { mode = "cursor", max_lines = 3 },
		keys = {
			{
				"<leader>ut",
				function()
					local tsc = require("treesitter-context")
					tsc.toggle()
					local function ts_get_upvalue_ctx(func, name)
						local i = 1
						while true do
							local n, v = debug.getupvalue(func, i)
							if not n then
								break
							end
							if n == name then
								return v
							end
							i = i + 1
						end
					end
					if ts_get_upvalue_ctx(tsc.toggle, "enabled") then
						vim.notify("Enabled Treesitter Context", vim.diagnostic.severity.INFO, { title = "Option" })
					else
						vim.notify("Disabled Treesitter Context", vim.diagnostic.severity.INFO, { title = "Option" })
					end
				end,
				desc = "Toggle Treesitter Context",
			},
		},
	},
}
