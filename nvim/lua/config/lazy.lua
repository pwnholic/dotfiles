---@diagnostic disable: undefined-field
local lazypath = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "lazy.nvim")

if not vim.uv.fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    root = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy"),
    spec = {
        { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        { import = "plugins" },
        { "mason-org/mason.nvim", version = "^1.0.0" },
        {
            "neovim/nvim-lspconfig",
            dependencies = {
                { "mason-org/mason-lspconfig.nvim", version = "^1.0.0" },
            },
        },
    },
    defaults = { lazy = false, version = false },
    install = { colorscheme = { "tokyonight", "habamax" } },
    checker = { enabled = false, notify = false },
    lockfile = vim.fs.joinpath(vim.fn.stdpath("config"), "lazy-lock.json"),
    concurrency = nil,
    pkg = {
        enabled = true,
        cache = vim.fs.joinpath(vim.fn.stdpath("state"), "lazy", "pkg-cache.lua"),
        sources = {
            "lazy",
            "rockspec", -- will only be used when rocks.enabled is true
            "packspec",
        },
    },
    rocks = {
        enabled = true,
        root = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy-rocks"),
        server = "https://nvim-neorocks.github.io/rocks-binaries/",
        hererocks = nil,
    },
    performance = {
        rtp = {
            disabled_plugins = {
                "2html_plugin",
                "compiler",
                "ftplugin",
                "gzip",
                "matchit",
                "matchparen",
                "netrwPlugin",
                "rplugin",
                "spellfile_plugin",
                "synmenu",
                "syntax",
                "tar",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zip",
                "zipPlugin",
            },
        },
    },
})
