--- conform.nvim: the formatting provider behind `core.format`.
---
--- `core.format` owns the policy (global/buffer gates, format-on-save). Conform
--- owns the formatting. The bridge is `core.format.set_provider()`.
---
--- Loaded on `BufWritePre` (format-on-save) and on `:ConformInfo`, so nothing
--- is loaded until formatting is actually about to happen.
---
--- @class plugins.conform
local M = {}

local SRC = "https://github.com/stevearc/conform.nvim"

--- Single source of truth for formatter metadata (health checks, `:FormatInfo`)
--- and filetype mapping (also handed to Conform).

function M.setup()
    require("core.pack").register({
        src = SRC,
        name = "conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        reloadable = true,
        config = M.configure,
    })
end

function M.configure()
    local format = require("core.format")
    local notify = require("core.notify")
    local format_data = require("core.defaults").get("format", {})

    -- Formatter metadata and the filetype mapping are core data
    -- (`defaults.format`), registered by `core.format.setup()`; this plugin only
    -- supplies the runner, so there is exactly one source of truth.

    local ok, conform = pcall(require, "conform")
    if not ok then
        notify.error("conform.nvim could not be loaded: " .. tostring(conform))
        return
    end

    conform.setup({
        formatters_by_ft = format_data.filetypes or {},
        -- `core.format` owns format-on-save; enabling Conform's own hook would
        -- bypass the global/buffer gates.
        format_on_save = false,
        default_format_opts = { lsp_format = "fallback" },
        notify_on_error = true,
    })

    local provider_ok, provider_err = format.set_provider({
        name = "conform.nvim",
        --- @param bufnr integer
        --- @param o { timeout_ms?: integer, range?: table }
        --- @return boolean attempted
        format = function(bufnr, o)
            local opts = {
                bufnr = bufnr,
                async = false,
                timeout_ms = o.timeout_ms or 1500,
                lsp_format = "fallback",
            }
            if o.range then
                opts.range = o.range
            end
            return conform.format(opts) == true
        end,
        --- @param bufnr integer
        --- @return table[]|nil
        formatters = function(bufnr)
            local list = conform.list_formatters_to_run(bufnr)
            return vim.iter(list or {})
                :map(function(info)
                    return { name = info.name, available = info.available ~= false }
                end)
                :totable()
        end,
    })
    if not provider_ok then
        notify.error("conform.lua: cannot register provider: " .. tostring(provider_err))
    end
end

function M.teardown()
    require("core.format").teardown()
end

return M
