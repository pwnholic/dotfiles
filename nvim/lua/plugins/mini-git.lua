return {
	"echasnovski/mini-git",
	main = "mini.git",
	cmd = "Git",
	keys = function()
		return {
			{
				"<leader>hg",
				function()
					vim.ui.input({ prompt = "Git Options : ", completion = "command" }, function(args)
						if args == "" then
							return vim.notify("Git need argument", 4, { title = "Git" })
						else
							vim.cmd.Git(args)
						end
					end)
				end,
				desc = "Git Wrapper",
			},
		}
	end,
	opts = function()
		return {
			job = { git_executable = "git", timeout = 30000 },
			command = { split = "auto" },
		}
	end,
}
