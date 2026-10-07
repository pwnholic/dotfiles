--- blink.pairs (saghen): intelligent auto-pairs with rainbow highlighting.
---
--- Requirements taken from the official README/source: Neovim 0.12+, the
--- `saghen/blink.lib` dependency (v0.6+; `lua/blink/pairs/init.lua` errors without
--- it) and a native matcher that is downloaded from the GitHub release at install
--- time (`require('blink.pairs').download()`), so the first start has no wait.
---
--- Switching is owned by the plugin: `vim.b.pairs = false` (buffer) or
--- `vim.g.pairs = false` (global), also `blink_pairs`. `cmdline` highlights need
--- `vim._core.ui2`, which is not enabled here, so they stay off.

local defaults = require("core.defaults")
local notify = require("core.notify")
local pack = require("core.pack")

local M = {}

function M.setup()
    if defaults.get("blink_pairs.enabled", true) == false then
        return
    end
    local ok, err = pack.register_all({
        {
            src = "https://github.com/Saghen/blink.lib",
            name = "blink.lib",
            --- Provides the native-library loader for blink.pairs.
            lazy = false,
        },
        {
            src = "https://github.com/Saghen/blink.pairs",
            name = "blink.pairs",
            --- `main`: the prebuilt release asset is only available for tagged
            --- checkouts, so the native matcher is built from source instead
            --- (see `M.configure`).
            lazy = false,
            deps = { "blink.lib" },
            reloadable = true,
            config = M.configure,
        },
    })
    if not ok then
        notify.warn("plugins.blink_pairs: " .. tostring(err))
    end
end

function M.configure()
    local o = defaults.get("blink_pairs", {})
    local loaded, blink = pcall(require, "blink.pairs")
    if not loaded then
        notify.error("blink.pairs is not installed (run :PackInstall)")
        return
    end

    -- vim.pack has no build hook: the plugin's instruction is to fetch the native
    -- matcher *before* setup(). It is cached per commit, so this only does work
    -- when it is actually missing.
    local root = vim.fn.stdpath("data") .. "/site/pack/core/opt/blink.pairs"
    local commit = vim.trim(vim.fn.system({ "git", "-C", root, "rev-parse", "HEAD" }))
    local native_path
    local ok_native, native = pcall(require, "blink.lib.native")
    if ok_native and type(native.library_path) == "function" then
        native_path = native.library_path(root, "blink_pairs", commit)
    end
    -- `library_path()` reports the *expected* file, while a source build installs
    -- `lib/libblink_pairs.so.<commit>`; both are checked, otherwise every start would
    -- try (and fail) to fetch a release asset for a `main` checkout.
    local present = #vim.fn.glob(root .. "/lib/libblink_pairs*", false, true) > 0
        or (native_path ~= nil and vim.uv.fs_stat(native_path) ~= nil)
    if not present then
        notify.info("blink.pairs: fetching the native matcher (once per commit)")
        pcall(function()
            blink.download():pwait(60000)
        end)
    end

    local ok, err = pcall(blink.setup, {
        mappings = {
            enabled = o.mappings ~= false,
            cmdline = o.mappings ~= false,
        },
        highlights = {
            enabled = o.highlights ~= false,
            --- Requires `vim._core.ui2`, which this configuration does not enable.
            cmdline = false,
            --- Pairs whose nesting is counted separately from the rest.
            separate = { "<" },
            matchparen = { enabled = o.matchparen ~= false },
        },
    })
    if not ok then
        -- One short line: the plugin's own message is multi-line and would trigger
        -- the hit-enter prompt at startup.
        local first = vim.split(tostring(err), "\n")[1] or "setup failed"
        notify.error(("blink.pairs: %s"):format(first))
    end
end

return M
