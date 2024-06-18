---@param group string
---@vararg { [1]: string|string[], [2]: vim.api.keyset.create_autocmd }
---@return nil
local function augroup(group, ...)
	local id = vim.api.nvim_create_augroup(group, {})
	for _, a in ipairs({ ... }) do
		a[2].group = id
		vim.api.nvim_create_autocmd(unpack(a))
	end
end

augroup("BigFileSettings", {
	"BufReadPre",
	{
		desc = "Set settings for large files.",
		callback = function(opts)
			vim.b.bigfile = false

			local fname = vim.api.nvim_buf_get_name(opts.buf)
			if #fname <= 0 then
				return
			end

			local size = vim.fn.getfsize(fname) / 1024
			if not size then
				return
			end

			if not vim.api.nvim_buf_is_loaded(opts.buf) then
				return
			end

			local function force_to_deattach()
				for _, client in pairs(vim.lsp.get_clients({ bufnr = opts.buf })) do
					if client.id > 0 then
						vim.api.nvim_create_autocmd("BufReadPost", {
							buffer = opts.buf,
							once = true,
							callback = function()
								vim.schedule(function()
									pcall(vim.treesitter.stop, opts.buf)
									vim.lsp.buf_detach_client(opts.buf, client.id)
								end)
								return true
							end,
						})
					end
				end
			end

			if size > 4800 then
				vim.b.bigfile = true
				vim.opt_local.spell = false
				vim.opt_local.swapfile = false
				vim.opt_local.undofile = false
				vim.opt_local.breakindent = false
				vim.opt_local.colorcolumn = ""
				vim.opt_local.statuscolumn = ""
				vim.opt_local.signcolumn = "no"
				vim.opt_local.foldcolumn = "0"
				vim.opt_local.winbar = ""
				vim.opt_local.number = false
				vim.opt_local.relativenumber = false
				force_to_deattach()
				vim.notify(string.format("[ file %dkb ] big file setup has been loaded", math.floor(size)), 2)
			end
		end,
	},
})

augroup("YankHighlight", {
	"TextYankPost",
	{
		desc = "Highlight the selection on yank.",
		callback = function()
			vim.highlight.on_yank({ higroup = "IlluminatedWordRead", timeout = 200 })
		end,
	},
})

augroup("Autosave", {
	{ "BufLeave", "WinLeave", "FocusLost" },
	{
		nested = true,
		desc = "Autosave on focus change.",
		callback = function(info)
			if vim.bo[info.buf].bt == "" then
				vim.cmd.update({ mods = { emsg_silent = true } })
			end
		end,
	},
})

augroup("WinCloseJmp", {
	"WinClosed",
	{
		nested = true,
		desc = "Jump to last accessed window on closing the current one.",
		command = "if expand('<amatch>') == win_getid() | wincmd p | endif",
	},
})

augroup("LastPosJmp", {
	"BufReadPost",
	{
		desc = "Last position jump.",
		callback = function(info)
			local ft = vim.bo[info.buf].ft
			-- don't apply to git messages
			if ft ~= "gitcommit" and ft ~= "gitrebase" then
				vim.cmd.normal({ 'g`"zvzz', bang = true, mods = { emsg_silent = true } })
			end
		end,
	},
})

augroup("AutoCwd", {
	{ "BufWinEnter", "FileChangedShellPost" },
	{
		pattern = "*",
		desc = "Automatically change local current directory.",
		callback = function(info)
			if info.file == "" or vim.bo[info.buf].bt ~= "" then
				return
			end
			local buf = info.buf
			local win = vim.api.nvim_get_current_win()

			vim.schedule(function()
				if
					not vim.api.nvim_buf_is_valid(buf)
					or not vim.api.nvim_win_is_valid(win)
					or not vim.api.nvim_win_get_buf(win) == buf
				then
					return
				end
				vim.api.nvim_win_call(win, function()
					local current_dir = vim.fn.getcwd(0)
					local target_dir = require("utils").root() or vim.fs.dirname(info.file)
					---@diagnostic disable-next-line: undefined-field
					local stat = target_dir and vim.uv.fs_stat(target_dir)
					-- Prevent unnecessary directory change, which triggers
					-- DirChanged autocmds that may update winbar unexpectedly
					if stat and stat.type == "directory" and current_dir ~= target_dir then
						-- vim.notify(string.format("Swicth to [%s]", target_dir), 3, { title = "Root Path" })
						pcall(vim.cmd.lcd, target_dir)
					end
				end)
			end)
		end,
	},
})

