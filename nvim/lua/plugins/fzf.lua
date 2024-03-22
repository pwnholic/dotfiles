local ignore_folder = table.concat(require("directory").ignore_folder, ",")
local ignore_file = table.concat(require("directory").ignore_file, ",")
local fmt = string.format

local no_preview_fzf_opts = {
	["--no-scrollbar"] = true,
	["--info"] = "right",
	["--padding"] = "0,1",
	["--margin"] = "0",
	["--layout"] = "reverse",
	["--marker"] = "",
	["--pointer"] = "",
	["--border"] = "none",
	["--no-preview"] = true,
	["--preview-window"] = "hidden",
	["--ansi"] = true,
}

return {
	"ibhagwan/fzf-lua",
	branch = "main",
	cmd = "FzfLua",
	init = function()
		vim.ui.select = function(...)
			local fzf_ui = require("fzf-lua.providers.ui_select")
			if not fzf_ui.is_registered() then
				local _ui_select = fzf_ui.ui_select
				fzf_ui.ui_select = function(items, opts, on_choice)
					opts.prompt = opts.prompt and vim.fn.substitute(opts.prompt, ":\\?\\s*$", ":\xc2\xa0", "")
					_ui_select(items, opts, on_choice)
				end
				fzf_ui.register(function(_, items)
					return {
						winopts = {
							split = fmt(
								"botright %dnew",
								math.min(10 + vim.go.ch + (vim.go.ls == 0 and 0 or 1), #items + 2)
							),
						},
						fzf_opts = no_preview_fzf_opts,
					}
				end)
			end
			return vim.ui.select(...)
		end
	end,
	config = function()
		local fzf, fzf_actions = require("fzf-lua"), require("fzf-lua.actions")
		local icons, fzf_config = require("icons"), require("fzf-lua.config")
		local fzf_core, fzf_path = require("fzf-lua.core"), require("fzf-lua.path")
		local fzf_utils = require("fzf-lua.utils")

		local _mt_cmd_wrapper = fzf_core.mt_cmd_wrapper

		---@param opts table?
		function fzf_core.mt_cmd_wrapper(opts)
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

		local function select_to_qf(selected, opts, is_loclist)
			local qf_list = {}
			for i = 1, #selected do
				local entry_file = fzf_path.entry_to_file(selected[i], opts)
				table.insert(qf_list, {
					filename = entry_file.bufname or entry_file.path,
					lnum = entry_file.line,
					col = entry_file.col,
					text = selected[i]:match(":%d+:%d?%d?%d?%d?:?(.*)$"),
				})
			end
			local title = fmt(
				"[FzfLua] %s%s",
				opts.__INFO and opts.__INFO.cmd .. ": " or "",
				fzf_utils.resume_get("query", opts) or ""
			)
			if is_loclist then
				vim.fn.setloclist(0, {}, " ", { nr = "$", items = qf_list, title = title })
				if type(opts.lopen) == "function" then
					opts.lopen(selected, opts)
				elseif opts.lopen ~= false then
					return require("trouble").toggle("loclist")
				end
			else
				vim.fn.setqflist({}, " ", { nr = "$", items = qf_list, title = title })
				if type(opts.copen) == "function" then
					opts.copen(selected, opts)
				elseif opts.copen ~= false then
					return require("trouble").toggle("quickfix")
				end
			end
		end

		function fzf_actions.buf_edit_or_qf(selected, opts)
			if #selected > 1 then
				return select_to_qf(selected, opts)
			else
				return fzf_actions.file_edit(selected, opts)
			end
		end

		function fzf_actions.switch_provider()
			local opts = { query = fzf_config.__resume_data.last_query, cwd = fzf_config.__resume_data.opts.cwd }
			fzf.builtin({
				actions = {
					["default"] = function(selected)
						fzf[selected[1]](opts)
					end,
					["esc"] = fzf_actions.resume,
				},
			})
		end

		---Switch cwd while preserving the last query
		function fzf_actions.switch_cwd()
			fzf_config.__resume_data.opts = fzf_config.__resume_data.opts or {}
			local opts = fzf_config.__resume_data.opts
			opts.fn_selected = nil
			opts.cwd = (opts.cwd or vim.uv.cwd())
			opts.query = fzf_config.__resume_data.last_query
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

			-- Adapted from fzf-lua `core.set_header()` function
			-- if opts.cwd_prompt then
			-- 	opts.prompt = vim.fn.fnamemodify(opts.cwd, ":.:~")
			-- 	local shorten_len = tonumber(opts.cwd_prompt_shorten_len)
			-- 	if shorten_len and #opts.prompt >= shorten_len then
			-- 		opts.prompt = fzf_path.shorten(opts.prompt, tonumber(opts.cwd_prompt_shorten_val) or 1)
			-- 	end
			-- 	if not fzf_path.ends_with_separator(opts.prompt) then
			-- 		opts.prompt = opts.prompt .. fzf_path.separator()
			-- 	end
			-- end
			if opts.headers then
				opts = fzf_core.set_header(opts, opts.headers)
			end
			fzf_actions.resume()
			vim.notify(fmt("switch to %s", opts.cwd), 2)
		end

		function fzf_actions.del_autocmd(selected)
			for _, line in ipairs(selected) do
				local event, group, pattern = line:match("^.+:%d+:(%w+)%s*│%s*(%S+)%s*│%s*(.-)%s*│")
				if event and group and pattern then
					vim.cmd.autocmd({ bang = true, args = { group, event, pattern }, mods = { emsg_silent = true } })
				end
			end
			local last_query = fzf_config.__resume_data.last_query or ""
			fzf.autocmds({ fzf_opts = { ["--query"] = vim.fn.shellescape(last_query) } })
		end

		local _diagnostics_document = fzf.diagnostics_document
		function fzf.diagnostics_document(opts)
			return _diagnostics_document(vim.tbl_extend("force", opts or {}, { prompt = "Document Diagnostics> " }))
		end
		local _diagnostics_workspace = fzf.diagnostics_workspace
		function fzf.diagnostics_workspace(opts)
			return _diagnostics_workspace(vim.tbl_extend("force", opts or {}, { prompt = "Workspace Diagnostics> " }))
		end

		fzf_actions.arg_add = function(selected, opts)
			fzf_actions.vimcmd_file("argadd", selected, opts)
			vim.notify("added to args list", 2, { title = "Arg Add" })
		end

		function fzf_actions.arg_search_add()
			local opts = fzf_config.__resume_data.opts
			fzf.files({
				cwd_header = true,
				cwd_prompt = false,
				headers = { "actions", "cwd" },
				prompt = "Argadd> ",
				actions = {
					["default"] = function(selected, _opts)
						local cmd = "argadd"
						vim.ui.input({ prompt = "Argadd cmd: ", default = cmd }, function(input)
							if input then
								cmd = input
							end
						end)
						fzf_actions.vimcmd_file(cmd, selected, _opts)
						fzf.args(opts)
					end,
					["esc"] = function()
						fzf.args(opts)
					end,
				},
				find_opts = [[-type f -type d -type l -not -path '*/\.git/*' -printf '%P\n']],
				fd_opts = [[--color=never --type f --type d --type l --hidden --follow --exclude .git]],
				rg_opts = [[--color=never --files --hidden --follow -g '!.git'"]],
			})
		end

		fzf_core.ACTION_DEFINITIONS[fzf_actions.toggle_ignore] = {
			function(opts)
				local flag = opts.toggle_ignore_flag or "--no-ignore"
				if opts.cmd:match(fzf_utils.lua_regex_escape(flag)) then
					return "on .gitignore" --respect
				else
					return "off .gitignore" -- disabled
				end
			end,
		}
		fzf_core.ACTION_DEFINITIONS[fzf_actions.grep_lgrep] = {
			function(opts)
				if opts.fn_reload then
					return "fuzzy lgrep (root)"
				else
					return "regex lgrep (root)"
				end
			end,
		}

		fzf_core.ACTION_DEFINITIONS[fzf_actions.switch_cwd] = { "change cwd", pos = 1 }
		fzf_core.ACTION_DEFINITIONS[fzf_actions.del_autocmd] = { "autocmd delete" }
		fzf_core.ACTION_DEFINITIONS[fzf_actions.arg_add] = { "argadd" }
		fzf_core.ACTION_DEFINITIONS[fzf_actions.arg_search_add] = { "search and argadd" }
		fzf_core.ACTION_DEFINITIONS[fzf_actions.buf_del] = { "buf close" }
		fzf_core.ACTION_DEFINITIONS[fzf_actions.arg_del] = { "arg delete" }
		fzf_core.ACTION_DEFINITIONS[fzf_actions.dap_bp_del] = { "breakpoint delete" }

		fzf_config._action_to_helpstr[fzf_actions.arg_search_add] = "search-and-argadd"
		fzf_config._action_to_helpstr[fzf_actions.arg_add] = "argadd"
		fzf_config._action_to_helpstr[fzf_actions.buf_edit_or_qf] = "buf_edit_or_qf"
		fzf_config._action_to_helpstr[fzf_actions.del_autocmd] = "delete-autocmd"
		fzf_config._action_to_helpstr[fzf_actions.switch_provider] = "switch-provider"
		fzf_config._action_to_helpstr[fzf_actions.switch_cwd] = "change-cwd"

		local no_preview_opts = {
			defaults = { headers = { "actions" }, actions = { ["ctrl-]"] = fzf_actions.switch_provider } },
			actions = {
				files = {
					["default"] = fzf_actions.buf_edit_or_qf,
					["ctrl-l"] = fzf_actions.arg_add,
					["ctrl-s"] = fzf_actions.file_split,
					["ctrl-v"] = fzf_actions.file_vsplit,
					["ctrl-t"] = fzf_actions.file_tabedit,
					["ctrl-q"] = fzf_actions.file_sel_to_qf,
					["alt-q"] = fzf_actions.file_sel_to_ll,
				},
			},
			fzf_colors = {
				fg = { "fg", "Normal" },
				bg = { "bg", "Normal" },
				hl = { "fg", "DashboardIcon" },
				info = { "fg", "Function" },
				border = { "fg", "Comment" },
				gutter = { "bg", "Normal" },
				prompt = { "fg", "FzfLuaPrompt" },
				pointer = { "fg", "CmpItemAbbrMatch" },
				marker = { "fg", "GitSignsChange" },
				["fg+"] = { "fg", "CmpItemAbbr" },
				["bg+"] = { "bg", "PmenuSel" },
				["hl+"] = { "fg", "CmpItemAbbrMatch" },
			},
			keymap = {
				builtin = { ["<F1>"] = "toggle-help", ["<esc><esc>"] = "abort" },
				fzf = {
					["ctrl-z"] = "abort",
					["ctrl-c"] = "abort",
					["ctrl-u"] = "unix-line-discard",
					["ctrl-f"] = "half-page-down",
					["ctrl-b"] = "half-page-up",
					["ctrl-a"] = "beginning-of-line",
					["ctrl-e"] = "end-of-line",
					["ctrl-h"] = "toggle-header",
					["ctrl-y"] = "yank",
					["alt-a"] = "toggle-all",
					["alt-,"] = "clear-selection",
					["ctrl-d"] = "clear-query",
				},
			},
			file_icon_padding = " ",
			global_resume = true, -- enable global `resume`?
			global_resume_query = true, -- include typed query in `resume`?
			fzf_opts = no_preview_fzf_opts,
			winopts = {
				split = fmt("botright %dnew", (vim.o.lines * 0.4)),
				preview = { hidden = "hidden" },
			},

			-- PROVIDER --
			buffers = {
				show_unlisted = true,
				show_unloaded = true,
				ignore_current_buffer = false,
				no_action_set_cursor = true,
				current_tab_only = false,
				no_term_buffers = false,
				cwd_only = false,
				ls_cmd = "ls",
			},
			autocmds = { actions = { ["ctrl-x"] = { fn = fzf_actions.del_autocmd } }, headers = { "actions" } },
			args = {
				files_only = false,
				headers = { "actions" },
				actions = { ["ctrl-j"] = fzf_actions.arg_search_add },
			},
			colorschemes = { actions = { ["default"] = fzf_actions.colorscheme } },
			highlights = {
				actions = {
					["default"] = function(selected)
						vim.defer_fn(function()
							vim.cmd.hi(selected[1])
						end, 0)
					end,
				},
			},
			command_history = { actions = { ["alt-e"] = fzf_actions.ex_run, ["ctrl-e"] = false } },
			search_history = {
				headers = { "actions", "regex_filter" },
				actions = { ["alt-e"] = fzf_actions.search, ["ctrl-e"] = false },
			},
			blines = {
				headers = { "actions" },
				fzf_opts = {
					["--delimiter"] = "[:]",
					["--with-nth"] = "2..",
					["--tiebreak"] = "index",
					["--tabstop"] = "1",
				},
				actions = {
					["alt-q"] = fzf_actions.buf_sel_to_qf,
					["alt-o"] = fzf_actions.buf_sel_to_ll,
					["alt-l"] = false,
				},
			},
			lines = {
				headers = { "actions" },
				actions = {
					["alt-q"] = fzf_actions.buf_sel_to_qf,
					["alt-o"] = fzf_actions.buf_sel_to_ll,
					["alt-l"] = false,
				},
			},
			grep = {
				actions = { ["alt-l"] = fzf_actions.grep_lgrep, ["ctrl-g"] = fzf_actions.toggle_ignore },
				headers = { "actions", "cwd" },
				cwd_header = true,
				input_prompt = "Grep For : ",
				glob_flag = "--iglob",
				glob_separator = "%s%-%-",
				rg_glob = false,
				git_icons = false,
				rg_opts = table.concat({
					"--hidden",
					"--follow",
					"--smart-case",
					"--column",
					"--line-number",
					"--no-heading",
					"--color=always",
					"-g",
					fmt("'!{%s}/'", ignore_folder),
					"-g",
					fmt("'!{%s}'", ignore_file),
					"-e",
				}, " "),
			},
			files = {
				prompt = "   : ",
				headers = { "actions", "cwd" },
				multiprocess = true,
				git_icons = false,
				file_icons = true,
				color_icons = true,
				cwd_header = true,
				cwd_prompt = false,
				find_opts = table.concat({
					"-type",
					"f",
					"-type",
					"l", -- symbolic link
					"-not",
					"-path",
					"'*/.git/*'",
					"-printf",
					"'%p\n'",
				}, " "),

				fd_opts = table.concat({
					"--color=never",
					"--type",
					"f",
					"--type",
					"l", -- symbolic link
					"--follow",
					"--exclude",
					fmt("'{%s}/'", ignore_folder),
					"--exclude",
					fmt("'{%s}'", ignore_file),
				}, " "),

				rg_opts = table.concat({
					"--color=never",
					"--files",
					"--follow",
					"-g",
					fmt("'!{%s}/'", ignore_folder),
					"-g",
					fmt("'!{%s}'", ignore_file),
				}, " "),

				actions = {
					["ctrl-g"] = fzf_actions.toggle_ignore,
					["alt-f"] = fzf_actions.switch_cwd,
				},
			},
			lsp = {
				code_actions = { winopts = { split = fmt("botright %d new", (vim.o.lines / 4)) } },
				symbols = { symbol_icons = icons.kinds },
				definitions = { sync = false, jump_to_single_result = true },
				references = { sync = false, ignore_current_line = true, jump_to_single_result = true },
				typedefs = { sync = false, jump_to_single_result = true },
			},
			diagnostics = {
				signs = {
					["Error"] = { text = icons.diagnostics.Error, texthl = "DiagnosticError" },
					["Warn"] = { text = icons.diagnostics.Warn, texthl = "DiagnosticWarn" },
					["Info"] = { text = icons.diagnostics.Info, texthl = "DiagnosticInfo" },
					["Hint"] = { text = icons.diagnostics.Hint, texthl = "DiagnosticHint" },
				},
			},
			git = {
				icons = {
					["M"] = { icon = icons.git.modified, color = "yellow" },
					["D"] = { icon = icons.git.removed, color = "red" },
					["A"] = { icon = icons.git.added, color = "green" },
					["R"] = { icon = icons.git.renamed, color = "yellow" },
					["C"] = { icon = icons.git.unstage, color = "yellow" }, --copied
					["T"] = { icon = icons.git.ignored, color = "magenta" }, -- type change
					["?"] = { icon = icons.git.untracked, color = "magenta" },
				},
				files = {
					cmd = [[git ls-files --exclude-standard]],
					prompt = "  : ",
					multiprocess = true,
					git_icons = false,
					file_icons = true,
					color_icons = true,
					actions = { ["ctrl-g"] = fzf_actions.toggle_ignore },
				},
			},
		}

		local preview_opts = {
			fzf_opts = {
				["--ansi"] = true,
				["--info"] = "right",
				["--header"] = false,
				["--padding"] = "0,1",
				["--margin"] = "0",
				["--marker"] = "",
				["--pointer"] = "",
				["--no-scrollbar"] = true,
			},
			winopts = {
				height = 0.70,
				width = 0.90,
				row = 0.50,
				col = 0.45,
				border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
				fullscreen = false,
				preview = {
					border = "border",
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
						foldmethod = "manual",
					},
				},
			},
			keymap = {
				builtin = vim.tbl_extend("force", no_preview_opts.keymap.builtin, {
					["<F2>"] = "toggle-fullscreen",
					["<F3>"] = "toggle-preview-wrap",
					["<F4>"] = "toggle-preview",
					["<F5>"] = "toggle-preview-ccw",
					["<F6>"] = "toggle-preview-cw",
					["<S-down>"] = "preview-page-down",
					["<S-up>"] = "preview-page-up",
					["<S-left>"] = "preview-page-reset",
				}),
			},
		}

		local enabled, map, fzf_opts_map = true, vim.keymap.set, no_preview_opts.fzf_opts
		map("n", "<leader>uz", function()
			enabled = not enabled
			if enabled then
				no_preview_opts.files.headers = { "actions", "cwd" }
				no_preview_opts.grep.headers = { "actions" }
				fzf_opts_map = no_preview_opts.fzf_opts
				vim.notify("Disabled FZF preview", 2, { title = "Fzflua" })
				return fzf.setup(no_preview_opts)
			else
				no_preview_opts.files.headers = { "cwd" }
				no_preview_opts.grep.headers = false
				fzf_opts_map = preview_opts.fzf_opts
				vim.notify("Enabled FZF Preview", 2, { title = "Fzflua" })
				return fzf.setup(vim.tbl_extend("force", no_preview_opts, preview_opts))
			end
		end, { desc = "Toggle FZF Preview" })

		fzf.setup(no_preview_opts)

		local function fzfmap(builtin, opts)
			local params = { builtin = builtin, opts = opts }
			return function()
				builtin = params.builtin
				opts = params.opts
				opts = vim.tbl_extend(
					"force",
					{ cwd = require("directory").get_root(), fzf_opts = fzf_opts_map },
					opts or {}
				)
				fzf[builtin](opts)
			end
		end

		local note_path = os.getenv("HOME") .. "/Notes"
		local note_args = {
			cwd_header = true,
			headers = { "actions", "cwd" },
			prompt = "Folder : ",
			find_opts = [[-type d -not -path '*/\.git/*' -printf '%P\n']],
			fd_opts = fmt(
				[[--color=never --type d --hidden --follow --exclude '{%s}/' --exclude '{%s}/']],
				ignore_folder,
				ignore_file
			),
			rg_opts = fmt([[--color=never --hidden --follow -g '!{%s}/' -g '!{%s}' ]], ignore_folder, ignore_file),
		}

		map("n", "<C-p>", fzfmap("files"), { desc = "Find Files (root)" })
		map(
			"n",
			"<leader>fN",
			fzfmap("files", vim.tbl_extend("force", note_args, { cwd = note_path })),
			{ desc = "Find Notes Folder (root)" }
		)
		map("n", "<leader>fd", fzfmap("files", note_args), { desc = "Find Folder (root)" })
		map("n", "<leader>fn", fzfmap("files", { cwd = note_path }), { desc = "Find Notes Files (root)" })
		map("n", "<leader>fB", fzfmap("builtin"), { desc = "Find Builtin" })
		map("n", "<leader>fb", fzfmap("buffers"), { desc = "Find Buffers" })
		map("n", "<leader>ff", fzfmap("files"), { desc = "Find Files (root)" })
		map("n", "<leader>fo", fzfmap("oldfiles"), { desc = "Find Old Files" })
		map("n", "<leader>fq", fzfmap("quickfix"), { desc = "Quick Fix Item" })
		map("n", "<leader>fl", fzfmap("lines"), { desc = "Find in Lines" })
		map("n", "<leader>ft", fzfmap("tabs"), { desc = "Find Tabs" })
		map("n", "<leader>fa", fzfmap("args"), { desc = "Args" })
		map("n", "<leader>fh", fzfmap("help_tags"), { desc = "Help Tags" })
		map("n", "<leader>fH", fzfmap("highlights"), { desc = "Highlight Groups" })
		map("n", "<leader>fc", fzfmap("commands"), { desc = "Neovim Commands" })
		map("n", "<leader>fz", fzfmap("search_history"), { desc = "Search History" })
		map("n", "<leader>fm", fzfmap("marks"), { desc = "Marks" })
		map("n", "<leader>fC", fzfmap("changes"), { desc = "Changes" })
		map("n", "<leader>fj", fzfmap("jumps"), { desc = "Jumps" })
		map("n", "<leader>fk", fzfmap("keymaps"), { desc = "Keymaps" })
		map("n", "<leader>fr", fzfmap("registers"), { desc = "Registers" })
		map("n", "<leader>fs", fzfmap("spell_suggest"), { desc = "Spell Suggest" })
		map("n", "<leader>fT", fzfmap("awesome_colorschemes"), { desc = "Awesome Colorschemes" })
		map("n", "<leader>fF", "<cmd>FzfLua resume<cr>", { desc = "Find Resume" })

		map("n", "<leader>fg", fzfmap("git_files"), { desc = "Git Files" })
		map("n", "<leader>hfs", fzfmap("git_status"), { desc = "`git status`" })
		map("n", "<leader>hfc", fzfmap("git_commits"), { desc = "Git Commit Log (project)" })
		map("n", "<leader>hfB", fzfmap("git_branches"), { desc = "`git branches`" })
		map("n", "<leader>hfb", fzfmap("git_bcommits"), { desc = "Git Commit Log (buffer)" })
		map("n", "<leader>hft", fzfmap("git_tags"), { desc = "`git tags`" })
		map("n", "<leader>hfS", fzfmap("git_stash"), { desc = "`git stash`" })

		map("n", "<leader>sc", fzfmap("grep_cword"), { desc = "Grep cword" })
		map("n", "<leader>sC", fzfmap("grep_cWORD"), { desc = "Grep cWORD" })
		map("v", "<leader>sv", fzfmap("grep_visual"), { desc = "Visual Grep" })
		map("n", "<leader>/", fzfmap("grep"), { desc = "Grep RG (pattern)" })
		map("n", "<leader>?", fzfmap("grep_last"), { desc = "Run Last Grep" })
		map("n", "<leader>ss", fzfmap("grep"), { desc = "Grep RG (pattern)" })
		map("n", "<leader>sS", fzfmap("grep_last"), { desc = "Run Last Grep" })
		map("n", "<leader>sb", fzfmap("grep_curbuf"), { desc = "Grep CurBuf" })
		map("n", "<leader>sB", fzfmap("lgrep_curbuf"), { desc = "LG CurBuf" })
		map("n", "<leader>sw", fzfmap("live_grep"), { desc = "LG Root Dir" })
		map("n", "<leader>sW", fzfmap("live_grep_resume"), { desc = "LG Last Search" })
		map("n", "<leader>sn", fzfmap("live_grep_native"), { desc = "Native of LG" })
		map("n", "<leader>sg", fzfmap("live_grep_glob"), { desc = "LG rg --glob" })
		map("n", "<leader>sa", fzfmap("autocmds"), { desc = "Search Autocmds" })
		map("n", "<leader>s-", fzfmap("blines"), { desc = "Current Buffer Lines" })
		map("n", "<leader>s=", fzfmap("lines"), { desc = "Open Buffer Lines" })

		map("n", "<leader>dsc", fzfmap("dap_commands"), { desc = "Command" })
		map("n", "<leader>dsC", fzfmap("dap_configurations"), { desc = "Configuration" })
		map("n", "<leader>dsb", fzfmap("dap_breakpoints"), { desc = "Breakpoint" })
		map("n", "<leader>dsv", fzfmap("dap_variables"), { desc = "Active Session Variables" })
		map("n", "<leader>dsf", fzfmap("dap_frames"), { desc = "Frames" })

		map("n", "<leader>gf", fzfmap("lsp_finder"), { desc = "Lsp Finder" })
	end,
	keys = {
		"<C-p>",
		"<leader>fN",
		"<leader>fd",
		"<leader>fn",
		"<leader>fB",
		"<leader>fb",
		"<leader>ff",
		"<leader>fo",
		"<leader>fq",
		"<leader>fl",
		"<leader>ft",
		"<leader>fa",
		"<leader>fh",
		"<leader>fH",
		"<leader>fc",
		"<leader>fz",
		"<leader>fm",
		"<leader>fC",
		"<leader>fj",
		"<leader>fk",
		"<leader>fr",
		"<leader>fs",
		"<leader>fF",

		"<leader>fg",
		"<leader>hfs",
		"<leader>hfc",
		"<leader>hfB",
		"<leader>hfb",
		"<leader>hft",
		"<leader>hfS",

		"<leader>sc",
		"<leader>sC",
		"<leader>sv",
		"<leader>/",
		"<leader>?",
		"<leader>ss",
		"<leader>sS",
		"<leader>sb",
		"<leader>sB",
		"<leader>sw",
		"<leader>sW",
		"<leader>sn",
		"<leader>sg",
		"<leader>sa",
		"<leader>s-",
		"<leader>s=",

		"<leader>dsc",
		"<leader>dsC",
		"<leader>dsb",
		"<leader>dsv",
		"<leader>dsf",

		"<leader>uz",
		"<leader>gf",
	},
}
