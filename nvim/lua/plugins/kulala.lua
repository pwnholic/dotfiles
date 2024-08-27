return {
	"mistweaverco/kulala.nvim",
	ft = "http",
	opts = function()
		vim.api.nvim_create_user_command("KulalaRun", require("kulala").run, {})
		vim.api.nvim_create_user_command("KulalaToggle", require("kulala").toggle_view, {})
		vim.api.nvim_create_user_command("KulalaPrev", require("kulala").jump_prev, {})
		vim.api.nvim_create_user_command("KulalaNext", require("kulala").jump_next, {})
		return {
			icons = { inlay = { loading = "󱦟 ", done = " ", error = "󰬅 " } },
			contenttypes = {
				["application/json"] = {
					ft = "json",
					formatter = { "jq", "." },
					pathresolver = require("kulala.parser.jsonpath").parse,
				},
				["application/xml"] = {
					ft = "xml",
					formatter = { "xmllint", "--format", "-" },
					pathresolver = { "xmllint", "--xpath", "{{path}}", "-" },
				},
				["text/html"] = {
					ft = "html",
					formatter = { "xmllint", "--format", "--html", "-" },
					pathresolver = {},
				},
			},
		}
	end,
}
