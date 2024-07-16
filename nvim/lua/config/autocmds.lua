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

			if vim.g.bigfile_size > (1024 * 1024 * 2) then
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

augroup("ColorfullHL", {
	"ModeChanged",
	{
		callback = function()
			local c = require("tokyonight.colors").setup()
			local cutil = require("tokyonight.util")
			local color = ({
				n = c.blue2,
				i = c.green,
				v = c.magenta,
				V = c.cyan,
				["\22"] = c.red,
				c = c.orange,
				s = c.yellow,
				S = c.yellow,
				["\19"] = c.yellow,
				r = c.green,
				["!"] = c.red,
				R = c.red,
				t = c.teal,
			})[vim.fn.mode():sub(1, 1)]
			vim.api.nvim_set_hl(0, "CursorLineNr", { fg = color, bg = c.none, bold = true })
			vim.api.nvim_set_hl(0, "TermCursor", { bg = color })
			vim.api.nvim_set_hl(0, "Cursor", { bg = cutil.darken(color, 0.3), bold = true })
			vim.api.nvim_set_hl(0, "Visual", { bg = cutil.darken(color, 0.3), bold = true })
			vim.api.nvim_set_hl(0, "VisualNOS", { bg = cutil.darken(color, 0.3), bold = true })
		end,
	},
})

return augroup
