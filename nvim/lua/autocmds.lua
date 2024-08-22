local autocmd = vim.api.nvim_create_autocmd
local groupid = vim.api.nvim_create_augroup

---@param group string
---@vararg { [1]: string|string[], [2]: vim.api.keyset.create_autocmd }
---@return nil
local function augroup(group, ...)
	local id = groupid(group, {})
	for _, a in ipairs({ ... }) do
		a[2].group = id
		autocmd(unpack(a))
	end
end

augroup("LastPosJmp", {
	"BufReadPost",
	{
		desc = "Last position jump.",
		callback = function(info)
			if not vim.tbl_contains({ "gitcommit", "gitrebase" }, vim.bo[info.buf].filetype) then
				vim.cmd.normal({ 'g`"zvzz', bang = true, mods = { emsg_silent = true } })
			end
		end,
	},
})

augroup("BigFileSettings", {
	"BufReadPre",
	{
		desc = "Set settings for large files.",
		callback = function(info)
			vim.b.bigfile = false
			local stat = vim.uv.fs_stat(info.match)
			if stat and stat.size > 1024000 then
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
				vim.opt_local.syntax = ""
				autocmd("BufReadPost", {
					once = true,
					buffer = info.buf,
					callback = function()
						vim.opt_local.syntax = ""
						return true
					end,
				})
			end
		end,
	},
})

augroup("YankHighlight", {
	"TextYankPost",
	{
		desc = "Highlight the selection on yank.",
		callback = function()
			pcall(vim.highlight.on_yank, { higroup = "Visual", timeout = 200 })
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

augroup("AutoCwd", {
	"LspAttach",
	{
		desc = "Record LSP root directories in `vim.g._lsp_root_dirs`.",
		callback = function(info)
			local client = vim.lsp.get_client_by_id(info.data.client_id)
			local root_dir = client and client.config and client.config.root_dir
			if not root_dir or root_dir == vim.fs.normalize("~") or root_dir == vim.fs.dirname(root_dir) then
				return
			end

			-- Keep only shortest root dir in `vim.g._lsp_root_dirs`,
			-- e.g. if we have `~/project` and `~/project/subdir`, keep only
			-- `~/project`
			local lsp_root_dirs = vim.g._lsp_root_dirs or {}
			for i, dir in ipairs(lsp_root_dirs) do
				-- If the new root dir is a subdirectory of an existing root dir,
				-- return early and don't add it
				if vim.startswith(root_dir, dir) then
					return
				end
				if vim.startswith(dir, root_dir) then
					table.remove(lsp_root_dirs, i)
				end
			end
			table.insert(lsp_root_dirs, root_dir)
			vim.g._lsp_root_dirs = lsp_root_dirs
			-- Execute BufWinEnter event on current buffer to trigger cwd change
			vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = info.buf })
		end,
	},
}, {
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
					local target_dir = vim.fs.root(info.file, require("utils.lsp").root_patterns)
						or vim.fs.dirname(info.file)
					local stat = target_dir and vim.uv.fs_stat(target_dir)
					-- Prevent unnecessary directory change, which triggers
					-- DirChanged autocmds that may update winbar unexpectedly
					if stat and stat.type == "directory" and current_dir ~= target_dir then
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

augroup("FixCmdLineIskeyword", {
	"CmdLineEnter",
	{
		desc = "Have consistent &iskeyword and &lisp in Ex command-line mode.",
		pattern = "[:>/?=@]",
		callback = function(info)
			-- Don't set &iskeyword and &lisp settings in insert/append command-line
			-- ('-'), if we are inserting into a lisp file, we want to have the same
			-- behavior as in insert mode
			--
			-- Change &iskeyword in search command-line ('/' or '?'), because we are
			-- searching for regex patterns not literal lisp words
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
		pattern = "[:>/?=@]",
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

augroup("Auto_Create_Dir", {
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
