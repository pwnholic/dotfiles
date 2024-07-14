return {
	{
		"ibhagwan/fzf-lua",
		cmd = "FzfLua",
		opts = function(_, opts)
			local config = require("fzf-lua.config")
			local actions = require("fzf-lua.actions")
			local path = require("fzf-lua.path")
			local core = require("fzf-lua.core")

			-- Quickfix
			config.defaults.keymap.fzf["ctrl-q"] = "select-all+accept"
			config.defaults.keymap.fzf["ctrl-u"] = "half-page-up"
			config.defaults.keymap.fzf["ctrl-d"] = "half-page-down"
			config.defaults.keymap.fzf["ctrl-x"] = "jump"
			config.defaults.keymap.fzf["ctrl-f"] = "preview-page-down"
			config.defaults.keymap.fzf["ctrl-b"] = "preview-page-up"
			config.defaults.keymap.builtin["<c-f>"] = "preview-page-down"
			config.defaults.keymap.builtin["<c-b>"] = "preview-page-up"

			-- Trouble
			if LazyVim.has("trouble.nvim") then
				config.defaults.actions.files["ctrl-t"] = require("trouble.sources.fzf").actions.open
			end

			-- Toggle root dir / cwd
			config.defaults.actions.files["ctrl-r"] = function(_, ctx)
				local o = vim.deepcopy(ctx.__call_opts)
				o.root = o.root == false
				o.cwd = nil
				o.buf = ctx.__CTX.bufnr
				LazyVim.pick.open(ctx.__INFO.cmd, o)
			end

			config.defaults.actions.files["alt-r"] = function()
				config.__resume_data.opts = config.__resume_data.opts or {}
				local o = config.__resume_data.opts

				-- Remove old fn_selected, else selected item will be opened
				-- with previous cwd
				o.fn_selected = nil
				o.cwd = o.cwd or vim.uv.cwd()
				o.query = config.__resume_data.last_query

				vim.ui.input({ prompt = "New cwd: ", default = o.cwd, completion = "dir" }, function(input)
					if not input then
						return
					end
					input = vim.fs.normalize(input)
					local stat = vim.uv.fs_stat(input)
					if not stat or not stat.type == "directory" then
						print("\n")
						vim.notify("[Fzf-lua] invalid path: " .. input .. "\n", vim.log.levels.ERROR)
						vim.cmd.redraw()
						return
					end
					o.cwd = input
				end)

				-- Adapted from fzf-lua `core.set_header()` function
				if o.cwd_prompt then
					o.prompt = vim.fn.fnamemodify(o.cwd, ":.:~")
					local shorten_len = tonumber(o.cwd_prompt_shorten_len)
					if shorten_len and #o.prompt >= shorten_len then
						o.prompt = path.shorten(o.prompt, tonumber(o.cwd_prompt_shorten_val) or 1)
					end
					if not path.ends_with_separator(o.prompt) then
						o.prompt = o.prompt .. path.separator()
					end
				end
				if o.headers then
					o = core.set_header(o, o.headers)
				end
				actions.resume()
			end

			core.ACTION_DEFINITIONS[config.defaults.actions.files["alt-r"]] = { "Change Cwd", pos = 1 }
			config.defaults.actions.files["alt-c"] = config.defaults.actions.files["ctrl-r"]
			config.set_action_helpstr(config.defaults.actions.files["ctrl-r"], "toggle-root-dir")
			config.set_action_helpstr(config.defaults.actions.files["alt-r"], "change-cwd")

			-- use the same prompt for all
			local defaults = require("fzf-lua.profiles.default-title")
			local function fix(t)
				t.prompt = t.prompt ~= nil and " " or nil
				for _, v in pairs(t) do
					if type(v) == "table" then
						fix(v)
					end
				end
			end
			fix(defaults)

			local img_previewer ---@type string[]?
			for _, v in ipairs({
				{ cmd = "ueberzug", args = {} },
				{ cmd = "chafa", args = { "{file}", "--format=symbols" } },
				{ cmd = "viu", args = { "-b" } },
			}) do
				if vim.fn.executable(v.cmd) == 1 then
					img_previewer = vim.list_extend({ v.cmd }, v.args)
					break
				end
			end

			return vim.tbl_deep_extend("force", defaults, {
				fzf_colors = true,
				fzf_opts = {
					["--no-scrollbar"] = true,
					["--info"] = "right",
					["--padding"] = "0,1",
					["--margin"] = "0",
					["--layout"] = "reverse",
					["--marker"] = "",
					["--pointer"] = "",
					["--border"] = "none",
					-- ["--no-preview"] = true,
					-- ["--preview-window"] = "hidden",
					["--ansi"] = true,
				},
				winopts = {
					split = [[ botright 10new | setlocal bt=nofile bh=wipe nobl noswf wfh ]],
					preview = { hidden = "hidden" },
				},
				defaults = {
					-- formatter = "path.filename_first",
					headers = { "actions", "cwd" },
					cwd_header = true,
					formatter = "path.dirname_first",
				},
				previewers = {
					builtin = {
						extensions = {
							["png"] = img_previewer,
							["jpg"] = img_previewer,
							["jpeg"] = img_previewer,
							["gif"] = img_previewer,
							["webp"] = img_previewer,
						},
						ueberzug_scaler = "fit_contain",
					},
				},
				-- Custom LazyVim option to configure vim.ui.select
				ui_select = function(fzf_opts, items)
					return vim.tbl_deep_extend("force", fzf_opts, {
						prompt = " ",
						winopts = {
							title = " " .. vim.trim((fzf_opts.prompt or "Select"):gsub("%s*:%s*$", "")) .. " ",
							title_pos = "center",
						},
					}, fzf_opts.kind == "codeaction" and {
						winopts = {
							layout = "vertical",
							-- height is number of items minus 15 lines for the preview, with a max of 80% screen height
							height = math.floor(math.min(vim.o.lines * 0.8 - 16, #items + 2) + 0.5) + 16,
							width = 0.5,
							preview = not vim.tbl_isempty(LazyVim.lsp.get_clients({ bufnr = 0, name = "vtsls" })) and {
								layout = "vertical",
								vertical = "down:15,border-top",
								hidden = "hidden",
							} or {
								layout = "vertical",
								vertical = "down:15,border-top",
							},
						},
					} or {
						winopts = {
							width = 0.5,
							-- height is number of items, with a max of 80% screen height
							height = math.floor(math.min(vim.o.lines * 0.8, #items + 2) + 0.5),
						},
					})
				end,
				files = {
					prompt = "Files❯ ",
					multiprocess = true,
					git_icons = false,
					file_icons = true,
					color_icons = true,
					-- path_shorten   = 1,              -- 'true' or number, shorten path?
					formatter = "path.filename_first",
					find_opts = [[-type f -type d -type l -not -path '*/\.git/*' -printf '%P\n']],
					fd_opts = [[--color=never --type f --type d --type l --follow --exclude .git]],
					rg_opts = [[--color=never --files --follow -g '!.git'"]],
					cwd_prompt = false,
					cwd_prompt_shorten_len = 32, -- shorten prompt beyond this length
					cwd_prompt_shorten_val = 1, -- shortened path parts length
					toggle_ignore_flag = "--no-ignore", -- flag toggled in `actions.toggle_ignore`
					toggle_hidden_flag = "--hidden", -- flag toggled in `actions.toggle_hidden`
					actions = {
						["alt-h"] = { actions.toggle_hidden },
					},
				},
				grep = {
					prompt = "Rg❯ ",
					input_prompt = "Grep For❯ ",
					multiprocess = true,
					git_icons = false,
					file_icons = true,
					color_icons = true,
					grep_opts = [[--binary-files=without-match --line-number --recursive --color=auto --perl-regexp -e]],
					rg_opts = [[--column --hidden --follow --line-number --no-heading --color=always --smart-case --max-columns=4096 -g=!git/ -e]],
					rg_glob = false, -- default to glob parsing?
					glob_flag = "--iglob", -- for case sensitive globs use '--glob'
					glob_separator = "%s%-%-", -- query separator pattern (lua): ' --'
					-- multiline = 1, -- Display as: PATH:LINE:COL\nTEXT\n
					no_header = false, -- hide grep|cwd header?
					no_header_i = false, -- hide interactive header?
					actions = {
						["alt-h"] = { actions.toggle_hidden },
					},
				},
				lsp = {
					symbols = {
						symbol_hl = function(s)
							return "TroubleIcon" .. s
						end,
						symbol_fmt = function(s)
							return s:lower() .. "\t"
						end,
						child_prefix = false,
					},
					code_actions = {
						previewer = vim.fn.executable("delta") == 1 and "codeaction_native" or nil,
					},
				},
			})
		end,
		config = function(_, opts)
			local fzf = require("fzf-lua")
			local enabled
			vim.keymap.set("n", "<leader>uz", function()
				enabled = not enabled
				if enabled then
					vim.notify("Enabled FZF Preview", 2, { title = "Fzflua" })
					return fzf.setup(vim.tbl_extend("force", opts, {
						winopts = {
							height = 0.70,
							width = 0.90,
							row = 0.50,
							col = 0.45,
							border = "single",
							fullscreen = false,
							preview = {
								border = "noborder",
								wrap = "nowrap",
								hidden = "nohidden",
								horizontal = "right:55%",
								layout = "flex",
								flip_columns = 120,
								title = false,
								scrollbar = false,
								delay = 100,
								winopts = {
									number = false,
									relativenumber = false,
									cursorline = false,
									cursorlineopt = "both",
									cursorcolumn = false,
									signcolumn = "no",
									list = false,
									foldenable = false,
								},
							},
						},
					}))
				else
					vim.notify("Disabled FZF preview", 2, { title = "Fzflua" })
					return fzf.setup(opts)
				end
			end, { desc = "Toggle FZF Preview" })
			fzf.setup(opts)
		end,
	},

	{
		"stevearc/oil.nvim",
		lazy = false,
		keys = { { "<leader>e", vim.cmd.Oil, desc = "Open Oil Buffer" } },
		opts = function()
			vim.g.loaded_fzf_file_explorer = 1
			vim.g.loaded_netrw = 1
			vim.g.loaded_netrwPlugin = 1

			local oil = require("oil")
			local icons = LazyVim.config.icons.kinds

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
				["file"] = "OilTypeFile",
				["directory"] = "OilTypeDir",
				["fifo"] = "OilTypeFifo",
				["link"] = "OilTypeLink",
				["socket"] = "OilTypeSocket",
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
				{ "size", highlight = "OilSize" },
				{ "mtime", highlight = "OilMtime" },
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
						local oildir = vim.fs.normalize(oil.get_current_dir(0))
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
}
