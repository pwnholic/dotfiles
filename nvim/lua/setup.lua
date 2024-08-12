local methods = vim.lsp.protocol.Methods
vim.diagnostic.config(require("utils.lsp").diagnostics_config)

vim.api.nvim_create_autocmd("LspAttach", {
	once = true,
	desc = "Apply lsp and diagnostic settings.",
	group = vim.api.nvim_create_augroup("LspDiagnosticSetup", {}),
	callback = function(opts)
		local lsp = require("utils.lsp")
		lsp.setup_lsp_stopidle()
		lsp.setup_commands("Lsp", lsp.subcommands.lsp, function(name)
			return vim.lsp[name] or vim.lsp.buf[name]
		end, opts.buf)
		lsp.setup_commands("Diagnostic", lsp.subcommands.diagnostic, vim.diagnostic)
		return true
	end,
})

require("utils.lsp").on_attach(function(client, buffer)
	require("utils.lsp").keys_on_attach(client, buffer)
	if client.supports_method(methods.textDocument_inlayHint) then
		if
			vim.api.nvim_buf_is_loaded(buffer)
			and vim.bo[buffer].buftype == ""
			and not vim.tbl_contains({}, vim.bo[buffer].filetype)
		then
			vim.lsp.inlay_hint.enable(false, { bufnr = buffer })
		end
	end

	-- if client.supports_method(methods.textDocument_codeLens) then
	-- 	vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
	-- 		buffer = buffer,
	-- 		callback = vim.lsp.codelens.refresh,
	-- 	})
	-- end
end)

local register_capability = vim.lsp.handlers["client/registerCapability"]
vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
	local ret = register_capability(err, res, ctx)
	local lsp = require("utils.lsp")
	local client = vim.lsp.get_client_by_id(ctx.client_id)
	if client then
		for buffer in pairs(client.attached_buffers) do
			lsp.keys_on_attach(client, buffer)
			lsp.setup_commands("Lsp", lsp.subcommands.lsp, function(name)
				return vim.lsp[name] or vim.lsp.buf[name]
			end, buffer)
		end
	end
	return ret
end

vim.schedule(function()
	local utils = require("utils.tmux")
	if vim.g.loaded_tmux or not vim.env.TMUX then
		return
	end
	vim.g.loaded_tmux = true

    -- stylua: ignore start
	utils.tmux_mapkey_fallback("<A-h>", utils.navigate_wrap("h"), utils.tmux_mapkey_navigate_condition("h"))
	utils.tmux_mapkey_fallback("<A-j>", utils.navigate_wrap("j"), utils.tmux_mapkey_navigate_condition("j"))
	utils.tmux_mapkey_fallback("<A-k>", utils.navigate_wrap("k"), utils.tmux_mapkey_navigate_condition("k"))
	utils.tmux_mapkey_fallback("<A-l>", utils.navigate_wrap("l"), utils.tmux_mapkey_navigate_condition("l"))

	-- utils.tmux_mapkey_fallback("<A-p>", "last-pane")
	utils.tmux_mapkey_fallback("<A-R>", "swap-pane -U")
	utils.tmux_mapkey_fallback("<A-r>", "swap-pane -D")
	utils.tmux_mapkey_fallback("<A-o>", "confirm 'kill-pane -a'")
	utils.tmux_mapkey_fallback("<A-=>", "confirm 'select-layout tiled'")
	utils.tmux_mapkey_fallback("<A-c>", "confirm kill-pane", utils.tmux_mapkey_close_win_condition)
	utils.tmux_mapkey_fallback("<A-q>", "confirm kill-pane", utils.tmux_mapkey_close_win_condition)
	utils.tmux_mapkey_fallback("<A-<>", "resize-pane -L 4", utils.tmux_mapkey_resize_pane_horiz_condition)
	utils.tmux_mapkey_fallback("<A->>", "resize-pane -R 4", utils.tmux_mapkey_resize_pane_horiz_condition)
	utils.tmux_mapkey_fallback("<A-,>", "resize-pane -L 4", utils.tmux_mapkey_resize_pane_horiz_condition)
	utils.tmux_mapkey_fallback("<A-.>", "resize-pane -R 4", utils.tmux_mapkey_resize_pane_horiz_condition)
	utils.tmux_mapkey_fallback("<A-->", [[run "tmux resize-pane -y $(($(tmux display -p '#{pane_height}') - 2))"]], utils.tmux_mapkey_resize_pane_vert_condition)
	utils.tmux_mapkey_fallback("<A-+>", [[run "tmux resize-pane -y $(($(tmux display -p '#{pane_height}') + 2))"]], utils.tmux_mapkey_resize_pane_vert_condition)
	-- stylua: ignore end

	-- Set @is_vim and register relevant autocmds callbacks if not already
	-- in a vim/nvim session
	if utils.tmux_get_pane_opt("@is_vim") == "" then
		utils.tmux_set_pane_opt("@is_vim", "yes")
		local groupid = vim.api.nvim_create_augroup("TmuxNavSetIsVim", {})
		vim.api.nvim_create_autocmd("VimResume", {
			desc = "Set @is_vim in tmux pane options after vim resumes.",
			group = groupid,
			callback = function()
				utils.tmux_set_pane_opt("@is_vim", "yes")
			end,
		})
		vim.api.nvim_create_autocmd({ "VimSuspend", "VimLeave" }, {
			desc = "Unset @is_vim in tmux pane options on vim leaving or suspending.",
			group = groupid,
			callback = function()
				utils.tmux_unset_pane_opt("@is_vim")
			end,
		})
	end
end)
