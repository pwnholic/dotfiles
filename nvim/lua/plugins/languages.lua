return {
	{
		"ray-x/go.nvim",
		branch = "master",
		opts = {
			go = "go",
			goimports = "gopls",
			fillstruct = "gopls",
			max_line_len = 0,
			gotests_template = "",
			gotests_template_dir = "",
			comment_placeholder = "",
			lsp_cfg = false,
			lsp_codelens = true,
			diagnostic = {
				hdlr = false,
				underline = true,
				virtual_text = { spacing = 2 },
				signs = { "", "", "", "" },
				update_in_insert = false,
			},
			lsp_document_formatting = true,
			gocoverage_sign = "█",
			dap_debug_gui = {
				floating = { border = "solid" },
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.2 },
							{ id = "breakpoints", size = 0.2 },
							{ id = "stacks", size = 0.2 },
							{ id = "watches", size = 0.2 },
							{ id = "console", size = 0.2 },
						},
						position = "right",
						size = 55,
					},
					{ elements = { { id = "repl", size = 1 } }, position = "bottom", size = 8 },
				},
			},
			test_runner = "go",
			verbose_tests = true,
			run_in_floaterm = false,
			gofmt = false,
			tag_transform = false,
			tag_options = "",
			icons = false,
			verbose = false,
			lsp_gofumpt = false,
			lsp_keymaps = false,
			lsp_inlay_hints = { enable = false },
			sign_priority = 5,
			textobjects = false,
			trouble = true,
			test_efm = false,
			luasnip = true,
			iferr_vertical_shift = 4,
			dap_debug = true,
			dap_debug_keymap = false,
			dap_debug_vt = { enabled_commands = true, all_frames = true },
			dap_port = 38697,
			dap_timeout = 15,
			dap_retries = 20,
		},
		ft = { "go", "gomod" },
		config = function(_, opts)
			require("go").setup(opts)
		end,
		-- build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
	},
}
