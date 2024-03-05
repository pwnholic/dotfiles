local root_patterns = {
	".git/",
	".svn/",
	".bzr/",
	".hg/",
	".pro",
	".sln",
	".project/",
	".vcxproj",
	"Makefile",
	"makefile",
	"MAKEFILE",
	".gitignore",
	".editorconfig",
}

local ignore_folder = {
	-- HOME
	".cache",
	".local",
	".java",
	".config",
	-- ".var",
	".gnome",

	-- Dev
	".git",
	".obsidian",
	".next",
	".idea",
	".vscode",
	".yarn",

	-- "lib",
	"node_modules",
	"tmp",
	"temp",
	"bin",
	"db",
	"vendor",
	"debug",
	"dist",
	"build",
	"reports",
	"pkg",
}

local ignore_file = {
	"*_templ.go",
	"*.bin",
}

local detectors = {}

function detectors.cwd()
	return { vim.uv.cwd() }
end

local function get_clients(opts)
	local ret = {}
	if vim.lsp.get_clients then
		ret = vim.lsp.get_clients(opts)
	end
	return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
end

local function realpath(path)
	if path == "" or path == nil then
		return nil
	end
	path = vim.uv.fs_realpath(path) or path
	return vim.fs.normalize(path)
end

local function bufpath(buf)
	return realpath(vim.api.nvim_buf_get_name(assert(buf)))
end

function detectors.pattern(buf, patterns)
	patterns = type(patterns) == "string" and { patterns } or patterns
	local path = bufpath(buf) or vim.uv.cwd()
	local pattern = vim.fs.find(patterns, { path = path, upward = true })[1]
	return pattern and { vim.fs.dirname(pattern) } or {}
end

function detectors.lsp(buf)
	local bp = bufpath(buf)
	if not bp then
		return {}
	end
	local roots = {}
	for _, client in pairs(get_clients({ bufnr = buf })) do
		local workspace = client.config.workspace_folders
		for _, ws in pairs(workspace or {}) do
			roots[#roots + 1] = vim.uri_to_fname(ws.uri)
		end
	end
	return vim.tbl_filter(function(path)
		path = vim.fs.normalize(path)
		return path and bp:find(path, 1, true) == 1
	end, roots)
end

local function resolve(spec)
	if detectors[spec] then
		return detectors[spec]
	elseif type(spec) == "function" then
		return spec
	end
	return function(buf)
		return detectors.pattern(buf, spec)
	end
end

local function detect(opts)
	opts = opts or {}
	opts.spec = { "lsp", { ".git", "lua" }, "cwd" }
	opts.buf = (opts.buf == nil or opts.buf == 0) and vim.api.nvim_get_current_buf() or opts.buf
	local ret = {}
	for _, spec in ipairs(opts.spec) do
		local paths = resolve(spec)(opts.buf)
		paths = paths or {}
		paths = type(paths) == "table" and paths or { paths }
		local roots = {} ---@type string[]
		for _, p in ipairs(paths) do
			local pp = realpath(p)
			if pp and not vim.tbl_contains(roots, pp) then
				roots[#roots + 1] = pp
			end
		end
		table.sort(roots, function(a, b)
			return #a > #b
		end)
		if #roots > 0 then
			ret[#ret + 1] = { spec = spec, paths = roots }
			if opts.all == false then
				break
			end
		end
	end
	return ret
end

local cache = {}

vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost" }, {
	group = vim.api.nvim_create_augroup("root_cache", { clear = true }),
	callback = function(event)
		cache[event.buf] = nil
	end,
})

local function get_cwd()
	return realpath(vim.uv.cwd()) or ""
end

local function get_root(opts)
	local buf = vim.api.nvim_get_current_buf()
	local ret = cache[buf]
	if not ret then
		local roots = detect({ all = false })
		ret = roots[1] and roots[1].paths[1] or vim.uv.cwd()
		cache[buf] = ret
	end
	if opts and opts.normalize then
		return ret
	end
	return ret
end

local function project_dir(path, patterns)
	if not path or path == "" then
		return nil
	end
	patterns = patterns or root_patterns
	local stat = vim.uv.fs_stat(path)
	if not stat then
		return
	end
	local dirpath = stat.type == "directory" and path or vim.fs.dirname(path)
	for _, pattern in ipairs(patterns) do
		local root = vim.fs.find(pattern, { path = dirpath, upward = true, type = pattern:match("/$") and "directory" or "file" })[1]
		if root and vim.uv.fs_stat(root) then
			local dirname = vim.fs.dirname(root)
			return dirname and vim.uv.fs_realpath(dirname) --[[@as string]]
		end
	end
end

return {
	get_root = get_root,
	get_cwd = get_cwd,
	project_dir = project_dir,
	ignore_folder = ignore_folder,
	ignore_file = ignore_file,
}
