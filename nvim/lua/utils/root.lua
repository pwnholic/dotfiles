local lazy_utils = require("lazy.core.util")

local M = {}

function M.is_win()
	return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

function M.norm(path)
	if path:sub(1, 1) == "~" then
		local home = vim.uv.os_homedir()
		if home:sub(-1) == "\\" or home:sub(-1) == "/" then
			home = home:sub(1, -2)
		end
		path = home .. path:sub(2)
	end
	path = path:gsub("\\", "/"):gsub("/+", "/")
	return path:sub(-1) == "/" and path:sub(1, -2) or path
end

---@param plugin string
function M.has(plugin)
	return require("lazy.core.config").spec.plugins[plugin] ~= nil
end

---@class GetRoot
---@field paths string[]
---@field spec GetRootSpec

---@alias GetRoonFn fun(buf: number): (string|string[])

---@alias GetRootSpec string|string[]|GetRoonFn

---@type GetRootSpec[]
M.spec = { "lsp", { ".git", "lua" }, "cwd" }

M.detectors = {}

function M.detectors.cwd()
	return { vim.uv.cwd() }
end

function M.get_clients(opts)
	local ret = {} ---@type lsp.Client[]
	if vim.lsp.get_clients then
		ret = vim.lsp.get_clients(opts)
	else
		---@diagnostic disable-next-line: deprecated
		ret = vim.lsp.get_active_clients(opts)
		if opts and opts.method then
			---@param client lsp.Client
			ret = vim.tbl_filter(function(client)
				return client.supports_method(opts.method, { bufnr = opts.bufnr })
			end, ret)
		end
	end
	return opts and opts.filter and vim.tbl_filter(opts.filter, ret) or ret
end

function M.detectors.lsp(buf)
	local bufpath = M.bufpath(buf)
	if not bufpath then
		return {}
	end
	local roots = {} ---@type string[]
	for _, client in pairs(M.get_clients({ bufnr = buf })) do
		-- only check workspace folders, since we're not interested in clients
		-- running in single file mode
		local workspace = client.config.workspace_folders
		for _, ws in pairs(workspace or {}) do
			roots[#roots + 1] = vim.uri_to_fname(ws.uri)
		end
	end
	return vim.tbl_filter(function(path)
		path = M.norm(path)
		return path and bufpath:find(path, 1, true) == 1
	end, roots)
end

---@param patterns string[]|string
function M.detectors.pattern(buf, patterns)
	patterns = type(patterns) == "string" and { patterns } or patterns
	local path = M.bufpath(buf) or vim.uv.cwd()
	local pattern = vim.fs.find(patterns, { path = path, upward = true })[1]
	return pattern and { vim.fs.dirname(pattern) } or {}
end

function M.bufpath(buf)
	return M.realpath(vim.api.nvim_buf_get_name(assert(buf)))
end

function M.get_cwd()
	return M.realpath(vim.uv.cwd()) or ""
end

function M.realpath(path)
	if path == "" or path == nil then
		return nil
	end
	path = vim.uv.fs_realpath(path) or path
	return M.norm(path)
end

---@param spec GetRootSpec
---@return GetRoonFn
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

---@param opts? { buf?: number, spec?: GetRootSpec[], all?: boolean }
function M.detect(opts)
	opts = opts or {}
	opts.spec = opts.spec or type(vim.g.root_spec) == "table" and vim.g.root_spec or M.spec
	opts.buf = (opts.buf == nil or opts.buf == 0) and vim.api.nvim_get_current_buf() or opts.buf

	local ret = {} ---@type GetRoot[]
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
	lazy_utils.info(lines, { title = "Root Path" })
	return roots[1] and roots[1].paths[1] or vim.uv.cwd()
end

---@type table<number, string>
M.cache = {}

function M.setup()
	vim.api.nvim_create_user_command("RootPath", function()
		M.info()
	end, { desc = "LazyVim roots for the current buffer" })
	vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost", "DirChanged" }, {
		group = vim.api.nvim_create_augroup("vim_root_cache", { clear = true }),
		callback = function(event)
			M.cache[event.buf] = nil
		end,
	})
end

-- returns the root directory based on:
-- * lsp workspace folders
-- * lsp root_dir
-- * root pattern of filename of the current buffer
-- * root pattern of cwd
---@param opts? {normalize?:boolean}
---@return string
function M.get_root(opts)
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
	return M.is_win() and ret:gsub("/", "\\") or ret
end

function M.get_git()
	local root = M.get_root()
	local git_root = vim.fs.find(".git", { path = root, upward = true })[1]
	local ret = git_root and vim.fn.fnamemodify(git_root, ":h") or root
	return ret
end

---@param opts? {hl_last?: string}
function M.pretty_path(opts)
	return ""
end

return M
