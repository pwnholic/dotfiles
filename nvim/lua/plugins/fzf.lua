return {
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

		local function add_to_harpoon(selected, opts)
			for i = 1, #selected do
				local file = fzf.path.entry_to_file(selected[i], opts)
				require("harpoon"):list():add({ value = file.bufname or file.path or file.uri, context = {} })
				vim.notify(string.format("Added to Harpoon %s", file.bufname or file.path or file.uri), 2)
			end
		end

		core.ACTION_DEFINITIONS[actions.toggle_ignore] = { "Disable .gitignore", fn_reload = "Respect .gitignore" }
		core.ACTION_DEFINITIONS[actions.toggle_hidden] = { "Disable dotfile", fn_reload = "Respect dotfile" }
		core.ACTION_DEFINITIONS[add_to_harpoon] = { "Add Harpoon" }
		core.ACTION_DEFINITIONS[actions.switch_cwd] = { "Change Cwd", pos = 1 }

		config._action_to_helpstr[actions.toggle_ignore] = "toggle-ignore"
		config._action_to_helpstr[actions.toggle_hidden] = "toggle-hidden"
		config._action_to_helpstr[add_to_harpoon] = "add-harpoon"
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
				split = [[
                        let tabpage_win_list = nvim_tabpage_list_wins(0) |
                        \ call v:lua.require'utils.win'.saveheights(tabpage_win_list) |
                        \ call v:lua.require'utils.win'.saveviews(tabpage_win_list) |
                        \ unlet tabpage_win_list |
                        \ let g:_fzf_vim_lines = &lines |
                        \ let g:_fzf_leave_win = win_getid(winnr()) |
                        \ botright 10new |
                        \ setlocal bt=nofile bh=wipe nobl noswf wfh
                    ]],
				on_create = function()
					vim.keymap.set(
						"t",
						"<C-r>",
						[['<C-\><C-N>"' . nr2char(getchar()) . 'pi']],
						{ expr = true, buffer = true }
					)
				end,
				on_close = function()
					if
						vim.g._fzf_leave_win
						and vim.api.nvim_win_is_valid(vim.g._fzf_leave_win)
						and vim.api.nvim_get_current_win() ~= vim.g._fzf_leave_win
					then
						vim.api.nvim_set_current_win(vim.g._fzf_leave_win)
					end
					vim.g._fzf_leave_win = nil

					if vim.go.lines == vim.g._fzf_vim_lines then
						utils.win.restheights()
					end
					vim.g._fzf_vim_lines = nil
					utils.win.clearheights()
					utils.win.restviews()
					utils.win.clearviews()
				end,
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
					["alt-m"] = add_to_harpoon,
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
								[[
                                        let tabpage_win_list = nvim_tabpage_list_wins(0) |
                                        \ call v:lua.require'utils.win'.saveheights(tabpage_win_list) |
                                        \ call v:lua.require'utils.win'.saveviews(tabpage_win_list) |
                                        \ unlet tabpage_win_list |
                                        \ let g:_fzf_vim_lines = &lines |
                                        \ let g:_fzf_leave_win = win_getid(winnr()) |
                                        \ botright %dnew |
                                        \ setlocal bt=nofile bh=wipe nobl noswf wfh
                                    ]],
								math.min(10 + vim.go.ch + (vim.go.ls == 0 and 0 or 1), #items + 1)
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
}
