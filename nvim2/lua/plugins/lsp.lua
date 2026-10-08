--- LSP servers.
---
--- Declarative server configs registered through `core.lsp`:
---
---   * `vim.lsp.config(name, cfg)` (0.11+), `vim.lsp.enable(name)` (0.11+),
---   * servers configured through the native `lsp/<name>.lua` convention
---     (`lsp/lua_ls.lua` is the single source for `lua_ls`; `core.lsp` enables
---     native configs too and reports their source in `:LspInfo`),
---   * servers whose executable is missing are skipped (not failed),
---   * `:checkhealth config` reports which binary is missing and where to look,
---   * `:LspInfo` shows active clients/configs, `:LspExec` runs commands.
---
--- No LSP plugin is required: `vim.lsp` in 0.12 ships the client, default
--- keymaps (`grn`, `gra`, `grr`, `gri`, `gO`, ...) and inline completion API.
---
--- @class plugins.lsp
local M = {}

--- Server configs. `cmd` is a list; a missing executable disables the server.
--- @type table<string, table>
local SERVERS = {
    gopls = {
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_markers = { "go.work", "go.mod", ".git" },
    },
    basedpyright = {
        cmd = { "basedpyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = {
            "pyproject.toml",
            "setup.py",
            "setup.cfg",
            "requirements.txt",
            "pyrightconfig.json",
            ".git",
        },
    },
    ruff = {
        cmd = { "ruff", "server" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
    },
    vtsls = {
        cmd = { "vtsls", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
    },
    clangd = {
        cmd = { "clangd", "--background-index", "--clang-tidy" },
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
        root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd", ".git" },
    },
    rust_analyzer = {
        cmd = { "rust-analyzer" },
        filetypes = { "rust" },
        root_markers = { "Cargo.toml", "rust-project.json", ".git" },
    },
}

--- `command_hints`: metadata for `:LspExec`.
---
--- LSP exposes only command *names* (`executeCommandProvider.commands`); the
--- protocol has no parameter metadata, so hints are opt-in data taken from each
--- server's documentation. Shape:
---
---   [server] = {                      -- or "*" as a global fallback
---     [command] = {
---       description = "...",          -- shown in the picker
---       params = { { name = "...", type = "...", required = true, description = "..." } },
---       example = '["..."]',          -- default text of the JSON prompt
---       docs = "https://...",         -- where the information comes from
---     },
---   }
---
--- `params`/`required` turn a hint into a guard: `:LspExec` refuses to run a
--- command whose required arguments are missing (clear error, no execution).
---
--- The entries below are limited to commands whose arguments are verifiably
--- "none" (they act on editor state); add more from a server's docs with
--- `require('core.lsp').register_command_hints(server, { ... })`.
local HINTS = {
    rust_analyzer = {
        ["rust-analyzer/analyzerStatus"] = {
            description = "Show rust-analyzer internal status",
            params = {},
            example = "[]",
            docs = "https://rust-analyzer.github.io/manual.html",
        },
        ["rust-analyzer/rebuildProcMacros"] = {
            description = "Rebuild all procedural macros",
            params = {},
            example = "[]",
            docs = "https://rust-analyzer.github.io/manual.html",
        },
    },
    lua_ls = {
        ["lua.removeSpace"] = {
            description = "Remove spaces around the cursor",
            params = {},
            example = "[]",
            docs = "https://luals.github.io/wiki/",
        },
    },
}

function M.setup()
    local lsp = require("core.lsp")
    local notify = require("core.notify")

    -- Servers declared in configuration (`defaults.lsp.servers`) extend/override
    -- the built-in list, so users add servers without editing this file.
    local declared = require("core.defaults").get("lsp.servers", {})
    local merged = vim.tbl_deep_extend("force", vim.deepcopy(SERVERS), declared)

    for name, config in pairs(merged) do
        local ok, err = lsp.register_server(name, config)
        if not ok then
            notify.error(("plugins.lsp: %s"):format(tostring(err)))
        end
    end

    for server, hints in pairs(HINTS) do
        local ok, err = lsp.register_command_hints(server, hints)
        if not ok then
            notify.error(("plugins.lsp: hints for %s: %s"):format(server, tostring(err)))
        end
    end

    -- Completion capabilities must exist before the first client starts: clients
    -- attach while file arguments are opened, i.e. before `User VeryLazy`. The
    -- completion spec is therefore loaded here when configured to do so; a
    -- failure (e.g. a headless session without the plugin installed) is not fatal.
    local blink = require("core.defaults").get("blink", {})
    if blink.enabled ~= false and blink.load_early_for_lsp ~= false then
        local packed = require("core.pack")
        if packed.is_declared("blink.cmp") then
            local loaded, load_err = packed.load("blink.cmp")
            if not loaded then
                require("core.notify").debug(
                    ("blink.cmp not loaded early: %s"):format(tostring(load_err))
                )
            end
        end
    end

    -- Start servers on matching filetypes when their command is available.
    local enabled, skipped = lsp.enable_servers()
    if #enabled > 0 then
        notify.debug(("LSP servers enabled: %s"):format(table.concat(enabled, ", ")))
    end
    for name, reason in pairs(skipped) do
        notify.debug(("LSP server %s skipped: %s"):format(name, reason))
    end
end

function M.teardown()
    -- Nothing to tear down: `vim.lsp.enable()`/configs are idempotent and clients
    -- are owned by Neovim.
end

--- @return table<string, table>
function M.servers()
    return vim.deepcopy(SERVERS)
end

return M
