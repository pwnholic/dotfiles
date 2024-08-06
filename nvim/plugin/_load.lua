vim.keymap.set({ "i", "c" }, "<Tab>", function()
	require("utils.cmp").jump(1)
end)
vim.keymap.set({ "i", "c" }, "<S-Tab>", function()
	require("utils.cmp").jump(-1)
end)

require("utils.lsp").on_attach(function(client, buffer)
	require("utils.lsp").keys_on_attach(client, buffer)
end)

vim.diagnostic.config({
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = require("utils.icons").diagnostics.ERROR,
			[vim.diagnostic.severity.WARN] = require("utils.icons").diagnostics.WARN,
			[vim.diagnostic.severity.INFO] = require("utils.icons").diagnostics.HINT,
			[vim.diagnostic.severity.HINT] = require("utils.icons").diagnostics.INFO,
		},
		numhl = {
			[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
			[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
			[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
			[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
		},
	},
	virtual_text = {
		spacing = 4,
		source = "if_many",
		prefix = "",
		format = function(d)
			local dicons = {}
			for key, value in pairs(require("utils.icons").diagnostics) do
				dicons[key:upper()] = value
			end
			return string.format(" %s : %s ", dicons[vim.diagnostic.severity[d.severity]], d.message)
		end,
	},
	float = {
		header = setmetatable({}, {
			__index = function(_, k)
				local icon, hl = require("mini.icons").get("file", vim.api.nvim_buf_get_name(0))
				local arr = {
					function()
						return string.format("Diagnostics: %s  %s", icon, vim.bo.filetype)
					end,
					function()
						return hl
					end,
				}
				return arr[k]()
			end,
		}),
		format = function(d)
			return string.format("[%s] : %s", d.source, d.message)
		end,
		source = "if_many",
		severity_sort = true,
		wrap = true,
		border = "single",
		max_width = math.floor(vim.o.columns / 2),
		max_height = math.floor(vim.o.lines / 3),
	},
})

vim.api.nvim_create_autocmd({ "LspAttach", "DiagnosticChanged" }, {
	once = true,
	desc = "Apply lsp and diagnostic settings.",
	group = vim.api.nvim_create_augroup("LspDiagnosticSetup", {}),
	callback = function()
		local lsp = require("utils.lsp")
		local register_capability = vim.lsp.handlers["client/registerCapability"]
		vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
			local ret = register_capability(err, res, ctx)
			local client = vim.lsp.get_client_by_id(ctx.client_id)
			if client then
				for buffer in pairs(client.attached_buffers) do
					require("utils.lsp").keys_on_attach(client, buffer)
				end
			end
			return ret
		end

		lsp.setup_lsp_stopidle()
		lsp.setup_commands("Lsp", lsp.subcommands.lsp, function(name)
			return vim.lsp[name] or vim.lsp.buf[name]
		end)
		lsp.setup_commands("Diagnostic", lsp.subcommands.diagnostic, vim.diagnostic)
		return true
	end,
})

vim.schedule(function()
	local utils = require("utils.tmux")
	if vim.g.loaded_tmux or not vim.env.TMUX then
		return
	end
	vim.g.loaded_tmux = true

	utils.tmux_mapkey_fallback("<M-h>", utils.navigate_wrap("h"), utils.tmux_mapkey_navigate_condition("h"))
	utils.tmux_mapkey_fallback("<M-j>", utils.navigate_wrap("j"), utils.tmux_mapkey_navigate_condition("j"))
	utils.tmux_mapkey_fallback("<M-k>", utils.navigate_wrap("k"), utils.tmux_mapkey_navigate_condition("k"))
	utils.tmux_mapkey_fallback("<M-l>", utils.navigate_wrap("l"), utils.tmux_mapkey_navigate_condition("l"))

	utils.tmux_mapkey_fallback("<M-p>", "last-pane")
	utils.tmux_mapkey_fallback("<M-R>", "swap-pane -U")
	utils.tmux_mapkey_fallback("<M-r>", "swap-pane -D")
	utils.tmux_mapkey_fallback("<M-o>", "confirm 'kill-pane -a'")
	utils.tmux_mapkey_fallback("<M-=>", "confirm 'select-layout tiled'")
	utils.tmux_mapkey_fallback("<M-c>", "confirm kill-pane", utils.tmux_mapkey_close_win_condition)
	utils.tmux_mapkey_fallback("<M-q>", "confirm kill-pane", utils.tmux_mapkey_close_win_condition)
	utils.tmux_mapkey_fallback("<M-<>", "resize-pane -L 4", utils.tmux_mapkey_resize_pane_horiz_condition)
	utils.tmux_mapkey_fallback("<M->>", "resize-pane -R 4", utils.tmux_mapkey_resize_pane_horiz_condition)
	utils.tmux_mapkey_fallback("<M-,>", "resize-pane -L 4", utils.tmux_mapkey_resize_pane_horiz_condition)
	utils.tmux_mapkey_fallback("<M-.>", "resize-pane -R 4", utils.tmux_mapkey_resize_pane_horiz_condition)
	utils.tmux_mapkey_fallback(
		"<M-->",
		[[run "tmux resize-pane -y $(($(tmux display -p '#{pane_height}') - 2))"]],
		utils.tmux_mapkey_resize_pane_vert_condition
	)
	utils.tmux_mapkey_fallback(
		"<M-+>",
		[[run "tmux resize-pane -y $(($(tmux display -p '#{pane_height}') + 2))"]],
		utils.tmux_mapkey_resize_pane_vert_condition
	)

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
