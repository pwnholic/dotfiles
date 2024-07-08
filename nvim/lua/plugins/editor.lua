return {
	{
		"stevearc/oil.nvim",
		lazy = false,
		keys = { { "<leader>e", vim.cmd.Oil, desc = "Open Oil Buffer" } },
		opts = function()
			vim.g.loaded_fzf_file_explorer = 1
			vim.g.loaded_netrw = 1
			vim.g.loaded_netrwPlugin = 1

			local oil = require("oil")
			local icons = require("utils").icons.kinds

			local preview_wins = {} ---@type table<integer, integer>
			local preview_bufs = {} ---@type table<integer, integer>
			local preview_max_fsize = 1000000
			local preview_debounce = 64 -- ms
			local preview_request_last_timestamp = 0

			---Change window-local directory to `dir`
			---@param dir string
			---@return nil
			local function lcd(dir)
				local ok = pcall(vim.cmd.lcd, dir)
				if not ok then
					vim.notify("[oil.nvim] failed to cd to " .. dir, vim.log.levels.WARN)
				end
			end

			---Generate lines for preview window when preview is not available
			---@param msg string
			---@param height integer
			---@param width integer
			---@return string[]
			local function nopreview(msg, height, width)
				local lines = {}
				local fillchar = vim.opt_local.fillchars:get().diff or "-"
				local msglen = #msg + 4
				local padlen_l = math.max(0, math.floor((width - msglen) / 2))
				local padlen_r = math.max(0, width - msglen - padlen_l)
				local line_fill = fillchar:rep(width)
				local half_fill_l = fillchar:rep(padlen_l)
				local half_fill_r = fillchar:rep(padlen_r)
				local line_above = half_fill_l .. string.rep(" ", msglen) .. half_fill_r
				local line_below = line_above
				local line_msg = half_fill_l .. "  " .. msg .. "  " .. half_fill_r
				local half_height_u = math.max(0, math.floor((height - 3) / 2))
				local half_height_d = math.max(0, height - 3 - half_height_u)
				for _ = 1, half_height_u do
					table.insert(lines, line_fill)
				end
				table.insert(lines, line_above)
				table.insert(lines, line_msg)
				table.insert(lines, line_below)
				for _ = 1, half_height_d do
					table.insert(lines, line_fill)
				end
				return lines
			end

			---End preview for oil window `win`
			---Close preview window and delete preview buffer
			---@param oil_win? integer oil window ID
			---@return nil
			local function end_preview(oil_win)
				oil_win = oil_win or vim.api.nvim_get_current_win()
				local preview_win = preview_wins[oil_win]
				local preview_buf = preview_bufs[oil_win]
				if
					preview_win
					and vim.api.nvim_win_is_valid(preview_win)
					and vim.fn.winbufnr(preview_win) == preview_buf
				then
					vim.api.nvim_win_close(preview_win, true)
				end
				if preview_buf and vim.api.nvim_win_is_valid(preview_buf) then
					vim.api.nvim_win_close(preview_buf, true)
				end
				preview_wins[oil_win] = nil
				preview_bufs[oil_win] = nil
			end

			---Preview file under cursor in a split
			---@return nil
			local function preview()
				local entry = oil.get_cursor_entry()
				local fname = entry and entry.name
				local dir = oil.get_current_dir()
				if not dir or not fname then
					return
				end
				local fpath = vim.fs.joinpath(dir, fname)
				local stat = vim.uv.fs_stat(fpath)
				if not stat or (stat.type ~= "file" and stat.type ~= "directory") then
					return
				end
				local oil_win = vim.api.nvim_get_current_win()
				local preview_win = preview_wins[oil_win]
				local preview_buf = preview_bufs[oil_win]
				if
					not preview_win
					or not preview_buf
					or not vim.api.nvim_win_is_valid(preview_win)
					or not vim.api.nvim_buf_is_valid(preview_buf)
				then
					local oil_win_height = vim.api.nvim_win_get_height(oil_win)
					local oil_win_width = vim.api.nvim_win_get_width(oil_win)

					vim.cmd.new({ mods = { vertical = oil_win_width > 6 * oil_win_height } })

					preview_win = vim.api.nvim_get_current_win()
					preview_buf = vim.api.nvim_get_current_buf()
					preview_wins[oil_win] = preview_win
					preview_bufs[oil_win] = preview_buf

					vim.bo[preview_buf].swapfile = false
					vim.bo[preview_buf].buflisted = false
					vim.bo[preview_buf].buftype = "nofile"
					vim.bo[preview_buf].bufhidden = "wipe"
					vim.bo[preview_buf].filetype = "oil_preview"
					vim.opt_local.spell = false
					vim.opt_local.number = false
					vim.opt_local.relativenumber = false
					vim.opt_local.signcolumn = "no"
					vim.opt_local.foldcolumn = "0"
					vim.opt_local.winbar = ""
					vim.opt_local.list = true
					vim.opt.listchars = { tab = "  " }
					vim.api.nvim_set_current_win(oil_win)
				end
				-- Set keymap for opening the file from preview buffer
				vim.keymap.set("n", "<CR>", function()
					vim.cmd.edit(fpath)
					end_preview(oil_win)
				end, { buffer = preview_buf })
				-- Preview buffer already contains contents of file to preview
				local preview_bufname = vim.fn.bufname(preview_buf)
				local preview_bufnewname = "oil_preview://" .. fpath
				if preview_bufname == preview_bufnewname then
					return
				end
				local preview_win_height = vim.api.nvim_win_get_height(preview_win)
				local preview_win_width = vim.api.nvim_win_get_width(preview_win)
				local add_syntax = false
				local lines = {}
				lines = stat.type == "directory" and vim.fn.systemlist("ls -lhA " .. vim.fn.shellescape(fpath))
					or stat.size == 0 and nopreview("Empty file", preview_win_height, preview_win_width)
					or stat.size > preview_max_fsize and nopreview(
						"File too large to preview",
						preview_win_height,
						preview_win_width
					)
					or not vim.fn.system({ "file", fpath }):match("text") and nopreview(
						"Binary file, no preview available",
						preview_win_height,
						preview_win_width
					)
					or (function()
							add_syntax = true
							return true
						end)()
						and vim.iter(io.lines(fpath))
							:map(function(line)
								return (line:gsub("\x0d$", ""))
							end)
							:totable()
				vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
				vim.api.nvim_buf_set_name(preview_buf, preview_bufnewname)
				-- If previewing a directory, change cwd to that directory
				-- so that we can `gf` to files in the preview buffer;
				-- else change cwd to the parent directory of the file in preview
				vim.api.nvim_win_call(preview_win, function()
					local target_dir = stat.type == "directory" and fpath or dir
					if not vim.fn.getcwd(0) ~= target_dir then
						lcd(target_dir)
					end
				end)
				vim.api.nvim_buf_call(preview_buf, function()
					vim.treesitter.stop(preview_buf)
				end)
				vim.bo[preview_buf].syntax = ""
				if not add_syntax then
					return
				end
				local ft = vim.filetype.match({ buf = preview_buf, filename = fpath })
				if ft and not pcall(vim.treesitter.start, preview_buf, ft) then
					vim.bo[preview_buf].syntax = ft
				end
			end

			local groupid_preview = vim.api.nvim_create_augroup("OilPreview", {})
			vim.api.nvim_create_autocmd({ "CursorMoved", "WinScrolled" }, {
				desc = "Update floating preview window when cursor moves or window scrolls.",
				group = groupid_preview,
				pattern = "oil:///*",
				callback = function()
					local oil_win = vim.api.nvim_get_current_win()
					local preview_win = preview_wins[oil_win]
					if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
						end_preview()
						return
					end
					local current_request_timestamp = vim.uv.now()
					preview_request_last_timestamp = current_request_timestamp
					vim.defer_fn(function()
						if preview_request_last_timestamp == current_request_timestamp then
							preview()
						end
					end, preview_debounce)
				end,
			})
			vim.api.nvim_create_autocmd("BufEnter", {
				desc = "Close preview window when leaving oil buffers.",
				group = groupid_preview,
				callback = function(info)
					if vim.bo[info.buf].filetype ~= "oil" then
						end_preview()
					end
				end,
			})

			vim.api.nvim_create_autocmd("WinClosed", {
				desc = "Close preview window when closing oil windows.",
				group = groupid_preview,
				callback = function(info)
					local win = tonumber(info.match)
					if win and preview_wins[win] then
						end_preview(win)
					end
				end,
			})

			---Toggle preview window
			---@return nil
			local function toggle_preview()
				local oil_win = vim.api.nvim_get_current_win()
				local preview_win = preview_wins[oil_win]
				if not preview_win or not vim.api.nvim_win_is_valid(preview_win) then
					preview()
					return
				end
				end_preview()
			end

			local permission_hlgroups = setmetatable({
				["-"] = "OilPermissionNone",
				["r"] = "OilPermissionRead",
				["w"] = "OilPermissionWrite",
				["x"] = "OilPermissionExecute",
			}, {
				__index = function()
					return "OilDir"
				end,
			})

			local type_hlgroups = setmetatable({
				["-"] = "OilTypeFile",
				["d"] = "OilTypeDir",
				["p"] = "OilTypeFifo",
				["l"] = "OilTypeLink",
				["s"] = "OilTypeSocket",
			}, {
				__index = function()
					return "OilTypeFile"
				end,
			})

			local columns = {
				{
					"permissions",
					highlight = function(permission_str)
						local hls = {}
						for i = 1, #permission_str do
							local char = permission_str:sub(i, i)
							table.insert(hls, { permission_hlgroups[char], i - 1, i })
						end
						return hls
					end,
				},
				{
					"type",
					icons = { directory = "directory", fifo = "fifo", file = "file", link = "link", socket = "socket" },
					highlight = function(type_str)
						return type_hlgroups[type_str]
					end,
				},
				{ "size", highlight = "AlphaButtons" },
				{ "mtime", highlight = "RainbowDelimiterViolet" },
				{ "icon", default_file = icons.File, directory = icons.Folder, add_padding = false },
			}

			return {
				default_file_explorer = true,
				columns = columns,
				win_options = {
					number = false,
					relativenumber = false,
					signcolumn = "no",
					foldcolumn = "0",
					wrap = false,
					cursorcolumn = false,
					spell = false,
					list = false,
					conceallevel = 3,
					concealcursor = "nvic",
					statuscolumn = "",
				},
				cleanup_delay_ms = false,
				delete_to_trash = true,
				skip_confirm_for_simple_edits = false,
				experimental_watch_for_changes = true,
				-- Set to `false` to disable, or "name" to keep it on the file names
				constrain_cursor = "name",
				prompt_save_on_select_new_entry = true,
				use_default_keymaps = false,
				view_options = {
					is_hidden_file = function(name)
						return vim.startswith(name, ".") --[[or vim.tbl_contains(require("directory").ignore_folder, name)]]
					end,
					is_always_hidden = function(name)
						return name == ".."
					end,
				},
				keymaps = {
					["-"] = "actions.parent",
					["g?"] = "actions.show_help",
					["g-"] = "actions.toggle_trash",
					["gh"] = "actions.toggle_hidden",
					["gs"] = "actions.change_sort",
					["gr"] = "actions.refresh",
					["gx"] = "actions.open_external",
					["<CR>"] = "actions.select",
					["K"] = { mode = { "n", "x" }, desc = "Toggle preview", callback = toggle_preview },
					["gq"] = {
						desc = "Quit Oil Buffer",
						callback = function()
							local win = vim.api.nvim_get_current_win()
							local alt = vim.api.nvim_win_call(win, function()
								return vim.fn.winnr("#")
							end)
							oil.close()
							if vim.api.nvim_win_is_valid(win) and vim.g[win].oil_opened and alt ~= 0 then
								vim.api.nvim_win_close(win, false)
							end
						end,
					},
					["gt"] = {
						desc = "Toggle detail view",
						callback = function()
							local config = require("oil.config")
							if #config.columns == 1 then
								oil.set_columns(columns)
							else
								oil.set_columns({ "icon" })
							end
						end,
					},
					["gp"] = {
						desc = "Go to Current Working Dir",
						callback = function()
							return oil.open(os.getenv("PWD"))
						end,
					},
					["g."] = {
						desc = "Go to Home Dir",
						callback = function()
							return oil.open(os.getenv("HOME"))
						end,
					},
					["go"] = {
						desc = "Choose an external program to open the entry under the cursor",
						callback = function()
							local entry, dir = oil.get_cursor_entry(), oil.get_current_dir()
							if not entry or not dir then
								return
							end
							local entry_path = vim.fs.joinpath(dir, entry.name)
							local response
							vim.ui.input({ prompt = "Open with: ", completion = "shellcmd" }, function(r)
								response = r
							end)
							if not response then
								return
							end
							print("\n")
							vim.system({ response, entry_path })
						end,
					},
					["gy"] = {
						desc = "Yank the filepath of the entry under the cursor to a register",
						callback = function()
							local entry, pwd = oil.get_cursor_entry(), oil.get_current_dir()
							if not entry or not pwd then
								return
							end
							local full_path = vim.fs.joinpath(pwd, entry.name)
							vim.fn.setreg('"', full_path)
							vim.fn.setreg(vim.v.register, full_path)
							vim.notify(string.format("[oil] yanked '%s' to register '%s'", full_path, vim.v.register))
						end,
					},
				},
				float = { border = vim.g.border, win_options = { winblend = 0 } },
				preview = { border = vim.g.border, win_options = { winblend = 0 } },
				progress = { border = vim.g.border, win_options = { winblend = 0 } },
			}
		end,
		config = function(_, opts)
			local oil = require("oil")
			oil.setup(opts)

			local groupid = vim.api.nvim_create_augroup("OilSyncCwd", {})
			vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged" }, {
				desc = "Set cwd to follow directory shown in oil buffers.",
				group = groupid,
				pattern = "oil:///*",
				callback = function(info)
					if vim.bo[info.buf].filetype == "oil" then
						local cwd = vim.fs.normalize(vim.fn.getcwd(vim.fn.winnr()))
						local oildir = vim.fs.normalize(oil.get_current_dir())
						if cwd ~= oildir and vim.uv.fs_stat(oildir) then
							local ok = pcall(vim.cmd.lcd, oildir)
							if not ok then
								vim.notify("[oil.nvim] failed to cd to " .. oildir, vim.log.levels.WARN)
							end
						end
					end
				end,
			})

			vim.api.nvim_create_autocmd("DirChanged", {
				desc = "Let oil buffers follow cwd.",
				group = groupid,
				callback = function(info)
					if vim.bo[info.buf].filetype == "oil" then
						vim.defer_fn(function()
							local cwd = vim.fs.normalize(vim.fn.getcwd(vim.fn.winnr()))
							local oildir = vim.fs.normalize(oil.get_current_dir() or "")
							if cwd ~= oildir and vim.bo.ft == "oil" then
								oil.open(cwd)
							end
						end, 100)
					end
				end,
			})

			vim.api.nvim_create_autocmd("BufEnter", {
				desc = "Set last cursor position in oil buffers when editing parent dir.",
				group = vim.api.nvim_create_augroup("OilSetLastCursor", {}),
				pattern = "oil:///*",
				callback = function()
					-- Place cursor on the alternate buffer if we are opening
					-- the parent directory of the alternate buffer
					local buf_alt = vim.fn.bufnr("#")
					if vim.api.nvim_buf_is_valid(buf_alt) then
						local bufname_alt = vim.api.nvim_buf_get_name(buf_alt)
						local parent_url, basename = oil.get_buffer_parent_url(bufname_alt, true)
						if basename then
							require("oil.view").set_last_cursor(parent_url, basename)
						end
					end
				end,
			})
		end,
	},
	{
		"altermo/ultimate-autopair.nvim",
		event = "InsertEnter",
		branch = "v0.6", --recommended as each new version will have breaking changes
		opts = function()
			---Record previous cmdline completion types,
			---`cmdcompltype[1]` is the current completion type,
			---`cmdcompltype[2]` is the previous completion type
			---@type string[]
			local compltype = {}

			vim.api.nvim_create_autocmd("CmdlineChanged", {
				desc = "Record cmd compltype to determine whether to autopair.",
				group = vim.api.nvim_create_augroup("AutopairRecordCmdCompltype", {}),
				callback = function()
					local type = vim.fn.getcmdcompltype()
					if compltype[1] == type then
						return
					end
					compltype[2] = compltype[1]
					compltype[1] = type
				end,
			})

			---Get next two characters after cursor, whether in cmdline or normal buffer
			---@return string: next two characters
			local function get_next_two_chars()
				local col, line
				if vim.fn.mode():match("^c") then
					col = vim.fn.getcmdpos()
					line = vim.fn.getcmdline()
				else
					col = vim.fn.col(".")
					line = vim.api.nvim_get_current_line()
				end
				return line:sub(col, col + 1)
			end

			-- Matches strings that start with:
			-- keywords: \k
			-- opening pairs: (, [, {, \(, \[, \{
			local IGNORE_REGEX = vim.regex([=[^\%(\k\|\\\?[([{]\)]=])

			return {
				extensions = {
					-- Improve performance when typing fast, see
					-- https://github.com/altermo/ultimate-autopair.nvim/issues/74
					tsnode = false,
					utf8 = false,
					filetype = { tree = false },
					cond = {
						cond = function(f)
							return not f.in_macro()
								-- Disable autopairs if followed by a keyword or an opening pair
								and not IGNORE_REGEX:match_str(get_next_two_chars())
								-- Disable autopairs when inserting a regex,
								-- e.g. `:s/{pattern}/{string}/[flags]` or
								-- `:g/{pattern}/[cmd]`, etc.
								and (not f.in_cmdline() or compltype[1] ~= "" or compltype[2] ~= "command")
						end,
					},
				},
				{ "\\(", "\\)" },
				{ "\\[", "\\]" },
				{ "\\{", "\\}" },
				{ "[=[", "]=]", ft = { "lua" } },
				{ "<<<", ">>>", ft = { "cuda" } },
				{ "/*", "*/", ft = { "c", "cpp", "cuda" }, newline = true, space = true },
				{ "<", ">", disable_start = true, disable_end = true },
				-- Paring '$' and '*' are handled by snippets,
				-- only use autopair to delete matched pairs here
				{ "$", "$", ft = { "markdown", "tex" }, disable_start = true, disable_end = true },
				{ "*", "*", ft = { "markdown" }, disable_start = true, disable_end = true },
				{ "\\left(", "\\right)", newline = true, space = true, ft = { "markdown", "tex" } },
				{ "\\left[", "\\right]", newline = true, space = true, ft = { "markdown", "tex" } },
				{ "\\left{", "\\right}", newline = true, space = true, ft = { "markdown", "tex" } },
				{ "\\left<", "\\right>", newline = true, space = true, ft = { "markdown", "tex" } },
				{ "\\left\\lfloor", "\\right\\rfloor", newline = true, space = true, ft = { "markdown", "tex" } },
				{ "\\left\\lceil", "\\right\\rceil", newline = true, space = true, ft = { "markdown", "tex" } },
				{ "\\left\\vert", "\\right\\vert", newline = true, space = true, ft = { "markdown", "tex" } },
				{ "\\left\\lVert", "\\right\\rVert", newline = true, space = true, ft = { "markdown", "tex" } },
				{ "\\left\\lVert", "\\right\\rVert", newline = true, space = true, ft = { "markdown", "tex" } },
				{ "\\begin{bmatrix}", "\\end{bmatrix}", newline = true, space = true, ft = { "markdown", "tex" } },
				{ "\\begin{pmatrix}", "\\end{pmatrix}", newline = true, space = true, ft = { "markdown", "tex" } },
			}
		end,
	},
	{
		"willothy/flatten.nvim",
		lazy = false,
		priority = 1001,
		opts = function()
			---Check if a file is a git (commit, rebase, etc.) file
			---@param fpath string
			---@return boolean
			local function should_block_file(fpath)
				fpath = vim.fs.normalize(fpath)
				return (
					fpath:find(".git/rebase-merge", 1, true)
					or fpath:find(".git/COMMIT_EDITMSG", 1, true)
					or fpath:find("^/tmp")
				)
						and true
					or false
			end

			if tonumber(vim.fn.system({ "id", "-u" })) == 0 then
				vim.env["NVIM_ROOT_" .. vim.fn.getpid()] = "1"
			end
			return {
				window = { open = "current" },
				callbacks = {
					-- Nest when child nvim is root but parent nvim (current session) is not
					-- to avoid opening files in current session without write permission
					should_nest = function()
						local pid = vim.fn.getpid()
						local parent_pid = vim.env.NVIM and vim.env.NVIM:match("nvim%.(%d+)")
						if vim.env["NVIM_ROOT_" .. pid] and parent_pid and not vim.env["NVIM_ROOT_" .. parent_pid] then
							return true
						end
					end,
					should_block = function()
						local files = vim.fn.argv() --[=[@as string[]]=]
						for _, file in ipairs(files) do
							if should_block_file(file) then
								return true
							end
						end
						return false
					end,
				},
				one_per = { kitty = false, wezterm = false },
			}
		end,
	},
	{
		"kylechui/nvim-surround",
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "BufReadPre",
		keys = {
			{ "<C-g>s", mode = "i" },
			{ "<C-g>S", mode = "i" },
			{ "S", mode = "x" },
			{ "gS", mode = "x" },
			"ys",
			"yss",
			"yS",
			"ySS",
			"ds",
			"cs",
			"cS",
		},
		opts = function()
			return {
				keymaps = {
					insert = "<C-g>s",
					insert_line = "<C-g>S",
					normal = "ys",
					normal_cur = "yss",
					normal_line = "yS",
					normal_cur_line = "ySS",
					visual = "S",
					visual_line = "gS",
					delete = "ds",
					change = "cs",
					change_line = "cS",
				},
			}
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		event = "BufReadPre",
		opts = {
			numhl = false,
			linehl = false,
			signs = {
				add = { text = "▎" },
				change = { text = "▎" },
				delete = { text = "" },
				topdelete = { text = "" },
				changedelete = { text = "▎" },
				untracked = { text = "▎" },
			},
			on_attach = function(buffer)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
				end

               -- stylua: ignore start
                map("n", "]h", function() gs.nav_hunk("next") end, "Next Hunk")
                map("n", "[h", function() gs.nav_hunk("prev") end, "Prev Hunk")
                map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
                map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
                map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
                map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
                map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
                map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
                map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
                map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
                map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
                map("n", "<leader>ghd", gs.diffthis, "Diff This")
                map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
                map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
				-- stylua: ignore end
			end,
		},
	},
	{
		"folke/trouble.nvim",
		cmd = { "TroubleToggle", "Trouble" },
		opts = { use_diagnostic_signs = true },
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
			{ "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
			{
				"<leader>cS",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP references/definitions/... (Trouble)",
			},
			{ "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
			{ "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
			{
				"[q",
				function()
					if require("trouble").is_open() then
						require("trouble").prev({ skip_groups = true, jump = true })
					else
						local ok, err = pcall(vim.cmd.cprev)
						if not ok then
							vim.notify(err, vim.log.levels.ERROR)
						end
					end
				end,
				desc = "Previous Trouble/Quickfix Item",
			},
			{
				"]q",
				function()
					if require("trouble").is_open() then
						require("trouble").next({ skip_groups = true, jump = true })
					else
						local ok, err = pcall(vim.cmd.cnext)
						if not ok then
							vim.notify(err, vim.log.levels.ERROR)
						end
					end
				end,
				desc = "Next Trouble/Quickfix Item",
			},
		},
	},
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		opts = {
			settings = {
				save_on_toggle = true,
				sync_on_ui_close = true,
				key = function()
					return vim.uv.cwd()
				end,
			},
		},
		keys = function()
			local harpoon = require("harpoon")
			local keys = {
				{
					"<leader>a",
					function()
						vim.notify("added to harpoon", 2, { title = "harpoon" })
						harpoon:list():add()
					end,
					desc = "Harpoon File",
				},
				{
					"<A-space>",
					function()
						harpoon.ui:toggle_quick_menu(harpoon:list(), { title = "", ui_max_width = 80 })
					end,
					desc = "Harpoon Quick Menu",
				},
				{
					"<space>l",
					function()
						local file_paths = {}
						for _, items in ipairs(harpoon:list().items) do
							table.insert(file_paths, items.value)
						end

						local filter_path = {}
						for idx = 1, #file_paths do
							if file_paths[idx] ~= "" then
								table.insert(filter_path, file_paths[idx])
							end
						end

						local actions = require("fzf-lua").actions
						require("fzf-lua").fzf_exec(file_paths, {
							prompt = "Harpoon> ",
							actions = {
								["default"] = actions.file_edit,
								["ctrl-s"] = actions.file_split,
								["ctrl-v"] = actions.file_vsplit,
								["ctrl-t"] = actions.file_tabedit,
								["ctrl-x"] = function(selected)
									for i = 1, #selected do
										harpoon:list():remove_at(i)
									end
								end,
							},
						})
					end,
					desc = "Fzf Harpoon",
				},
			}

			for i = 1, 9 do
				table.insert(keys, {
					"<leader>" .. i,
					function()
						harpoon:list():select(i)
					end,
					desc = "Harpoon to File " .. i,
				})
			end
			return keys
		end,
	},
}
