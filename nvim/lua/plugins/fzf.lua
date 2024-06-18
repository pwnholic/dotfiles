return {
	"ibhagwan/fzf-lua",
	cmd = "FzfLua",
	init = vim.schedule_wrap(function()
		---@diagnostic disable-next-line: duplicate-set-field
		vim.ui.select = function(...)
			local fzf_ui = require("fzf-lua.providers.ui_select")
			if not fzf_ui.is_registered() then
				local _ui_select = fzf_ui.ui_select
				fzf_ui.ui_select = function(items, opts, on_choice)
					opts.prompt = opts.prompt and vim.fn.substitute(opts.prompt, ":\\?\\s*$", ":\xc2\xa0", "")
					_ui_select(items, opts, on_choice)
				end
				fzf_ui.register(function(_, items)
					local min_h, max_h = 0.15, 0.70
					local h = (#items + 4) / vim.o.lines
					if h < min_h then
						h = min_h
					elseif h > max_h then
						h = max_h
					end
					return { winopts = { height = h, width = 0.60, row = 0.40 } }
				end)
			end
			vim.ui.select(...)
		end
	end),
	keys = function()
		local fzf = require("fzf-lua")
		return {
			{ "<leader>ff", fzf.files, desc = "Find Files (root)" },
			{ "<C-p>", fzf.files, desc = "Find Files (root)" },
			{ "<leader>fB", fzf.builtin, desc = "Find Builtin" },
			{ "<leader>fb", fzf.buffers, desc = "Find Buffers" },
			{ "<leader>fo", fzf.oldfiles, desc = "Find Old Files" },
			{ "<leader>fq", fzf.quickfix, desc = "Quick Fix Item" },
			{ "<leader>fl", fzf.lines, desc = "Find in Lines" },
			{ "<leader>ft", fzf.tabs, desc = "Find Tabs" },
			{ "<leader>fa", fzf.args, desc = "Args" },
			{ "<leader>fh", fzf.help_tags, desc = "Help Tags" },
			{ "<leader>fH", fzf.highlights, desc = "Highlight Groups" },
			{ "<leader>fc", fzf.commands, desc = "Neovim Commands" },
			{ "<leader>fz", fzf.search_history, desc = "Search History" },
			{ "<leader>fm", fzf.marks, desc = "Marks" },
			{ "<leader>fC", fzf.changes, desc = "Changes" },
			{ "<leader>fj", fzf.jumps, desc = "Jumps" },
			{ "<leader>fk", fzf.keymaps, desc = "Keymaps" },
			{ "<leader>fr", fzf.registers, desc = "Registers" },
			{ "<leader>fs", fzf.spell_suggest, desc = "Spell Suggest" },
			{ "<leader>fT", fzf.awesome_colorschemes, desc = "Awesome Colorschemes" },
			{ "<leader>fR", fzf.resume, desc = "Find Resume" },

			{ "<leader>fg", fzf.git_files, desc = "Git Files" },
			{ "<leader>hfs", fzf.git_status, desc = "`git status`" },
			{ "<leader>hfc", fzf.git_commits, desc = "Git Commit Log (project)" },
			{ "<leader>hfB", fzf.git_branches, desc = "`git branches`" },
			{ "<leader>hfb", fzf.git_bcommits, desc = "Git Commit Log (buffer)" },
			{ "<leader>hft", fzf.git_tags, desc = "`git tags`" },
			{ "<leader>hfS", fzf.git_stash, desc = "`git stash`" },

			{ "<leader>sc", fzf.grep_cword, desc = "Grep cword" },
			{ "<leader>sC", fzf.grep_cWORD, desc = "Grep cWORD" },
			{ "<leader>sv", fzf.grep_visual, desc = "Visual Grep" },
			{ "<leader>/", fzf.grep, desc = "Grep RG (pattern)" },
			{ "<leader>?", fzf.grep_last, desc = "Run Last Grep" },
			{ "<leader>ss", fzf.grep, desc = "Grep RG (pattern)" },
			{ "<leader>sS", fzf.grep_last, desc = "Run Last Grep" },
			{ "<leader>sb", fzf.grep_curbuf, desc = "Grep CurBuf" },
			{ "<leader>sB", fzf.lgrep_curbuf, desc = "LG CurBuf" },
			{ "<leader>sw", fzf.live_grep, desc = "LG Root Dir" },
			{ "<leader>sW", fzf.live_grep_resume, desc = "LG Last Search" },
			{ "<leader>sn", fzf.live_grep_native, desc = "Native of LG" },
			{ "<leader>sg", fzf.live_grep_glob, desc = "LG rg --glob" },
			{ "<leader>sa", fzf.autocmds, desc = "Search Autocmds" },
			{ "<leader>s-", fzf.blines, desc = "Current Buffer Lines" },
			{ "<leader>s=", fzf.lines, desc = "Open Buffer Lines" },

			{ "<leader>dsc", fzf.dap_commands, desc = "Command" },
			{ "<leader>dsC", fzf.dap_configurations, desc = "Configuration" },
			{ "<leader>dsb", fzf.dap_breakpoints, desc = "Breakpoint" },
			{ "<leader>dsv", fzf.dap_variables, desc = "Active Session Variables" },
			{ "<leader>dsf", fzf.dap_frames, desc = "Frames" },
		}
	end,
	opts = function()
		local fzf = require("fzf-lua")
		local core = require("fzf-lua.core")
		local config = require("fzf-lua.config")
		local actions = require("fzf-lua.actions")
		local path = require("fzf-lua.path")
		local fzf_utils = require("fzf-lua.utils")
		local utils = require("utils")

		local _mt_cmd_wrapper = core.mt_cmd_wrapper

		---@param opts table?
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

			-- Adapted from fzf-lua `core.set_header()` function
			if opts.cwd_prompt then
				opts.prompt = vim.fn.fnamemodify(opts.cwd, ":.:~")
				local shorten_len = tonumber(opts.cwd_prompt_shorten_len)
				if shorten_len and #opts.prompt >= shorten_len then
					opts.prompt = path.shorten(opts.prompt, tonumber(opts.cwd_prompt_shorten_val) or 1)
				end
				if not path.ends_with_separator(opts.prompt) then
					opts.prompt = opts.prompt .. path.separator()
				end
			end
			if opts.headers then
				opts = core.set_header(opts, opts.headers)
			end
			actions.resume()
		end

		local function select_to_qf(selected, opts, is_loclist)
			local qf_list = {}
			for i = 1, #selected do
				local entry_file = path.entry_to_file(selected[i], opts)
				table.insert(qf_list, {
					filename = entry_file.bufname or entry_file.path,
					lnum = entry_file.line,
					col = entry_file.col,
					text = selected[i]:match(":%d+:%d?%d?%d?%d?:?(.*)$"),
				})
			end
			local title = string.format(
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

		function actions._buf_edit_or_qf(selected, opts)
			if #selected > 1 then
				return select_to_qf(selected, opts)
			else
				return actions.file_edit(selected, opts)
			end
		end

		core.ACTION_DEFINITIONS[actions.toggle_ignore] = { "Disable .gitignore", fn_reload = "Respect .gitignore" }
		core.ACTION_DEFINITIONS[actions.switch_cwd] = { "Change Cwd", pos = 1 }

		config._action_to_helpstr[actions._buf_edit_or_qf] = "edit-or-qf"
		config._action_to_helpstr[actions.switch_cwd] = "change-cwd"

		return {
			file_icon_padding = " ",
			defaults = { headers = { "actions", "cwd" }, cwd_header = true },
			keymap = {
				builtin = {
					["<F1>"] = "toggle-help",
					["<F2>"] = "toggle-fullscreen",
					["<F3>"] = "toggle-preview-wrap",
					["<F4>"] = "toggle-preview",
					["<F5>"] = "toggle-preview-ccw",
					["<F6>"] = "toggle-preview-cw",
					["<S-down>"] = "preview-page-down",
					["<S-up>"] = "preview-page-up",
					["<S-left>"] = "preview-page-reset",
				},
				fzf = {
					["ctrl-z"] = "abort",
					["ctrl-u"] = "unix-line-discard",
					["ctrl-f"] = "half-page-down",
					["ctrl-b"] = "half-page-up",
					["ctrl-a"] = "beginning-of-line",
					["ctrl-e"] = "end-of-line",
					["alt-a"] = "toggle-all",
					["f3"] = "toggle-preview-wrap",
					["f4"] = "toggle-preview",
					["shift-down"] = "preview-page-down",
					["shift-up"] = "preview-page-up",
				},
			},
			actions = {
				blines = {
					["alt-q"] = actions.buf_sel_to_qf,
					["alt-o"] = actions.buf_sel_to_ll,
					["alt-l"] = false,
				},
				lines = {
					["alt-q"] = actions.buf_sel_to_qf,
					["alt-o"] = actions.buf_sel_to_ll,
					["alt-l"] = false,
				},
				command_history = {
					["alt-e"] = actions.ex_run,
					["ctrl-e"] = false,
				},
				search_history = {
					["alt-e"] = actions.search,
					["ctrl-e"] = false,
				},
				helptags = {
					["default"] = actions.help,
					["alt-s"] = actions.help,
					["alt-v"] = actions.help_vert,
					["alt-t"] = actions.help_tab,
				},
				keymaps = {
					["default"] = actions.keymap_edit,
					["alt-s"] = actions.keymap_split,
					["alt-v"] = actions.keymap_vsplit,
					["alt-t"] = actions.keymap_tabedit,
				},
				awesome_colorschemes = {
					["default"] = actions.colorscheme,
					["ctrl-g"] = { fn = actions.toggle_bg, exec_silent = true },
					["ctrl-r"] = { fn = actions.cs_update, reload = true },
					["ctrl-x"] = { fn = actions.cs_delete, reload = true },
				},
				files = {
					["alt-c"] = actions.switch_cwd,
					["ctrl-g"] = actions.toggle_ignore,
					["default"] = actions._buf_edit_or_qf,
					["ctrl-s"] = actions.file_split,
					["ctrl-v"] = actions.file_vsplit,
					["ctrl-t"] = actions.file_tabedit,
					["alt-q"] = actions.file_sel_to_qf,
					["alt-l"] = actions.file_sel_to_ll,
				},
				grep = {
					["alt-c"] = actions.switch_cwd,
					["ctrl-g"] = actions.toggle_ignore,
					["alt-i"] = actions.grep_lgrep,
				},
				buffers = {
					["default"] = actions.buf_edit,
					["ctrl-s"] = actions.buf_split,
					["ctrl-v"] = actions.buf_vsplit,
					["ctrl-t"] = actions.buf_tabedit,
				},
			},
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
			fzf_colors = true,
			winopts = {
				split = [[ botright 10new | setlocal bt=nofile bh=wipe nobl noswf wfh ]],
				preview = { hidden = "hidden" },
			},
			previewers = {
				builtin = {
					syntax = true, -- preview syntax highlight?
					syntax_limit_l = 0, -- syntax limit (lines), 0=nolimit
					syntax_limit_b = 1024 * 1024, -- syntax limit (bytes), 0=nolimit
					limit_b = 1024 * 1024 * 10, -- preview limit (bytes), 0=nolimit
					treesitter = { enable = true, disable = {} },
					toggle_behavior = "default",
					extensions = {
						["png"] = { "viu", "-b" },
						["svg"] = { "chafa", "{file}" },
						["jpg"] = { "ueberzug" },
					},
					ueberzug_scaler = "cover",
				},
				-- TODO: do some shit with this
				-- keren juga kalo ada delta
				codeaction_native = { diff_opts = { ctxlen = 3 } },
			},
			files = {
				prompt = "Files❯ ",
				multiprocess = true,
				git_icons = false,
				file_icons = true,
				color_icons = true,
				-- path_shorten   = 1,              -- 'true' or number, shorten path?
				formatter = "path.filename_first",
				find_opts = [[-type f -type d -type l -not -path '*/\.git/*' -printf '%P\n']],
				fd_opts = [[--color=never --type f --type d --type l --hidden --follow --exclude .git]],
				rg_opts = [[--color=never --files --hidden --follow -g '!.git'"]],
				cwd_prompt = false,
				cwd_prompt_shorten_len = 32, -- shorten prompt beyond this length
				cwd_prompt_shorten_val = 1, -- shortened path parts length
				toggle_ignore_flag = "--no-ignore", -- flag toggled in `actions.toggle_ignore`
				toggle_hidden_flag = "--hidden", -- flag toggled in `actions.toggle_hidden`
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
			},
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
			awesome_colorschemes = {
				prompt = "Colorschemes❯ ",
				live_preview = true, -- apply the colorscheme on preview?
				max_threads = 5, -- max download/update threads
				winopts = { row = 0, col = 0.99, width = 0.50 },
				fzf_opts = {
					["--multi"] = true,
					["--delimiter"] = "[:]",
					["--with-nth"] = "3..",
					["--tiebreak"] = "index",
				},
			},
			lsp = {
				prompt_postfix = "❯ ", -- will be appended to the LSP label
				-- to override use 'prompt' instead
				cwd_only = false, -- LSP/diagnostics for cwd only?
				async_or_timeout = 5000, -- timeout(ms) or 'true' for async calls
				file_icons = true,
				git_icons = false,
				includeDeclaration = true, -- include current declaration in LSP context
				symbols = {
					async_or_timeout = true,
					symbol_style = 1,
					symbol_icons = utils.icons.kinds,
				},
				definitions = {
					sync = false,
					jump_to_single_result = true,
				},
				references = {
					sync = false,
					ignore_current_line = true,
					jump_to_single_result = true,
				},
				typedefs = {
					sync = false,
					jump_to_single_result = true,
				},
				code_actions = {
					prompt = "Code Actions> ",
					async_or_timeout = 5000,
					winopts = {
						relative = "cursor",
						row = 1,
						col = 0,
						height = 0.4,
						preview = { vertical = "down:80%" },
					},
					previewer = vim.fn.executable("delta") == 1 and "codeaction_native" or nil,
					preview_pager = "delta --width=$COLUMNS --hunk-header-style='omit' --file-style='omit'",
				},
				finder = {
					prompt = "LSP Finder> ",
					file_icons = true,
					color_icons = true,
					git_icons = false,
					async = true, -- async by default
					silent = true, -- suppress "not found"
					separator = "| ", -- separator after provider prefix, `false` to disable
					includeDeclaration = true, -- include current declaration in LSP context
					providers = {
						{ "references", prefix = fzf_utils.ansi_codes.blue("ref ") },
						{ "definitions", prefix = fzf_utils.ansi_codes.green("def ") },
						{ "declarations", prefix = fzf_utils.ansi_codes.magenta("decl") },
						{ "typedefs", prefix = fzf_utils.ansi_codes.red("tdef") },
						{ "implementations", prefix = fzf_utils.ansi_codes.green("impl") },
						{ "incoming_calls", prefix = fzf_utils.ansi_codes.cyan("in  ") },
						{ "outgoing_calls", prefix = fzf_utils.ansi_codes.yellow("out ") },
					},
				},
			},
			diagnostics = {
				prompt = "Diagnostics❯ ",
				cwd_only = false,
				file_icons = true,
				git_icons = false,
				diag_icons = true,
				diag_source = true, -- display diag source (e.g. [pycodestyle])
				icon_padding = " ", -- add padding for wide diagnostics signs
				multiline = true, -- concatenate multi-line diags into a single line
				signs = {
					["Error"] = { text = "", texthl = "DiagnosticError" },
					["Warn"] = { text = "", texthl = "DiagnosticWarn" },
					["Info"] = { text = "", texthl = "DiagnosticInfo" },
					["Hint"] = { text = "󰌵", texthl = "DiagnosticHint" },
				},
			},
		}
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
}
