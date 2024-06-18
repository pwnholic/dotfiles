local utils = require("utils")
local lazy_util = require("lazy.util")

local M = setmetatable({}, {
	__call = function(m)
		return m.get()
	end,
})

M.spec = { "lsp", { ".git", "lua" }, "cwd" }

M.detectors = {}

function M.detectors.cwd()
	return { vim.uv.cwd() }
end

function M.detectors.lsp(buf)
	local bufpath = M.bufpath(buf)
	if not bufpath then
		return {}
	end
	local roots = {} ---@type string[]
	for _, client in pairs(utils.lsp.get_clients({ bufnr = buf })) do
		-- only check workspace folders, since we're not interested in clients
		-- running in single file mode
		local workspace = client.config.workspace_folders
		for _, ws in pairs(workspace or {}) do
			roots[#roots + 1] = vim.uri_to_fname(ws.uri)
		end
	end
	return vim.tbl_filter(function(path)
		path = lazy_util.norm(path)
		return path and bufpath:find(path, 1, true) == 1
	end, roots)
end

---@param patterns string[]|string
function M.detectors.pattern(buf, patterns)
	patterns = type(patterns) == "string" and { patterns } or patterns
	local path = M.bufpath(buf) or vim.uv.cwd()
	local pattern = vim.fs.find(function(name)
		for _, p in ipairs(patterns) do
			if name == p then
				return true
			end
			if p:sub(1, 1) == "*" and name:find(vim.pesc(p:sub(2)) .. "$") then
				return true
			end
		end
		return false
	end, { path = path, upward = true })[1]
	return pattern and { vim.fs.dirname(pattern) } or {}
end

function M.bufpath(buf)
	return M.realpath(vim.api.nvim_buf_get_name(assert(buf)))
end

function M.cwd()
	return M.realpath(vim.uv.cwd()) or ""
end

function M.realpath(path)
	if path == "" or path == nil then
		return nil
	end
	path = vim.uv.fs_realpath(path) or path
	return lazy_util.norm(path)
end

---@param spec LazyRootSpec
---@return LazyRootFn
function M.resolve(spec)
	if M.detectors[spec] then
		return M.detectors[spec]
	elseif type(spec) == "function" then
		return spec
	end
	return function(buf)
		return M.detectors.pattern(buf, spec)
	end
end

---@param opts? { buf?: number, spec?: LazyRootSpec[], all?: boolean }
function M.detect(opts)
	opts = opts or {}
	opts.spec = opts.spec or type(vim.g.root_spec) == "table" and vim.g.root_spec or M.spec
	opts.buf = (opts.buf == nil or opts.buf == 0) and vim.api.nvim_get_current_buf() or opts.buf

	local ret = {} ---@type LazyRoot[]
	for _, spec in ipairs(opts.spec) do
		local paths = M.resolve(spec)(opts.buf)
		paths = paths or {}
		paths = type(paths) == "table" and paths or { paths }
		local roots = {} ---@type string[]
		for _, p in ipairs(paths) do
			local pp = M.realpath(p)
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

function M.info()
	local spec = type(vim.g.root_spec) == "table" and vim.g.root_spec or M.spec

	local roots = M.detect({ all = true })
	local lines = {} ---@type string[]
	local first = true
	for _, root in ipairs(roots) do
		for _, path in ipairs(root.paths) do
			lines[#lines + 1] = ("- [%s] `%s` **(%s)**"):format(
				first and "x" or " ",
				path,
				type(root.spec) == "table" and table.concat(root.spec, ", ") or root.spec
			)
			first = false
		end
	end
	lines[#lines + 1] = "```lua"
	lines[#lines + 1] = "vim.g.root_spec = " .. vim.inspect(spec)
	lines[#lines + 1] = "```"
	lazy_util.info(lines, { title = "Roots" })
	return roots[1] and roots[1].paths[1] or vim.uv.cwd()
end

---@type table<number, string>
M.cache = {}

-- returns the root directory based on:
-- * lsp workspace folders
-- * lsp root_dir
-- * root pattern of filename of the current buffer
-- * root pattern of cwd
---@param opts? {normalize?:boolean}
---@return string
function M.get(opts)
	local buf = vim.api.nvim_get_current_buf()
	local ret = M.cache[buf]
	if not ret then
		local roots = M.detect({ all = false })
		ret = roots[1] and roots[1].paths[1] or vim.uv.cwd()
		M.cache[buf] = ret
	end
	if opts and opts.normalize then
		return ret
	end
	return utils.is_win() and ret:gsub("/", "\\") or ret
end

function M.git()
	local root = M.get()
	local git_root = vim.fs.find(".git", { path = root, upward = true })[1]
	local ret = git_root and vim.fn.fnamemodify(git_root, ":h") or root
	return ret
end

---@param opts? {hl_last?: string}
function M.pretty_path(opts)
	return ""
end

M.root_patterns = {
	".git/",
	".svn/",
	".bzr/",
	".hg/",
	".project/",
	".pro",
	".sln",
	".vcxproj",
	"Makefile",
	"makefile",
	"MAKEFILE",
	".gitignore",
	".editorconfig",
}

---Compute project directory for given path.
---@param path string?
---@param patterns string[]? root patterns
---@return string? nil if not found
function M.proj_dir(path, patterns)
	if not path or path == "" then
		return nil
	end
	patterns = patterns or M.root_patterns
	---@diagnostic disable-next-line: undefined-field
	local stat = vim.uv.fs_stat(path)
	if not stat then
		return
	end
	local dirpath = stat.type == "directory" and path or vim.fs.dirname(path)
	for _, pattern in ipairs(patterns) do
		local root = vim.fs.find(pattern, {
			path = dirpath,
			upward = true,
			type = pattern:match("/$") and "directory" or "file",
		})[1]
		if root and vim.uv.fs_stat(root) then
			local dirname = vim.fs.dirname(root)
			return dirname and vim.uv.fs_realpath(dirname) --[[@as string]]
		end
	end
end

return M
