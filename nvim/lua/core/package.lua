---Print git command error
---@param cmd string[] shell command
---@param msg string error message
---@param lev number? log level to use for errors, defaults to WARN
---@return nil
local function error(cmd, msg, lev)
	lev = lev or vim.log.levels.WARN
	vim.notify("[git] failed to execute git command: " .. table.concat(cmd, " ") .. "\n" .. msg, lev)
end

---Execute git command in given directory synchronously
---@param path string
---@param cmd string[] git command to execute
---@param error_lev number? log level to use for errors, hide errors if nil or false
---@reurn { success: boolean, output: string }
local function dir_execute(path, cmd, error_lev)
	local shell_args = { "git", "-C", path, table.unpack(cmd) }
	local shell_out = vim.fn.system(shell_args)
	if vim.v.shell_error ~= 0 then
		if error_lev then
			error(shell_args, shell_out, error_lev)
		end
		return { success = false, output = shell_out }
	end
	return { success = true, output = shell_out }
end

---Execute git command in current directory synchronously
---@param cmd string[] git command to execute
---@param error_lev number? log level to use for errors, hide errors if nil or false
---@return { success: boolean, output: string }
local function execute(cmd, error_lev)
	local shell_args = { "git", unpack(cmd) }
	local shell_out = vim.fn.system(shell_args)
	if vim.v.shell_error ~= 0 then
		if error_lev then
			error(shell_args, shell_out, error_lev)
		end
		return { success = false, output = shell_out }
	end
	return { success = true, output = shell_out }
end

---Read file contents
---@param path string
---@return string?
local function read_file(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content or ""
end

---Write string into file
---@param path string
---@return boolean success
local function write_file(path, str)
	local file = io.open(path, "w")
	if not file then
		return false
	end
	file:write(str)
	file:close()
	return true
end

---Write json contents
---@param path string
---@param tbl table
---@return boolean success
local function write(path, tbl)
	local ok, str = pcall(vim.json.encode, tbl)
	if not ok then
		return false
	end
	return write_file(path, str)
end

---Read json contents as lua table
---@param path string
---@param opts table? same option table as `vim.json.decode()`
---@return table
local function read(path, opts)
	opts = opts or {}
	local str = read_file(path)
	local ok, tbl = pcall(vim.json.decode, str, opts)
	return ok and tbl or {}
end

local conf_path = vim.fn.stdpath("config") --[[@as string]]
local data_path = vim.fn.stdpath("data") --[[@as string]]
local state_path = vim.fn.stdpath("state") --[[@as string]]
local package_path = vim.fs.joinpath(data_path, "packages")
local package_lock = vim.fs.joinpath(conf_path, "package-lock.json")
local lazy_path = vim.fs.joinpath(package_path, "lazy.nvim")

---Install package manager if not already installed
---@return boolean success
local function bootstrap()
	if vim.uv.fs_stat(lazy_path) then
		vim.opt.rtp:prepend(lazy_path)
		return true
	end

	local startup_file = vim.fs.joinpath(state_path, "startup.json")
	local startup_data = read(startup_file)
	if startup_data.bootstrap == false then
		return false
	end

	local response = ""
	vim.ui.input({
		prompt = "[packages] package manager not found, bootstrap? [y/N/never] ",
	}, function(r)
		response = r
	end)

	if vim.fn.match(response, "[Nn][Ee][Vv][Ee][Rr]") >= 0 then
		startup_data.bootstrap = false
		write(startup_file, startup_data)
		return false
	end

	if vim.fn.match(response, "^[Yy]\\([Ee][Ss]\\)\\?$") < 0 then
		return false
	end

	print("\n")
	local lock_data = read(package_lock)
	local commit = lock_data["lazy.nvim"] and lock_data["lazy.nvim"].commit
	local url = "https://github.com/folke/lazy.nvim.git"
	vim.notify("[packages] installing lazy.nvim...")
	vim.fn.mkdir(package_path, "p")
	if not execute({ "clone", "--filter=blob:none", url, lazy_path }, vim.log.levels.INFO).success then
		return false
	end

	if commit then
		dir_execute(lazy_path, { "checkout", commit }, vim.log.levels.INFO)
	end
	local lazy_patch_path = vim.fs.joinpath(conf_path, "patches", "lazy.nvim.patch")
	if vim.uv.fs_stat(lazy_patch_path) and vim.uv.fs_stat(lazy_path) then
		dir_execute(lazy_path, { "apply", "--ignore-space-change", lazy_patch_path }, vim.log.levels.WARN)
	end
	vim.notify("[packages] lazy.nvim cloned to " .. lazy_path)
	vim.opt.rtp:prepend(lazy_path)
	return true
end

if not bootstrap() then
	return
end

-- Reverse/Apply local patches on updating/intalling plugins,
-- must be created before setting lazy to apply the patches properly
vim.api.nvim_create_autocmd("User", {
	desc = "Reverse/Apply local patches on updating/intalling plugins.",
	group = vim.api.nvim_create_augroup("LazyPatches", {}),
	pattern = { "LazyInstall*", "LazyUpdate*", "LazySync*", "LazyRestore*" },
	callback = function(info)
		-- In a lazy sync action:
		-- -> LazySyncPre     <- restore packages
		-- -> LazyInstallPre
		-- -> LazyUpdatePre
		-- -> LazyInstall
		-- -> LazyUpdate
		-- -> LazySync        <- apply patches
		vim.g._lz_syncing = vim.g._lz_syncing or info.match == "LazySyncPre"
		if vim.g._lz_syncing and not info.match:find("^LazySync") then
			return
		end
		if info.match == "LazySync" then
			vim.g._lz_syncing = nil
		end

		local patches_path = vim.fs.joinpath(conf_path, "patches")
		for patch in vim.fs.dir(patches_path) do
			local patch_path = vim.fs.joinpath(patches_path, patch)
			local plugin_path = vim.fs.joinpath(package_path, (patch:gsub("%.patch$", "")))
			if vim.uv.fs_stat(plugin_path) then
				dir_execute(plugin_path, { "restore", "." })
				if not info.match:find("Pre$") then
					vim.notify("[packages] applying patch " .. patch)
					dir_execute(plugin_path, { "apply", "--ignore-space-change", patch_path }, vim.log.levels.WARN)
				end
			end
		end
	end,
})

require("lazy").setup(require("core.plugins"), {
	defaults = { lazy = true, version = "*" },
	install = { missing = true, colorscheme = { "tokyonight" } },
	change_detection = { enabled = true, notify = false },
	checker = { enabled = true, notify = false, frequency = (3600 * 24) * 7 },
	ui = {
		border = "single",
		icons = { ft = " ", lazy = "󰂠 ", loaded = " ", not_loaded = " " },
	},
	performance = {
		cache = { enabled = true },
		reset_packpath = true,
		rtp = {
			reset = true,
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
