local M = {}

M.keys = { { "<leader>e", "<cmd>Oil<cr>", desc = "File Explorer" } }

function M.init()
	return vim.api.nvim_create_autocmd("BufWinEnter", {
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
end

function M.setup()
	local oil, icons = require("oil"), require("utils.icons").kinds
	local preview_wins, preview_bufs = {}, {}
	local preview_max_fsize = 1000000
	local preview_debounce = 64 -- ms
	local preview_request_last_timestamp = 0

	---Change window-local directory to `dir`
	local function set_lcd(dir)
		local ok = pcall(vim.cmd.lcd, dir)
		if not ok then
			vim.notify("[oil.nvim] failed to cd to " .. dir, vim.log.levels.WARN)
		end
	end

	---Generate lines for preview window when preview is not available
	local function no_preview(msg, height, width)
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
	local function end_preview(oil_win)
		oil_win = oil_win or vim.api.nvim_get_current_win()
		local preview_win = preview_wins[oil_win]
		local preview_buf = preview_bufs[oil_win]
		if preview_win and vim.api.nvim_win_is_valid(preview_win) and vim.fn.winbufnr(preview_win) == preview_buf then
			vim.api.nvim_win_close(preview_win, true)
		end
		if preview_buf and vim.api.nvim_win_is_valid(preview_buf) then
			vim.api.nvim_win_close(preview_buf, true)
		end
		preview_wins[oil_win] = nil
		preview_bufs[oil_win] = nil
	end

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
		vim.cmd.new({ mods = { vertical = true } })
			-- vim.cmd.new({ mods = { horizontal = true } })

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
			vim.opt_local.listchars:append({ tab = "  " })

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
			or stat.size == 0 and no_preview("Empty file", preview_win_height, preview_win_width)
			or stat.size > preview_max_fsize and no_preview(
				"File too large to preview",
				preview_win_height,
				preview_win_width
			)
			or not vim.fn.system({ "file", fpath }):match("text") and no_preview(
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
				set_lcd(target_dir)
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
		{ "size", highlight = "AlphaButtons" },
		{ "mtime", highlight = "RainbowDelimiterViolet" },
		{ "icon", default_file = icons.File, directory = icons.Folder, add_padding = false },
	}

	if tostring(vim.fs.normalize(vim.fn.getcwd(vim.fn.winnr()))) == tostring(vim.fn.expand("~") .. "/Notes") then
		columns = {
			{ "icon", default_file = icons.File, directory = icons.Folder, add_padding = false },
		}
	end

	oil.setup({
		default_file_explorer = true,
		columns = columns,
		win_options = {
			virtualedit = "block",
			wrap = false,
			signcolumn = "no",
			cursorcolumn = false,
			foldcolumn = "0",
			spell = false,
			conceallevel = 3,
			concealcursor = "nivc",
			number = false,
			relativenumber = false,
			statuscolumn = nil,
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
			["gm"] = {
				desc = "Generate Random Name for Markdown File",
				callback = function()
					local position = vim.api.nvim_win_get_cursor(0)
					local row, col = position[1], position[2]
					local replacement = {}

					if vim.api.nvim_get_mode()["mode"] == "n" then
						math.randomseed(os.time())
						local len = 7
						local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
						local name = ""
						for _ = 1, len do
							local ridx = math.random(1, #chars)
							name = string.format("%s%s", name, string.sub(chars, ridx, ridx))
						end
						if string.len(name) > len then
							name:gsub(" ", "_"):lower()
						end
						local generate_name = string.format("%s_%s%s.md", os.date("%d%m%Y"), os.date("%S"), name)
						table.insert(replacement, generate_name)

						vim.api.nvim_buf_set_text(0, row - 1, col - 1, row - 1, col - 1, replacement)
						vim.api.nvim_win_set_cursor(0, { row, row - 1 })
						return
					else
						return vim.notify("genarete name file only work on insert mode", 2, { title = "Oil" })
					end
				end,
			},
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
	})

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
					set_lcd(oildir)
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
end

return M
