vim.filetype.add({
	extension = {
		cconf = "python",
		frag = "glsl",
		norg = "norg",
		rbi = "ruby",
		sky = "starlark",
		templ = "templ",
		http = "http",
		env = "sh",
		pyi = "python",
		conf = "sh",
	},
	pattern = {
		[".*/%.vscode/.*%.json"] = "json5", -- These json files frequently have comments
	},
})
