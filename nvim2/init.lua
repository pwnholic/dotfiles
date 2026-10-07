-- Neovim 0.12+ configuration entry point.
--
-- Keep this file declarative: it computes overrides and hands them to
-- `core.setup()`. `:ConfigReload` re-sources this file (that is what makes
-- changes to it take effect without a full restart), so it must stay
-- idempotent and free of one-off side effects.
--
-- User overrides live in `lua/core/user.lua` (optional, user-owned). See
-- `lua/core/defaults.lua` for the full list of options and the documented
-- precedence: core defaults -> lua/core/user.lua -> this call -> plugin
-- registries -> runtime state.

-- Native module loader: caches compiled Lua and invalidates on file change
-- (mtime+size), which keeps `:ConfigReload` fast and correct.
vim.loader.enable(true)

local overrides = {}

local user_config = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "core", "user.lua")
if vim.fn.filereadable(user_config) == 1 then
    local ok, user = pcall(require, "core.user")
    if ok and type(user) == "table" then
        overrides = user
    else
        vim.notify(
            ("lua/core/user.lua could not be loaded: %s"):format(tostring(user)),
            vim.log.levels.ERROR
        )
    end
end

require("core").setup(overrides)
