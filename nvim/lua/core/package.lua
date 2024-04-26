local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	root = vim.fn.stdpath("data") .. "/lazy",
	defaults = { lazy = true, version = "*" },
	spec = require("core.plugins"), ---@type LazySpec
	lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- lockfile generated after running update.
	concurrency = jit.os:find("Windows") and (vim.uv.available_parallelism() * 2) or nil,
	git = {
		log = { "-8" }, -- show the last 8 commits
		timeout = 120, -- kill processes that take more than 2 minutes
		url_format = "https://github.com/%s.git",
		filter = true,
	},
	install = { missing = true, colorscheme = { "tokyonight" } },
	ui = {
		size = { width = 0.8, height = 0.8 },
		wrap = true, -- wrap the lines in the ui
		border = "rounded",
		backdrop = 60,
		pills = true, ---@type boolean
		icons = {
			cmd = " ",
			config = "",
			event = " ",
			ft = " ",
			init = " ",
			import = " ",
			keys = " ",
			lazy = "󰒲 ",
			loaded = "●",
			not_loaded = "○",
			plugin = " ",
			runtime = " ",
			require = "󰢱 ",
			source = " ",
			start = " ",
			task = "✔ ",
			list = {
				"●",
				"➜",
				"★",
				"‒",
			},
		},
		throttle = 20, -- how frequently should the ui process render events
		custom_keys = {
			["<localleader>l"] = {
				function(plugin)
					require("lazy.util").float_term({ "lazygit", "log" }, {
						cwd = plugin.dir,
					})
				end,
				desc = "Open lazygit log",
			},

			["<localleader>t"] = {
				function(plugin)
					require("lazy.util").float_term(nil, {
						cwd = plugin.dir,
					})
				end,
				desc = "Open terminal in plugin dir",
			},
		},
	},
	diff = { cmd = "git" },
	checker = {
		enabled = true,
		concurrency = 10, ---@type number? set to 1 to check for updates very slowly
		notify = false, -- get a notification when new updates are found
		frequency = 3600 * 24 * 7, -- check for updates every hour
	},
	change_detection = {
		enabled = true,
		notify = false,
	},
	performance = {
		cache = { enabled = true },
		reset_packpath = true, -- reset the package path to improve startup time
		rtp = {
			reset = true, -- reset the runtime path to $VIMRUNTIME and your config directory
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
	-- lazy can generate helptags from the headings in markdown readme files,
	-- so :help works even for plugins that don't have vim docs.
	-- when the readme opens with :help it will be correctly displayed as markdown
	readme = {
		enabled = true,
		root = vim.fn.stdpath("state") .. "/lazy/readme",
		files = { "README.md", "lua/**/README.md" },
		skip_if_doc_exists = true,
	},
	state = vim.fn.stdpath("state") .. "/lazy/state.json", -- state info for checker and other things
})
