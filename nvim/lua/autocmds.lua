local function augroup(name)
	return vim.api.nvim_create_augroup(name, { clear = true })
end
local autocmd = vim.api.nvim_create_autocmd

return {
	setup = function()
		autocmd("BufReadPost", {
			desc = "Last position jump.",
			group = vim.api.nvim_create_augroup("LastPost", { clear = false }),
			callback = function()
				if not vim.tbl_contains({ "gitcommit", "gitrebase" }, vim.bo.filetype) then
					return vim.cmd.normal({ 'g`"zvzz', bang = true, mods = { emsg_silent = true } })
				end
			end,
		})

		autocmd("TextYankPost", {
			group = augroup("Hl on yank"),
			desc = "Highlight on yank",
			callback = function()
				vim.highlight.on_yank({ higroup = "LspReferenceText", priority = 250 })
			end,
		})

		autocmd({ "BufWinEnter", "FileChangedShellPost" }, {
			pattern = "*",
			group = augroup("AutoCwd"),
			desc = "Automatically change local current directory.",
			callback = function(opts)
				if opts.file == "" or vim.bo[opts.buf].bt ~= "" then
					return
				end
				local current_win = vim.api.nvim_get_current_win()
				vim.schedule(function()
					if
						not vim.api.nvim_buf_is_valid(opts.buf)
						or not vim.api.nvim_win_is_valid(current_win)
						or not vim.api.nvim_win_get_buf(current_win) == opts.buf
					then
						return
					end
					vim.api.nvim_win_call(current_win, function()
						local current_dir = vim.fn.getcwd(0)
						local target_dir = require("directory").project_dir(opts.file) or vim.fs.dirname(opts.file)
						local stat = target_dir and vim.uv.fs_stat(target_dir)
						if stat and stat.type == "directory" and current_dir ~= target_dir then
							vim.cmd.lcd(target_dir)
						end
					end)
				end)
			end,
		})

		-- Check if we need to reload the file when it changed
		autocmd({ "FocusGained", "TermClose", "TermLeave" }, { group = augroup("CheckTime"), command = "checktime" })

		-- Auto create dir when saving a file, in case some intermediate directory does not exist
		autocmd({ "BufWritePre" }, {
			group = augroup("AutoCreateDir"),
			callback = function(event)
				if event.match:match("^%w%w+://") then
					return
				end
				local file = vim.uv.fs_realpath(event.match) or event.match
				vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
			end,
		})

		autocmd("BufReadPre", {
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
							autocmd("BufReadPost", {
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
		})

		autocmd({ "BufWinEnter", "WinEnter", "UIEnter" }, {
			desc = "Show cursorline and cursorcolumn in current window.",
			group = augroup("AutoHlCursorLines"),
			callback = function()
				if vim.fn.mode():match("^[itRsS\x13]") then
					return
				end
				if vim.w._cul and not vim.wo.cul then
					vim.wo.cul = true
					vim.w._cul = nil
				end
				if vim.w._cuc and not vim.wo.cuc then
					vim.wo.cuc = true
					vim.w._cuc = nil
				end
			end,
		})

		autocmd("WinLeave", {
			desc = "Hide cursorline and cursorcolumn in other windows.",
			group = augroup("AutoHlCursorLines"),
			callback = function()
				if vim.wo.cul then
					vim.w._cul = true
					vim.wo.cul = false
				end
				if vim.wo.cuc then
					vim.w._cuc = true
					vim.wo.cuc = false
				end
			end,
		})

		autocmd("ModeChanged", {
			desc = "Hide cursorline and cursorcolumn in insert mode.",
			pattern = { "[itRss\x13]*:*", "*:[itRss\x13]*" },
			group = augroup("AutoHlCursorLines"),
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
		})
	end,
}
