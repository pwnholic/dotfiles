--- External tool registry.
---
--- One declarative place describing every external executable the
--- configuration knows about: what it is for, whether it is required, and how
--- to read its version. `core.health` reports on this registry, and optional
--- integrations can query it before trying to run something.
---
--- Extension point: `require('core.tools').register{ id = ..., cmd = ... }`
--- (user configuration and plugins both use it).
---
--- @class core.tools
local M = {}

local Registry = require("lib.registry")
local process = require("lib.process")

--- @type lib.Registry
local registry = Registry.new({ name = "tools" })

--- Register a tool.
--- @param spec { id: string, cmd: string, required?: boolean, purpose?: string, version_args?: string[], notes?: string }
--- @return boolean ok
--- @return string? err
function M.register(spec, opts)
    if type(spec) ~= "table" then
        return false, "tool spec must be a table"
    end
    if type(spec.cmd) ~= "string" or spec.cmd == "" then
        return false, ("tool %q needs a cmd"):format(tostring(spec.id))
    end
    local entry =
        vim.tbl_extend("force", { required = false, version_args = { "--version" } }, spec)
    -- Core-owned tools are re-registerable so a repeated `setup()` cannot fail
    -- with duplicate-id errors (extension points keep the strict default).
    return registry:register(entry, { replace = (opts or {}).replace == true })
end

--- All registered tools in priority order.
--- @return table[]
function M.list()
    return registry:list()
end

--- Resolve availability + version for a tool spec.
--- @param spec table
--- @return { id: string, cmd: string, required: boolean, purpose: string, path: string|nil, version: string|nil, available: boolean }
function M.check(spec)
    local path = process.executable(spec.cmd)
    return {
        id = spec.id,
        cmd = spec.cmd,
        required = spec.required == true,
        purpose = spec.purpose or "",
        path = path,
        version = path and process.version(spec.cmd, spec.version_args) or nil,
        available = path ~= nil,
    }
end

--- Check every registered tool (used by `:checkhealth config`).
--- @return table[] results
function M.check_all()
    return vim.iter(registry:list()):map(M.check):totable()
end

--- Register the tools the core itself depends on.
function M.setup()
    local core_tools = {
        {
            id = "git",
            cmd = "git",
            required = true,
            purpose = "vim.pack plugin install/update, update checks",
            version_args = { "--version" },
        },
        {
            id = "sh",
            cmd = "sh",
            required = true,
            purpose = "fallback shell for the terminal subsystem",
        },
        {
            id = "rg",
            cmd = "rg",
            required = false,
            purpose = "grep program used by :grep / pickers",
            version_args = { "--version" },
        },
        {
            id = "lazygit",
            cmd = "lazygit",
            required = false,
            purpose = "<leader>gg / <leader>gG floating lazygit",
            version_args = { "--version" },
        },
        {
            id = "fzf",
            cmd = "fzf",
            required = false,
            purpose = "fzf-lua picker backend",
            version_args = { "--version" },
        },
        {
            id = "fd",
            cmd = "fd",
            required = false,
            purpose = "file listing for the picker",
            version_args = { "--version" },
        },
        {
            id = "bat",
            cmd = "bat",
            required = false,
            purpose = "file previews in the picker",
            version_args = { "--version" },
        },
        {
            id = "cc",
            cmd = "cc",
            required = false,
            purpose = "compiling Treesitter parsers",
            version_args = { "--version" },
        },
        {
            id = "tree-sitter",
            cmd = "tree-sitter",
            required = false,
            purpose = "Treesitter parser/query tooling",
            version_args = { "--version" },
        },
    }
    for _, spec in ipairs(core_tools) do
        local ok, err = M.register(spec, { replace = true })
        if not ok then
            require("core.notify").error("core.tools: " .. tostring(err))
        end
    end
end

return M
