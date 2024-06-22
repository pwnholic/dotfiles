vim.opt_local.expandtab = true -- Use spaces instead of tabs

local get_current_gomod = function()
	local file = io.open("go.mod", "r")
	if file == nil then
		return nil
	end

	local first_line = file:read()
	local mod_name = first_line:gsub("module ", "")
	file:close()
	return mod_name
end

require("utils.lsp").start({
	on_attach = function(client, _)
		if not client.server_capabilities.semanticTokensProvider then
			local semantic = client.config.capabilities.textDocument.semanticTokens
			client.server_capabilities.semanticTokensProvider = {
				full = true,
				legend = { tokenTypes = semantic.tokenTypes, tokenModifiers = semantic.tokenModifiers },
				range = true,
			}
		end
	end,
	capabilities = {
		textDocument = {
			completion = {
				completionItem = {
					commitCharactersSupport = true,
					deprecatedSupport = true,
					documentationFormat = { "markdown", "plaintext" },
					preselectSupport = true,
					insertReplaceSupport = true,
					labelDetailsSupport = true,
					snippetSupport = vim.snippet and true or false,
					resolveSupport = {
						properties = {
							"edit",
							"documentation",
							"details",
							"additionalTextEdits",
						},
					},
				},
				completionList = {
					itemDefaults = {
						"editRange",
						"insertTextFormat",
						"insertTextMode",
						"data",
					},
				},
				contextSupport = true,
				dynamicRegistration = true,
			},
		},
	},
	filetypes = { "go", "gomod", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },
	message_level = vim.lsp.protocol.MessageType.Error,
	cmd = {
		"gopls", -- share the gopls instance if there is one already
		"-remote.debug=:0",
	},
	flags = { allow_incremental_sync = true, debounce_text_changes = 500 },
	settings = {
		gopls = {
			analyses = {
				append = true,
				asmdecl = true,
				assign = true,
				atomic = true,
				unreachable = true,
				nilness = true,
				ST1003 = true,
				undeclaredname = true,
				fillreturns = true,
				nonewvars = true,
				fieldalignment = true,
				shadow = true,
				unusedvariable = true,
				unusedparams = true,
				useany = true,
				unusedwrite = true,
			},
			codelenses = {
				generate = true, -- show the `go generate` lens.
				gc_details = true, -- Show a code lens toggling the display of gc's choices.
				test = true,
				tidy = true,
				vendor = true,
				regenerate_cgo = true,
				upgrade_dependency = true,
			},
			hints = {
				assignVariableTypes = true,
				compositeLiteralFields = true,
				compositeLiteralTypes = true,
				constantValues = true,
				functionTypeParameters = true,
				parameterNames = true,
				rangeVariableTypes = true,
			},
			usePlaceholders = true,
			completeUnimported = true,
			staticcheck = true,
			matcher = "Fuzzy",
			-- check if diagnostic update_in_insert is set
			diagnosticsDelay = "250ms",
			diagnosticsTrigger = "Save",
			symbolMatcher = "FastFuzzy",
			semanticTokens = true,
			noSemanticString = true, -- disable semantic string tokens so we can use treesitter highlight injection
			vulncheck = "Imports",
			["local"] = get_current_gomod(),
			gofumpt = false,
			buildFlags = { "-tags", "integration" },
		},
	},
})

local function input(prompt, cmd)
	return function()
		vim.ui.input({ prompt = prompt }, function(name)
			if name ~= "" then
				return vim.cmd[cmd](name)
			end
		end)
	end
end

vim.keymap.set("n", "<leader>jw", vim.cmd.GoFillSwitch, { desc = "Fill Switch" })
vim.keymap.set("n", "<leader>jf", vim.cmd.GoFillStruct, { desc = "Auto Sill Struct" })
vim.keymap.set("n", "<leader>je", vim.cmd.GoIfErr, { desc = "Add If Err" })
vim.keymap.set("n", "<leader>jd", vim.cmd.GoDebug, { desc = "Go Debug" })
vim.keymap.set("n", "<leader>jp", vim.cmd.GoFixPlurals, { desc = "Fix Plurals Func" })
vim.keymap.set("n", "<leader>jC", vim.cmd.GoClearname, { desc = "Clear All names" })
vim.keymap.set("n", "<leader>jc", vim.cmd.GoCmt, { desc = "Add comment" })
vim.keymap.set("n", "<leader>ja", vim.cmd.GoModInit, { desc = "`go mod init`" })
vim.keymap.set("n", "<leader>jv", vim.cmd.GoModVendor, { desc = "`go mod vendor`" })
vim.keymap.set("n", "<leader>jy", vim.cmd.GoModTidy, { desc = "`go mod tidy`" })
vim.keymap.set("n", "<leader>jT", vim.cmd.GoAddTest, { desc = "Add New Test File" })
vim.keymap.set({ "n", "v" }, "<leader>jt", input("Add name : ", "GoAddTag"), { desc = "Add Tags" })
vim.keymap.set({ "n", "v" }, "<leader>jr", input("Remove name : ", "GoRmTag"), { desc = "Remove Tags" })
vim.keymap.set("n", "<leader>jn", input("New File : ", "GoNew"), { desc = "GoNew `package name` `location`" })
vim.keymap.set(
	"n",
	"<leader>ji",
	input("Struct -> Interface : ", "GoImpl"),
	{ desc = "GoImpl `struct name` `interface`" }
)
