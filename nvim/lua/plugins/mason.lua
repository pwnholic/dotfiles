--- mason.nvim: install LSP servers (and other tools) from inside Neovim.
---
--- The `<leader>cM` mapping lists the servers that `core.lsp` reports as missing
--- and installs the chosen one with `:MasonInstall`, so the WARN lines of
--- `:checkhealth config` have a one-keystroke fix (the picker is `vim.ui.select`,
--- which fzf-lua provides). `<leader>cm` opens the mason UI.
---
--- Mason installs into `<data>/mason` and puts its `bin` directory in `PATH`
--- (`install_root_dir` + `PATH = "prepend"`); `core.lsp.setup_mason_path()` does
--- the same at startup, so both orders work.
---
--- @class plugins.mason
local M = {}

local SRC = "https://github.com/mason-org/mason.nvim"

--- mason package name for each LSP server declared in `plugins/lsp.lua`.
--- Package naming is mason's domain, so the mapping lives here instead of in the
--- server configuration. Verified against the registry by `tests/t10`.
local SERVER_PACKAGES = {
    lua_ls = "lua-language-server",
    gopls = "gopls",
    basedpyright = "basedpyright",
    ruff = "ruff",
    vtsls = "vtsls",
    clangd = "clangd",
    rust_analyzer = "rust-analyzer",
}

--- @type lib.Lifecycle?
local lc

--- LSP servers that are declared, missing on this machine, and known to mason.
--- @return { server: string, package: string, cmd: string|nil }[]
function M.missing()
    local out = {}
    for _, info in ipairs(require("core.lsp").server_info()) do
        local package = SERVER_PACKAGES[info.name]
        if package and not info.available then
            out[#out + 1] = { server = info.name, package = package, cmd = info.cmd }
        end
    end
    return out
end

--- @return table<string, string>
function M.packages()
    return vim.deepcopy(SERVER_PACKAGES)
end

--- Pick a missing server and hand it to `:MasonInstall`.
function M.install_missing()
    local missing = M.missing()
    if #missing == 0 then
        require("core.notify").info("every declared LSP server is already available")
        return
    end
    vim.ui.select(missing, {
        prompt = "Install LSP server with mason",
        format_item = function(item)
            return ("%s  (%s)"):format(item.package, item.cmd or "dynamic cmd")
        end,
    }, function(choice)
        if not choice then
            return
        end
        vim.cmd(("MasonInstall %s"):format(choice.package))
    end)
end

function M.setup()
    local o = require("core.defaults").get("mason", {})
    if o.enabled == false then
        return
    end

    local ok, err = require("core.pack").register({
        src = SRC,
        name = "mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
        reloadable = true,
        config = M.configure,
    })
    if not ok then
        require("core.notify").error("mason: " .. tostring(err))
    end
end

function M.configure()
    local o = require("core.defaults").get("mason", {})
    require("mason").setup({
        ui = { border = o.border or vim.o.winborder },
    })

    lc = require("lib.lifecycle").new({ name = "plugins.mason" })
    lc:keymap("n", "<leader>cm", "<cmd>Mason<cr>", { desc = "mason: package UI" })
    lc:keymap("n", "<leader>cM", function()
        M.install_missing()
    end, { desc = "mason: install a missing LSP server" })
    lc:activate()
end

function M.teardown()
    if lc then
        lc:teardown()
        lc = nil
    end
end

return M