augroup("PromptBufKeymaps", {
	"BufEnter",
	{
		desc = "Undo automatic <C-w> remap in prompt buffers.",
		callback = function(info)
			if vim.bo[info.buf].buftype == "prompt" then
				vim.keymap.set("i", "<C-w>", "<C-S-W>", { buffer = info.buf })
			end
		end,
	},
})

augroup("QuickFixAutoOpen", {
	"QuickFixCmdPost",
	{
		desc = "Open quickfix window if there are results.",
		callback = function(info)
			if #vim.fn.getqflist() > 1 then
				vim.schedule(vim.cmd[info.match:find("^l") and "lwindow" or "cwindow"])
			end
		end,
	},
})

-- Show cursor line and cursor column only in current window
augroup("AutoHlCursorLine", {
	"WinEnter",
	{
		desc = "Show cursorline and cursorcolumn in current window.",
		callback = function()
			if vim.w._cul and not vim.wo.cul then
				vim.wo.cul = true
				vim.w._cul = nil
			end
			if vim.w._cuc and not vim.wo.cuc then
				vim.wo.cuc = true
				vim.w._cuc = nil
			end

			local prev_win = vim.fn.win_getid(vim.fn.winnr("#"))
			if prev_win ~= 0 then
				local w = vim.w[prev_win]
				local wo = vim.wo[prev_win]
				w._cul = wo.cul
				w._cuc = wo.cuc
				wo.cul = false
				wo.cuc = false
			end
		end,
	},
})

augroup("FixCmdLineIskeyword", {
	"CmdLineEnter",
	{
		desc = "Have consistent &iskeyword and &lisp in Ex command-line mode.",
		pattern = "[^/?]",
		callback = function(info)
			-- Don't set &iskeyword and &lisp settings in search command-line
			-- ('/' and '?'), if we are searching in a lisp file, we want to
			-- have the same behavior as in insert mode
			vim.g._isk_lisp_buf = info.buf
			vim.g._isk_save = vim.bo[info.buf].isk
			vim.g._lisp_save = vim.bo[info.buf].lisp
			vim.cmd.setlocal("isk&")
			vim.cmd.setlocal("lisp&")
		end,
	},
}, {
	"CmdLineLeave",
	{
		desc = "Restore &iskeyword after leaving command-line mode.",
		pattern = "[^/?]",
		callback = function()
			if
				vim.g._isk_lisp_buf
				and vim.api.nvim_buf_is_valid(vim.g._isk_lisp_buf)
				and vim.g._isk_save ~= vim.b[vim.g._isk_lisp_buf].isk
			then
				vim.bo[vim.g._isk_lisp_buf].isk = vim.g._isk_save
				vim.bo[vim.g._isk_lisp_buf].lisp = vim.g._lisp_save
				vim.g._isk_save = nil
				vim.g._lisp_save = nil
				vim.g._isk_lisp_buf = nil
			end
		end,
	},
})

augroup("HideCursorLineInsertMode", {
	"ModeChanged",
	{
		desc = "Hide cursorline and cursorcolumn in insert mode.",
		pattern = { "[itRss\x13]*:*", "*:[itRss\x13]*" },
		callback = function()
			if vim.v.event.new_mode:match("^[itRss\x13]") then
				if vim.wo.cul then
					vim.w._cul = true
					vim.wo.cul = false
				end
				if vim.wo.cuc then
					vim.w._cuc = true
					vim.wo.cuc = false
				end
			else
				if vim.w._cul and not vim.wo.cul then
					vim.wo.cul = true
					vim.w._cul = nil
				end
				if vim.w._cuc and not vim.wo.cuc then
					vim.wo.cuc = true
					vim.w._cuc = nil
				end
			end
		end,
	},
})

augroup("AutoCreateDir", {
	"BufWritePre",
	{
		callback = function(event)
			if event.match:match("^%w%w+:[\\/][\\/]") then
				return
			end
			local file = vim.uv.fs_realpath(event.match) or event.match
			vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
		end,
	},
})

return augroup
