-- Diagnostic display via lspconfig `opts.diagnostics` (NOT bare
-- `vim.diagnostic.config` in options.lua: LazyVim's LSP setup overwrites
-- that). WARN+ inline, HINT/INFO signs only, responsive to split width.

local SEVERITY_HL = {
    [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
    [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
    [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
    [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
}

---@param bufnr integer?
---@return integer
local function buf_width(bufnr)
    if bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr) then
        local winid = vim.fn.bufwinid(bufnr)
        if winid ~= -1 and vim.api.nvim_win_is_valid(winid) then
            return vim.api.nvim_win_get_width(winid)
        end
    end
    return vim.o.columns
end

-- One tidy line, multibyte-safe clamp.
---@param message string
---@param max_len integer?
---@return string
local function clean_message(message, max_len)
    local msg = message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    max_len = max_len or 120
    if vim.fn.strchars(msg) > max_len then
        msg = vim.fn.strcharpart(msg, 0, max_len - 1) .. "…"
    end
    return msg
end

---@param diagnostic vim.Diagnostic
---@return string
local function code_suffix(diagnostic)
    local code = diagnostic.code
    if code == nil or code == "" then
        return ""
    end
    return " [" .. tostring(code) .. "]"
end

---@param bufnr integer?
---@return integer
local function inline_budget(bufnr)
    return math.max(30, math.min(100, buf_width(bufnr) - 40))
end

---@param bufnr integer?
---@return integer
local function expanded_budget(bufnr)
    return math.max(40, math.min(160, buf_width(bufnr) - 20))
end

---@param bufnr integer?
---@return integer
local function inline_spacing(bufnr)
    local width = buf_width(bufnr)
    if width < 80 then
        return 1
    end
    if width < 120 then
        return 2
    end
    return 4
end

return {
    {
        "neovim/nvim-lspconfig",
        -- Function form: `LazyVim.config.icons` only exists post-setup.
        ---@param _ table
        ---@param opts table
        opts = function(_, opts)
            -- Icons follow the active set, so theme switches propagate.
            local SEVERITY_ICON = {
                [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
                [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
                [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
                [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
            }

            ---@type vim.diagnostic.Opts
            opts.diagnostics = {
                underline = {
                    severity = { min = vim.diagnostic.severity.WARN },
                },
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = SEVERITY_ICON[vim.diagnostic.severity.ERROR],
                        [vim.diagnostic.severity.WARN] = SEVERITY_ICON[vim.diagnostic.severity.WARN],
                        [vim.diagnostic.severity.INFO] = SEVERITY_ICON[vim.diagnostic.severity.INFO],
                        [vim.diagnostic.severity.HINT] = SEVERITY_ICON[vim.diagnostic.severity.HINT],
                    },
                    numhl = {
                        [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
                        [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
                        [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
                        [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
                    },
                    priority = 10,
                },
                -- Rendered per buffer; adapts to split width.
                ---@param _ integer
                ---@param bufnr integer
                virtual_text = function(_, bufnr)
                    local compact = buf_width(bufnr) < 80
                    return {
                        spacing = inline_spacing(bufnr),
                        source = "if_many",
                        -- Hidden on cursor line (virtual_lines owns it).
                        current_line = false,
                        hl_mode = "combine",
                        -- ERROR-only below 80 cols.
                        severity = { min = compact and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN },
                        prefix = function(diagnostic)
                            return SEVERITY_ICON[diagnostic.severity] or "●"
                        end,
                        suffix = function(diagnostic)
                            return code_suffix(diagnostic)
                        end,
                        format = function(diagnostic)
                            return clean_message(diagnostic.message, inline_budget(bufnr))
                        end,
                    }
                end,
                -- Cursor line only; one row per diagnostic.
                ---@param _ integer
                ---@param bufnr integer
                virtual_lines = function(_, bufnr)
                    local width = buf_width(bufnr)
                    return {
                        current_line = true,
                        severity = { min = vim.diagnostic.severity.WARN },
                        format = function(diagnostic)
                            local icon = SEVERITY_ICON[diagnostic.severity] or "●"
                            local src = (width >= 100 and diagnostic.source) and (" (" .. diagnostic.source .. ")")
                                or ""
                            return icon
                                .. " "
                                .. clean_message(diagnostic.message, expanded_budget(bufnr))
                                .. src
                                .. code_suffix(diagnostic)
                        end,
                    }
                end,
                -- Capped at 80% screen width.
                ---@param _ integer?
                ---@param bufnr integer?
                float = function(_, bufnr)
                    return {
                        border = vim.o.winborder,
                        source = "if_many",
                        header = "",
                        focusable = false,
                        severity_sort = true,
                        max_width = math.min(80, math.floor(vim.o.columns * 0.8)),
                        max_height = math.min(20, math.max(10, math.floor(vim.o.lines * 0.4))),
                        prefix = function(diagnostic, _, _)
                            return SEVERITY_ICON[diagnostic.severity] or "●",
                                SEVERITY_HL[diagnostic.severity] or "Normal"
                        end,
                        suffix = function(diagnostic, _, _)
                            local code = code_suffix(diagnostic)
                            if code == "" then
                                return "", "Normal"
                            end
                            return code, SEVERITY_HL[diagnostic.severity] or "Normal"
                        end,
                        format = function(diagnostic)
                            return clean_message(diagnostic.message, expanded_budget(bufnr))
                        end,
                    }
                end,
                jump = {
                    wrap = true,
                    on_jump = function(diagnostic, bufnr)
                        if diagnostic == nil then
                            return
                        end
                        vim.diagnostic.open_float({
                            bufnr = bufnr,
                            scope = "cursor",
                            focus = false,
                            border = vim.o.winborder,
                        })
                    end,
                },
                status = {
                    -- `map` nil drops zero-counts; fixed ERROR..HINT order.
                    format = function(counts)
                        local order = {
                            vim.diagnostic.severity.ERROR,
                            vim.diagnostic.severity.WARN,
                            vim.diagnostic.severity.INFO,
                            vim.diagnostic.severity.HINT,
                        }
                        return vim.iter(order)
                            :map(function(sev)
                                local n = counts[sev]
                                if n ~= nil then
                                    return (SEVERITY_ICON[sev] or "●") .. " " .. n
                                end
                            end)
                            :join("  ")
                    end,
                },
                severity_sort = true,
                update_in_insert = false,
            }
        end,
    },
}
