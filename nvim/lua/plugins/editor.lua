---@diagnostic disable: unused-local, undefined-field
return {
	{
		"ibhagwan/fzf-lua",
		cmd = "FzfLua",
		opts = function()
			local fzf = require("fzf-lua")
			local actions = require("fzf-lua.actions")
			local core = require("fzf-lua.core")
			local config = require("fzf-lua.config")
			local utils = require("utils")

			local _mt_cmd_wrapper = core.mt_cmd_wrapper

			---@param opts table?
			---@diagnostic disable-next-line: duplicate-set-field
			function core.mt_cmd_wrapper(opts)
				if not opts or not opts.cwd then
					return _mt_cmd_wrapper(opts)
				end
				local _opts = {}
				for k, v in pairs(opts) do
					_opts[k] = v
				end
				_opts.cwd = nil
				return _mt_cmd_wrapper(_opts)
			end

			---@return nil
			function actions.switch_cwd()
				fzf.config.__resume_data.opts = fzf.config.__resume_data.opts or {}
				local opts = fzf.config.__resume_data.opts
				-- Remove old fn_selected, else selected item will be opened
				-- with previous cwd
				opts.fn_selected = nil
				opts.cwd = opts.cwd or vim.uv.cwd()
				opts.query = fzf.config.__resume_data.last_query

				vim.ui.input({ prompt = "New cwd: ", default = opts.cwd, completion = "dir" }, function(input)
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
					opts.cwd = input
				end)
				if opts.headers then
					opts = core.set_header(opts, opts.headers)
				end
				actions.resume()
			end

			---Delete selected autocmd
			---@return nil
			function actions.del_autocmd(selected)
				for _, line in ipairs(selected) do
					local event, group, pattern = line:match("^.+:%d+:(%w+)%s*│%s*(%S+)%s*│%s*(.-)%s*│")
					if event and group and pattern then
						vim.cmd.autocmd({
							bang = true,
							args = { group, event, pattern },
							mods = { emsg_silent = true },
						})
					end
				end
				local query = fzf.config.__resume_data.last_query
				fzf.autocmds({ fzf_opts = { ["--query"] = query ~= "" and query or nil } })
			end

			local function _file_edit_or_qf(selected, opts)
				if #selected > 1 then
					for i = 1, #selected do
						local file = require("fzf-lua.path").entry_to_file(selected[i], opts)
						local stat = vim.uv.fs_stat(file.path)
						if stat and stat.type == "file" then
							require("trouble.sources.fzf").open(selected, opts)
						end
					end
				else
					return actions.file_edit(selected, opts)
				end
			end

			core.ACTION_DEFINITIONS[actions.toggle_ignore] = { "Disable .gitignore", fn_reload = "Respect .gitignore" }
			core.ACTION_DEFINITIONS[actions.toggle_hidden] = { "Disable dotfile", fn_reload = "Respect dotfile" }
			core.ACTION_DEFINITIONS[actions.switch_cwd] = { "Change Cwd", pos = 1 }

			config._action_to_helpstr[actions.toggle_ignore] = "toggle-ignore"
			config._action_to_helpstr[actions.toggle_hidden] = "toggle-hidden"
			config._action_to_helpstr[actions.switch_cwd] = "change-cwd"
			config._action_to_helpstr[actions.del_autocmd] = "delete-autocmd"

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

			return {
				winopts = {
					backdrop = 100,
					split = "botright 10new | setlocal bt=nofile bh=wipe nobl noswf wfh",
					preview = { hidden = "hidden" },
				},
				file_icon_padding = " ",
				defaults = {
					-- formatter = "path.filename_first",
					file_icons = "mini",
					headers = { "actions", "cwd" },
					cwd_header = true,
					formatter = "path.dirname_first",
				},
				fzf_colors = true,
				keymap = {
					builtin = {
						["<Esc><Esc>"] = "hide",
						["<F1>"] = "toggle-help",
						["<F2>"] = "toggle-fullscreen",
						["<F3>"] = "toggle-preview-wrap",
						["<F4>"] = "toggle-preview",
						["<F5>"] = "toggle-preview-ccw",
						["<F6>"] = "toggle-preview-cw",
						["<S-down>"] = "preview-page-down",
						["<S-up>"] = "preview-page-up",
						["<M-S-down>"] = "preview-down",
						["<M-S-up>"] = "preview-up",
					},
					fzf = {
						["ctrl-z"] = "abort",
						["ctrl-u"] = "unix-line-discard",
						["ctrl-f"] = "half-page-down",
						["ctrl-b"] = "half-page-up",
						["ctrl-a"] = "beginning-of-line",
						["ctrl-e"] = "end-of-line",
						["alt-a"] = "toggle-all",
						["alt-g"] = "last",
						["alt-G"] = "first",
						["f3"] = "toggle-preview-wrap",
						["f4"] = "toggle-preview",
						["shift-down"] = "preview-page-down",
						["shift-up"] = "preview-page-up",
					},
				},
				fzf_opts = {
					["--no-scrollbar"] = true,
					-- ["--no-separator"] = true,
					["--info"] = "inline-right",
					["--layout"] = "reverse",
					["--marker"] = "󰐃 ",
					["--pointer"] = "󰅂 ",
					["--border"] = "none",
					["--padding"] = "0,1",
					["--margin"] = "0",
					["--no-preview"] = true,
					["--highlight-line"] = true,
					["--preview-window"] = "hidden",
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
					codeaction_native = {
						diff_opts = { ctxlen = 3 },
						pager = [[delta --width=$COLUMNS --hunk-header-style="omit" --file-style="omit"]],
					},
				},
				actions = {
					files = {
						["enter"] = _file_edit_or_qf,
						["ctrl-s"] = actions.file_split,
						["alt-o"] = actions.toggle_hidden,
						["ctrl-v"] = actions.file_vsplit,
						["alt-q"] = actions.file_sel_to_qf,
						["alt-g"] = actions.switch_cwd,
					},
					grep = {
						["enter"] = _file_edit_or_qf,
						["ctrl-s"] = actions.file_split,
						["ctrl-v"] = actions.file_vsplit,
						["alt-o"] = actions.toggle_hidden,
						["alt-q"] = actions.file_sel_to_qf,
						["alt-g"] = actions.switch_cwd,
					},
					buffers = {
						["enter"] = actions.buf_edit,
						["ctrl-s"] = actions.buf_split,
						["ctrl-v"] = actions.buf_vsplit,
						["ctrl-x"] = { fn = actions.buf_del, reload = true },
					},
					git = {
						commits = {
							["enter"] = actions.git_checkout,
							["ctrl-y"] = { fn = actions.git_yank_commit, exec_silent = true },
						},
						bcommits = {
							["enter"] = actions.git_buf_edit,
							["ctrl-s"] = actions.git_buf_split,
							["ctrl-v"] = actions.git_buf_vsplit,
							["ctrl-y"] = { fn = actions.git_yank_commit, exec_silent = true },
						},
						branches = {
							["enter"] = actions.git_switch,
							["ctrl-x"] = { fn = actions.git_branch_del, reload = true },
							["ctrl-a"] = { fn = actions.git_branch_add, field_index = "{q}", reload = true },
						},
					},
				},
				files = {
					prompt = "Files❯ ",
					multiprocess = true,
					git_icons = false,
					file_icons = "mini",
					color_icons = true,
					-- path_shorten   = 1,
					formatter = "path.filename_first",
					find_opts = [[-type f -type d -type l -not -path '*/\.git/*' -printf '%P\n']],
					fd_opts = [[--color=never --type f --type d --type l --follow --exclude .git]],
					rg_opts = [[--color=never --files --follow -g '!.git'"]],
					cwd_prompt = false,
					cwd_prompt_shorten_len = 32,
					cwd_prompt_shorten_val = 1,
					toggle_ignore_flag = "--no-ignore",
					toggle_hidden_flag = "--hidden",
				},
				grep = {
					prompt = "Rg❯ ",
					input_prompt = "Grep For❯ ",
					multiprocess = true,
					git_icons = false,
					file_icons = "mini",
					color_icons = true,
					grep_opts = [[--binary-files=without-match --line-number --recursive --color=auto --perl-regexp -e]],
					rg_opts = [[--column --hidden --follow --line-number --no-heading --color=always --smart-case --max-columns=4096 -g=!git/ -e]],
					rg_glob = true,
					glob_flag = "--iglob",
					glob_separator = "%s%-%-",
					-- multiline = 1, -- Display as: PATH:LINE:COL\nTEXT\n
					no_header = false,
					no_header_i = false,
				},
				oldfiles = {
					prompt = "History❯ ",
					cwd_only = false,
					stat_file = require("fzf-lua").utils.file_is_readable,
					include_current_session = false, -- include bufs from current session
				},
				buffers = {
					prompt = "Buffers❯ ",
					show_unlisted = true,
					show_unloaded = true,
					ignore_current_buffer = false,
					no_action_set_cursor = true,
					current_tab_only = false,
					no_term_buffers = false,
					cwd_only = false,
					ls_cmd = "ls",
				},
				keymaps = {
					prompt = "Keymaps> ",
					winopts = { preview = { layout = "vertical" } },
					fzf_opts = { ["--tiebreak"] = "index" },
					ignore_patterns = { "^<SNR>", "^<Plug>" },
				},
				lsp = {
					-- async_or_timeout = 3000,
					symbols = {
						symbol_icons = utils.icons.kinds,
						symbol_hl = function(s)
							return "TroubleIcon" .. s
						end,
						symbol_fmt = function(s)
							return s:lower() .. "\t"
						end,
						child_prefix = false,
					},
					code_actions = {
						previewer = vim.fn.executable("delta") == 1 and "codeaction_native",
					},
				},
				diagnostics = {
					prompt = "Diagnostics❯ ",
					cwd_only = false,
					file_icons = true,
					git_icons = false,
					diag_icons = true,
					diag_source = true,
					icon_padding = " ",
					multiline = true,
					signs = {
						["Error"] = { text = utils.icons.diagnostics.ERROR, texthl = "DiagnosticError" },
						["Warn"] = { text = utils.icons.diagnostics.WARN, texthl = "DiagnosticWarn" },
						["Info"] = { text = utils.icons.diagnostics.INFO, texthl = "DiagnosticInfo" },
						["Hint"] = { text = utils.icons.diagnostics.HINT, texthl = "DiagnosticHint" },
					},
				},
				git = {
					files = {
						prompt = "GitFiles❯ ",
						cmd = "git ls-files --exclude-standard",
						multiprocess = true,
						git_icons = true,
						file_icons = "mini",
						color_icons = true,
						cwd_header = true,
					},
					icons = {
						["M"] = { icon = utils.icons.git.modified, color = "yellow" },
						["D"] = { icon = utils.icons.git.remove, color = "red" },
						["A"] = { icon = utils.icons.git.add, color = "green" },
						["R"] = { icon = utils.icons.git.rename, color = "yellow" },
						["C"] = { icon = utils.icons.git.change, color = "yellow" },
						["T"] = { icon = utils.icons.git.task, color = "magenta" },
						["?"] = { icon = utils.icons.git.qmark, color = "magenta" },
					},
				},
			}
		end,
		config = function(_, opts)
			require("fzf-lua").setup(opts)

			local enabled = true
			vim.keymap.set("n", "<leader>uz", function()
				enabled = not enabled
				if enabled then
					require("fzf-lua").setup(opts)
					vim.notify("Disabled Preview", 2, { title = "Fzflua" })
				else
					require("fzf-lua").setup(vim.tbl_extend("force", opts, {
						winopts = {
							height = 0.85,
							width = 0.90,
							row = 0.40,
							col = 0.50,
							border = "single",
							fullscreen = false,
							preview = {
								border = "noborder",
								wrap = "nowrap",
								hidden = "nohidden",
								vertical = "down:45%",
								horizontal = "right:55%",
								winopts = {
									number = false,
									relativenumber = false,
									signcolumn = "no",
									list = false,
									foldenable = false,
									foldmethod = "manual",
								},
							},
						},
						fzf_opts = {
							["--ansi"] = true,
							["--info"] = "inline-right",
							["--height"] = "100%",
							["--layout"] = "reverse",
							["--highlight-line"] = true,
						},
					}))
					vim.notify("Enabled Preview", 2, { title = "Fzflua" })
				end
			end, { desc = "Toggle FzF Preview" })
		end,
		init = vim.schedule_wrap(function()
			---@diagnostic disable-next-line: duplicate-set-field
			vim.ui.select = function(...)
				local fzf_ui = require("fzf-lua.providers.ui_select")
				if not fzf_ui.is_registered() then
					local _ui_select = fzf_ui.ui_select
					---@diagnostic disable-next-line: duplicate-set-field
					fzf_ui.ui_select = function(items, opts, on_choice)
						opts.prompt = opts.prompt and vim.fn.substitute(opts.prompt, ":\\?\\s*$", ":\xc2\xa0", "")
						_ui_select(items, opts, on_choice)
					end
					fzf_ui.register(function(_, items)
						return {
							winopts = {
								split = string.format(
									"botright %dnew | setlocal bt=nofile bh=wipe nobl noswf wfh",
									math.min(10 + vim.go.ch + (vim.go.ls == 0 and 0 or 2), #items + 2)
								),
							},
						}
					end)
				end
				vim.ui.select(...)
			end
		end),
		keys = function()
			return {
				-- SEARCH
				{ "<leader>s/", "<cmd>FzfLua grep<cr>", desc = "Grep" },
				{ "<leader>sS", "<cmd>FzfLua grep_last<cr>", desc = "Grep Last" },
				{ "<leader>sc", "<cmd>FzfLua grep_cword<cr>", desc = "Grep Current Word" },
				{ "<leader>sv", "<cmd>FzfLua grep_visual<cr>", desc = "Grep Visual", mode = "x" },
				{ "<leader>s.", "<cmd>FzfLua grep_curbuf<cr>", desc = "Grep Current Buf" },
				{ "<leader>s,", "<cmd>FzfLua lgrep_curbuf<cr>", desc = "LGrep Current Buf" },
				{ "<leader>sg", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep" },
				{ "<leader>sr", "<cmd>FzfLua live_grep_resume<cr>", desc = "LGrep Resume" },
				{ "<leader>sG", "<cmd>FzfLua live_grep_glob<cr>", desc = ">Lgrep Glob" },
				{ "<leader>sn", "<cmd>FzfLua live_grep_native<cr>", desc = "LGrep Native" },

				-- TAGS
				{ "<leader>st", "<cmd>FzfLua tags<cr>", desc = "Tags" },
				{ "<leader>sT", "<cmd>FzfLua tags_grep<cr>", desc = "Tags Grep" },
				{ "<leader>ss", "<cmd>FzfLua tags_live_grep<cr>", desc = "Tags LGrep" },

				-- GIT
				{ "<leader>hf", "<cmd>FzfLua git_files<cr>", desc = "FzF Files" },
				{ "<leader>hs", "<cmd>FzfLua git_status<cr>", desc = "FzF Status" },
				{ "<leader>hc", "<cmd>FzfLua git_commits<cr>", desc = "FzF Commit" },
				{ "<leader>hb", "<cmd>FzfLua git_bcommits<cr>", desc = "FzF Bcommit" },
				{ "<leader>hB", "<cmd>FzfLua git_branches<cr>", desc = "FzF Branches" },
				{ "<leader>ht", "<cmd>FzfLua git_tags<cr>", desc = "FzF Tags" },
				{ "<leader>hS", "<cmd>FzfLua git_stash<cr>", desc = "FzF Statsh" },

				-- DAP
				{ "<leader>dfx", "<cmd>FzfLua dap_commands<cr>", desc = "Dap Commend" },
				{ "<leader>dfc", "<cmd>FzfLua dap_configurations<cr>", desc = "Dap Conf" },
				{ "<leader>dfb", "<cmd>FzfLua dap_breakpoints<cr>", desc = "Dap Breakpoint" },
				{ "<leader>dfv", "<cmd>FzfLua dap_variables<cr>", desc = "Dap Variable" },
				{ "<leader>dff", "<cmd>FzfLua dap_frames<cr>", desc = "Dap Frame" },

				-- BUFFER and FILES
				{ "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
				{ "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Files" },
				{ "<leader>fo", "<cmd>FzfLua oldfiles<cr>", desc = "Oldfiles" },
				{ "<leader>fq", "<cmd>FzfLua quickfix<cr>", desc = "Qf" },
				{ "<leader>fQ", "<cmd>FzfLua loclist<cr>", desc = "Loclist" },
				{ "<leader>fl", "<cmd>FzfLua lines<cr>", desc = "Lines" },
				{ "<leader>fL", "<cmd>FzfLua blines<cr>", desc = "Blines" },
				{ "<leader>ft", "<cmd>FzfLua tabs<cr>", desc = "Tabs" },
				{ "<leader>fA", "<cmd>FzfLua args<cr>", desc = "Args" },

				-- MICS
				{ "<leader>fr ", "<cmd>FzfLua resume<cr>", desc = "Resume Stuff" },
				{ "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "Help" },
				{ "<leader>fC", "<cmd>FzfLua awesome_colorschemes<cr>", desc = "Awesome Colorscheme" },
				{ "<leader>fH", "<cmd>FzfLua highlights<cr>", desc = "Highlight" },
				{ "<leader>fx", "<cmd>FzfLua command_history<cr>", desc = "Command History" },
				{ "<leader>fS", "<cmd>FzfLua search_history<cr>", desc = "Search History" },
				{ "<leader>fm", "<cmd>FzfLua marks<cr>", desc = "Marks" },
				{ "<leader>fj", "<cmd>FzfLua jumps<cr>", desc = "Jumps" },
				{ "<leader>fc", "<cmd>FzfLua changes<cr>", desc = "Change" },
				{ "<leader>fR", "<cmd>FzfLua registers<cr>", desc = "Registers" },
				{ "<leader>fa", "<cmd>FzfLua autocmds<cr>", desc = "Autocmds" },
				{ "<leader>fk", "<cmd>FzfLua keymaps<cr>", desc = "Keymaps" },
				{ "<leader>fp", "<cmd>FzfLua spell_suggest<cr>", desc = "Spell Suggest" },
			}
		end,
	},
	{
		"stevearc/oil.nvim",
		cmd = "Oil",
		keys = { { "<leader>e", vim.cmd.Oil, desc = "Open Oil Buffer" } },
		lazy = false,
		init = vim.schedule_wrap(function()
			vim.api.nvim_create_autocmd("BufWinEnter", {
				nested = true,
				callback = function(info)
					local path = info.file
					if path == "" then
						return
					end
					local stat = vim.uv.fs_stat(path)
					if stat and stat.type == "directory" then
						vim.api.nvim_del_autocmd(info.id)
						require("oil")
						vim.cmd.edit({ bang = true, mods = { keepjumps = true } })
						return true
					end
				end,
			})
		end),
		opts = function()
			local oil = require("oil")
			local icons = require("utils.icons").kinds

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
			---@param height integer @param width integer @return string[]
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
				{ "icon", default_file = icons.File, directory = icons.Folder, add_padding = true },
			}

			return {
				default_file_explorer = true,
				columns = { { "icon", default_file = icons.File, directory = icons.Folder, add_padding = true } },
				buf_options = { buflisted = false, bufhidden = "hide" },
				win_options = {
					wrap = false,
					signcolumn = "no",
					cursorcolumn = false,
					foldcolumn = "0",
					spell = false,
					number = false,
					relativenumber = false,
					list = false,
					conceallevel = 3,
					concealcursor = "nvic",
					winbar = "",
				},
				delete_to_trash = true,
				skip_confirm_for_simple_edits = false,
				prompt_save_on_select_new_entry = true,
				cleanup_delay_ms = false,
				lsp_file_methods = { timeout_ms = 1000, autosave_changes = false },
				constrain_cursor = "name",
				watch_for_changes = true,
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
				use_default_keymaps = false,
				view_options = {
					show_hidden = false,
					is_hidden_file = function(name, bufnr)
						return vim.startswith(name, ".")
					end,
					is_always_hidden = function(name, bufnr)
						return false
					end,
					natural_order = true,
					case_insensitive = false,
					sort = { { "type", "asc" }, { "name", "asc" } },
				},
				progress = {
					max_width = 0.7,
					border = "rounded",
					minimized_border = "none",
					win_options = { winblend = 0 },
				},
				ssh = { border = "rounded" },
				keymaps_help = { border = "rounded" },
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

	{
		"lewis6991/gitsigns.nvim",
		event = "VeryLazy",
		opts = function()
			local icons = require("utils.icons").misc
			return {
				signs = {
					add = { text = icons.vertical_bar_bold },
					change = { text = icons.vertical_bar_bold },
					delete = { text = icons.vertical_bar_bold },
					topdelete = { text = icons.vertical_bar_bold },
					changedelete = { text = icons.vertical_bar_bold },
					untracked = { text = icons.vertical_bar_bold },
				},
				signs_staged = {
					add = { text = icons.vertical_bar_bold },
					change = { text = icons.vertical_bar_bold },
					delete = { text = icons.vertical_bar_bold },
					topdelete = { text = icons.vertical_bar_bold },
					changedelete = { text = icons.vertical_bar_bold },
				},
				on_attach = function(buffer)
					local gs = package.loaded.gitsigns

					local function map(mode, l, r, desc)
						vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
					end

                    -- stylua: ignore start
					map("n", "]h", function() if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end end, "Next Hunk")
					map("n", "[h", function() if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end end, "Prev Hunk")
					map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk") map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
					map({ "n", "v" }, "<leader>hA", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
					map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
					map("n", "<leader>ha", gs.stage_buffer, "Stage Buffer")
					map("n", "<leader>hu", gs.undo_stage_hunk, "Undo Stage Hunk")
					map("n", "<leader>hR", gs.reset_buffer, "Reset Buffer")
					map("n", "<leader>hp", gs.preview_hunk_inline, "Preview Hunk Inline")
					map("n", "<leader>hB", function() gs.blame_line({ full = true }) end, "Blame Line") map("n", "<leader>hB", function() gs.blame() end, "Blame Buffer")
					map("n", "<leader>hd", gs.diffthis, "Diff This") map("n", "<leader>hD", function() gs.diffthis("~") end, "Diff This ~")
					map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
					-- stylua: ignore end
				end,
			}
		end,
	},

	{
		"kylechui/nvim-surround",
		event = "BufRead",
		keys = function()
			return {
				"ys",
				"ds",
				"cs",
				{ "S", mode = "x" },
				{ "<C-g>s", mode = "i" },
			}
		end,
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
		"altermo/ultimate-autopair.nvim",
		event = "InsertEnter",
		opts = function()
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
					suround = false,
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
		priority = 1000,
		opts = function()
			---Check if a file is a git (commit, rebase, etc.) file
			---@param fpath string
			---@return boolean
			local function should_block_file(fpath)
				local fname = vim.fs.basename(fpath)
				return fname == "rebase-merge"
					or fname == "COMMIT_EDITMSG"
					or vim.startswith(vim.fs.normalize(fpath), "/tmp/")
			end

			if tonumber(vim.fn.system({ "id", "-u" })) == 0 then
				vim.env["NVIM_ROOT_" .. vim.fn.getpid()] = "1"
			end
			return {
				window = { open = "alternate" },
				block_for = { gitcommit = true, gitrebase = true },
				callbacks = {
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
					post_open = function(buf, win)
						vim.api.nvim_set_current_win(win)
						local bufname = vim.api.nvim_buf_get_name(buf)
						if should_block_file(bufname) then
							vim.bo[buf].bufhidden = "wipe"
							local keymap_utils = require("utils.keys")
							keymap_utils.command_abbrev("x", "b#", { buffer = buf })
							keymap_utils.command_abbrev("wq", "b#", { buffer = buf })
							keymap_utils.command_abbrev("bw", "b#", { buffer = buf })
							keymap_utils.command_abbrev("bd", "b#", { buffer = buf })
						end
					end,
				},
				one_per = { kitty = false, wezterm = false },
			}
		end,
	},
	{
		"RRethy/vim-illuminate",
		event = "BufRead",
		opts = function()
			return {
				delay = 0,
				providers = { "lsp", "treesitter", "regex" },
				large_file_cutoff = 2000,
				filetypes_denylist = {
					"oil",
					"harpoon",
				},
				modes_denylist = { "i", "v", "vs", "V", "Vs", "\22", "\22s" },
				large_file_overrides = { providers = { "lsp" } },
			}
		end,
		config = function(_, opts)
			require("illuminate").configure(opts)
		end,
	},
	{
		"echasnovski/mini-git",
		main = "mini.git",
		cmd = "Git",
		keys = function()
			return {
				{
					"<leader>hg",
					function()
						vim.ui.input({ prompt = "Git Options : ", completion = "command" }, function(args)
							if args == "" then
								return vim.notify("Git need argument", 4, { title = "Git" })
							else
								vim.cmd.Git(args)
							end
						end)
					end,
					desc = "Git Wrapper",
				},
			}
		end,
		opts = function()
			return {
				job = { git_executable = "git", timeout = 30000 },
				command = { split = "auto" },
			}
		end,
	},
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = function()
			return { modes = { lsp = { win = { position = "right" } } } }
		end,
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
			{ "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols (Trouble)" },
			{ "<leader>xS", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references/definitions/... (Trouble)" },
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
		keys = function()
			return {
                -- stylua: ignore start
				{ "<leader><leader>", function() require("harpoon").ui:toggle_quick_menu( require("harpoon"):list(), { ui_width_ratio = 0.40, border = "single", title = "" }) end, desc = "Harpoon List", },
				{ "<leader>l", function() require("harpoon").ui:toggle_quick_menu( require("harpoon"):list(), { ui_width_ratio = 0.40, border = "single", title = "" }) end, desc = "Harpoon List", },
				{ "<leader>a", function() vim.notify("Add to Mark", 2) require("harpoon"):list():add() end, desc = "Add to Mark", },
				{ "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Mark 1" },
				{ "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Mark 2" },
				{ "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Mark 3" },
				{ "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Mark 4" },
				{ "<leader>5", function() require("harpoon"):list():select(5) end, desc = "Mark 5" },
				-- stylua: ignore end
			}
		end,
		config = function()
			local harpoon = require("harpoon")
			require("harpoon.config").DEFAULT_LIST = "files"
			harpoon:setup({
				settings = {
					save_on_toggle = true,
					key = function()
						return vim.uv.cwd() --[[@as string]]
					end,
				},
			})
			harpoon:extend({
				UI_CREATE = function(cx)
					vim.keymap.set("n", "<C-v>", function()
						harpoon.ui:select_menu_item({ vsplit = true })
					end, { buffer = cx.bufnr })
					vim.keymap.set("n", "<C-s>", function()
						harpoon.ui:select_menu_item({ split = true })
					end, { buffer = cx.bufnr })
					vim.keymap.set("n", "<C-t>", function()
						harpoon.ui:select_menu_item({ tabedit = true })
					end, { buffer = cx.bufnr })
				end,
			})
		end,
	},
	{
		"3rd/image.nvim",
		ft = { "markdown", "neorg" },
		-- build = "luarocks --local --lua-version=5.1 install magick --force",
		init = vim.schedule_wrap(function()
			package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua"
			package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua"
		end),
		opts = function()
			return {
				backend = "kitty",
				integrations = {
					markdown = {
						enabled = true,
						clear_in_insert_mode = false,
						download_remote_images = false,
						only_render_image_at_cursor = false,
						filetypes = { "markdown", "vimwiki" },
					},
				},
			}
		end,
	},

	{
		"Bekaboo/deadcolumn.nvim",
		event = "BufRead",
		opts = function()
			return {
				scope = "line",
				modes = function(mode)
					return mode:find("^[ictRss\x13]") ~= nil
				end,
				blending = {
					threshold = 0.75,
					colorcode = "#000000",
					hlgroup = { "Normal", "bg" },
				},
				warning = {
					alpha = 0.4,
					offset = 0,
					colorcode = "#FF0000",
					hlgroup = { "Error", "bg" },
				},
				extra = { follow_tw = nil },
			}
		end,
	},

	{
		"isakbm/gitgraph.nvim",
		opts = function()
			return {
				format = {
					timestamp = "%H:%M:%S %d-%m-%Y",
					fields = { "hash", "timestamp", "author", "branch_name", "tag" },
				},
				hooks = {
					on_select_commit = function(commit)
						vim.cmd.Git(string.format("diff %s", commit.hash))
						vim.notify(string.format("Commit hash %s selected", commit.hash), 2, { title = "GitGraph" })
					end,
					on_select_range_commit = function(from, to)
						vim.cmd.Git(string.format("diff %s..%s", from.hash, to.hash))
						vim.notify(
							string.format("Commit hash form %s to %s selected", from.hash, to.hash),
							2,
							{ title = "GitGraph" }
						)
					end,
				},
			}
		end,
		keys = function()
			return {
				{
					"<leader>hl",
					function()
						require("gitgraph").draw({}, { all = true, max_count = 5000 })
					end,
					desc = "GitGraph",
				},
			}
		end,
	},
	{
		"folke/flash.nvim",
		event = "BufRead",
		opts = function()
			return {
				jump = { nohlsearch = true },
				prompt = { win_config = { row = -3 } },
				modes = { search = { enabled = true } },
				search = {
					exclude = {
						"cmp_menu",
						"flash_prompt",
						"qf",
						function(win)
							if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)):match("BqfPreview") then
								return true
							end
							return not vim.api.nvim_win_get_config(win).focusable
						end,
					},
				},
			}
		end,
		keys = function()
			return {
            -- stylua: ignore start
			{ "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash", },
			{ "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter", },
			{ "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash", },
			{ "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search", },
			{ "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
				-- stylua: ignore end
			}
		end,
	},
}
