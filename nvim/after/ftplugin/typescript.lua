local lsp = require("utils.lsp")

lsp.start({
	cmd = { vim.fn.stdpath("data") .. "/mason/bin/vtsls", "--stdio" },
	name = "vtsls",
	root_patterns = {
		"tsconfig.json",
		"jsconfig.json",
		"package.json",
		".git",
	},
	filetypes = {
		"javascript",
		"javascriptreact",
		"javascript.jsx",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
	},
	settings = {
		complete_function_calls = true,
		vtsls = {
			enableMoveToFileCodeAction = true,
			autoUseWorkspaceTsdk = true,
			experimental = {
				completion = {
					enableServerSideFuzzyMatch = true,
				},
			},
		},
		typescript = {
			updateImportsOnFileMove = { enabled = "always" },
			suggest = {
				completeFunctionCalls = true,
			},
			inlayHints = {
				enumMemberValues = { enabled = true },
				functionLikeReturnTypes = { enabled = true },
				parameterNames = { enabled = "literals" },
				parameterTypes = { enabled = true },
				propertyDeclarationTypes = { enabled = true },
				variableTypes = { enabled = false },
			},
		},
	},
})

lsp.on_attach(function(client, _)
	client.commands["_typescript.moveToFileRefactoring"] = function(command, _)
		---@type string, string, lsp.Range
		local action, uri, range = unpack(command.arguments)

		local function move(newf)
			client.request("workspace/executeCommand", {
				command = command.command,
				arguments = { action, uri, range, newf },
			})
		end

		local fname = vim.uri_to_fname(uri)
		client.request("workspace/executeCommand", {
			command = "typescript.tsserverRequest",
			arguments = {
				"getMoveToRefactoringFileSuggestions",
				{
					file = fname,
					startLine = range.start.line + 1,
					startOffset = range.start.character + 1,
					endLine = range["end"].line + 1,
					endOffset = range["end"].character + 1,
				},
			},
		}, function(_, result)
			---@type string[]
			local files = result.body.files
			table.insert(files, 1, "Enter new path...")
			vim.ui.select(files, {
				prompt = "Select move destination:",
				format_item = function(f)
					return vim.fn.fnamemodify(f, ":~:.")
				end,
			}, function(f)
				if f and f:find("^Enter new path") then
					vim.ui.input({
						prompt = "Enter move destination:",
						default = vim.fn.fnamemodify(fname, ":h") .. "/",
						completion = "file",
					}, function(newf)
						return newf and move(newf)
					end)
				elseif f then
					move(f)
				end
			end)
		end)
	end
end, "vtsls")

vim.keymap.set("n", "gD", function()
	local params = vim.lsp.util.make_position_params()
	lsp.execute({
		command = "typescript.goToSourceDefinition",
		arguments = { params.textDocument.uri, params.position },
		open = true,
	})
end, { desc = "Goto Source Definition" })

vim.keymap.set("n", "gR", function()
	lsp.execute({
		command = "typescript.findAllFileReferences",
		arguments = { vim.uri_from_bufnr(0) },
		open = true,
	})
end, { desc = "File References" })
