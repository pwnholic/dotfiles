--- t10: completion (blink.cmp) + LSP tool installer (mason.nvim).
---
--- The LSP part starts a real client (`lua_ls`) and inspects the capabilities the
--- client was created with: that is the end-to-end proof that completion is wired
--- into the LSP clients, not just that a config table exists.
local T = dofile(vim.fs.joinpath(vim.fn.stdpath("config"), "tests", "helpers.lua"))

local defaults = require("core.defaults")
local fs = require("lib.fs")
local pack = require("core.pack")

-- ---------------------------------------------------------------- blink.cmp --
local spec = pack.get("blink.cmp")
T.check(spec ~= nil, "blink.cmp is declared")
T.equal(spec and spec.reloadable, true, "completion configuration is reloadable")
T.equal(
    tostring(spec and spec.version),
    tostring(vim.version.range("1.*")),
    "pinned to the stable 1.* tags"
)
T.check(
    spec and vim.tbl_contains(vim.tbl_map(tostring, spec.event or {}), "InsertEnter"),
    "lazy triggers declared"
)
T.equal(
    pack.is_loaded("blink.cmp"),
    true,
    "loaded during startup (capabilities before the first client)"
)

-- blink.cmp treats `border = nil` as "use vim.o.winborder" (its own alias
-- documents this for 0.11+), so the configuration must not pin a shape.
local blink_config = require("blink.cmp.config")
T.equal(blink_config.documentation.window.border, nil, "completion docs inherit the global border")
T.equal(blink_config.signature.window.border, nil, "signature help inherits the global border")

local blink = require("blink.cmp")
local caps = blink.get_lsp_capabilities()
T.check(
    caps.textDocument.completion.completionList.itemDefaults ~= nil,
    "blink provides LSP completion capabilities (itemDefaults)"
)
T.equal(defaults.get("blink.load_early_for_lsp"), true, "early load is the configured default")

-- Real client: the capabilities registered through `vim.lsp.config('*')` must
-- reach the client that attaches to a buffer.
if not require("lib.process").have("lua-language-server") then
    T.info("lua-language-server not available: skipping the live LSP capability check")
else
    local dir = T.tmpdir("completion")
    local file = vim.fs.joinpath(dir, "sample.lua")
    T.write(vim.fs.joinpath(dir, ".git", "HEAD"), { "ref: refs/heads/main" })
    T.write(file, { "local function add(a, b)", "  return a + b", "end", "return add" })
    vim.cmd.edit(vim.fn.fnameescape(file))

    local buf = vim.api.nvim_get_current_buf()
    T.check(
        vim.wait(20000, function()
            return #vim.lsp.get_clients({ bufnr = buf }) > 0
        end, 100),
        "lua_ls client attached"
    )
    local client = vim.lsp.get_clients({ bufnr = buf })[1]
    if client then
        local client_caps = client.config.capabilities or {}
        T.check(
            client_caps.textDocument ~= nil
                and client_caps.textDocument.completion ~= nil
                and client_caps.textDocument.completion.completionList ~= nil
                and client_caps.textDocument.completion.completionList.itemDefaults ~= nil,
            "client started with blink's completion capabilities"
        )
        T.check(client:supports_method("textDocument/completion"), "client advertises completion")
        -- Proof that the *native* `lsp/lua_ls.lua` file is used: `LuaJIT` comes
        -- only from that file (`lua/plugins/lsp.lua` no longer registers lua_ls).
        local settings = (client.config.settings or {}).Lua or {}
        T.check(
            settings.runtime ~= nil and settings.runtime.version == "LuaJIT",
            "client started with the native lsp/lua_ls.lua settings: "
                .. vim.inspect(settings.runtime)
        )
        pcall(function()
            client:stop(true) -- `vim.lsp.stop_client()` is deprecated in 0.12
        end)
    else
        T.check(false, "client object available for capability inspection")
    end
end

-- ------------------------------------------------------------------- mason --
local mason_spec = pack.get("mason.nvim")
T.check(mason_spec ~= nil, "mason.nvim is declared")
T.check(
    mason_spec ~= nil
        and vim.tbl_contains(vim.tbl_map(tostring, mason_spec.cmd or {}), "MasonInstall"),
    "command triggers cover the mason commands"
)
T.check(pack.load("mason.nvim"), "mason.nvim loads")
T.check(vim.api.nvim_get_commands({}).Mason ~= nil, ":Mason exists after loading")
T.check(vim.api.nvim_get_commands({}).MasonInstall ~= nil, ":MasonInstall exists after loading")
T.check(vim.fn.maparg("<leader>cm", "n", false, true).desc ~= nil, "mason UI is mapped")
T.check(
    vim.fn.maparg("<leader>cM", "n", false, true).desc ~= nil,
    "install-missing-server is mapped"
)

local mason = require("plugins.mason")
local mapping = mason.packages()
local missing = mason.missing()
T.check(#missing > 0, "missing LSP servers are detected: " .. vim.inspect(vim.tbl_map(function(i)
    return i.server
end, missing)))
for _, item in ipairs(missing) do
    T.equal(
        mapping[item.server],
        item.package,
        ("%s maps to mason package %s"):format(item.server, item.package)
    )
    T.check(
        item.package ~= nil and item.package ~= "",
        ("package name for %s is non-empty"):format(tostring(item.server))
    )
end
-- Available servers must not be reported as missing.
for _, name in ipairs({ "lua_ls" }) do
    local listed = false
    for _, item in ipairs(missing) do
        if item.server == name then
            listed = true
        end
    end
    T.equal(listed, false, ("available server %s is not reported as missing"):format(name))
end

-- Every mapped package name must exist in mason's registry (registry is fetched
-- by the mason UI; when offline the check is skipped instead of failing).
local registry_dir = fs.data_path("mason", "registries")
if fs.is_dir(registry_dir) then
    local ok_reg, registry = pcall(require, "mason-registry")
    if ok_reg then
        for server, package in pairs(mapping) do
            local ok_pkg = pcall(registry.get_package, package)
            T.check(ok_pkg, ("mason registry knows the %s package (%s)"):format(server, package))
        end
    else
        T.info("mason-registry not loadable; skipping registry validation")
    end
else
    T.info("mason registry not fetched yet (:Mason); skipping registry validation")
end

-- `:checkhealth config` reports the mason installation (filesystem based).
T.check(require("core.health") ~= nil, "health module still loadable after mason")
T.check(fs.is_dir(fs.data_path("mason")), "mason data directory exists")

T.finish()
