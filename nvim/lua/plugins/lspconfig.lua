-- Advanced diagnostic display override (via nvim-lspconfig).
--
-- Why here and not in `lua/config/options.lua`:
-- `LazyVim/lua/lazyvim/plugins/lsp/init.lua` calls
-- `vim.diagnostic.config(vim.deepcopy(opts.diagnostics))` during LSP setup,
-- so a bare `vim.diagnostic.config()` in `options.lua` would be overwritten.
-- Filling `opts.diagnostics` on the `neovim/nvim-lspconfig` spec is LazyVim's
-- official path (see `opts = function() ... diagnostics = {...}` there); the
-- table is deep-merged with the LazyVim defaults, so only overrides go here.
--
-- Why `opts` is a function: plugin spec files are sourced while lazy.nvim
-- collects specs, before `_G.LazyVim` exists. Reading
-- `LazyVim.config.icons.diagnostics` at the top level would index a nil
-- global at startup. Deferring the read into `opts = function(_, opts)`
-- (which lazy.nvim runs after LazyVim is set up, like LazyVim's own LSP
-- spec does) makes the icon lookup safe.
--
-- Display model (WARN and above inline, HINT/INFO stay in the sign column):
--   * other lines  : compact virtual_text (WARN+), hidden on the active line
--   * active line  : expanded virtual_lines (WARN+), virtual_text suppressed
--     there via `virtual_text.current_line = false` so they never double up
--   * sign column + line-number highlight: always on, every severity
--   * underline: WARN and above only (HINT/INFO never underlined)
--   * float: `single` border (matches `opts.winborder`), non-focusable,
--     cursor-scoped on jump (`]d` / `[d` / `]e` / `[e`)
--
-- Responsive behavior (adapts to the actual split width, not just the screen):
-- `virtual_text`, `virtual_lines`, and `float` are functions of
-- `(namespace, bufnr)`, so each render measures the window showing the buffer
-- and then adjusts itself: tighter spacing, shorter messages, and (below 80
-- columns) ERROR-only inline text to keep narrow splits readable. Wide splits
-- keep the full detail. Floats are capped at 80% of the screen width so they
-- stay pretty on both small and ultrawide displays.

local SEVERITY_HL = {
    [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
    [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
    [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
    [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
}

-- Width of the window currently showing {bufnr}, falling back to the full
-- editor width when the buffer is hidden (e.g. during headless evaluation).
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

-- Collapse a diagnostic message to one tidy line and clamp its display width.
-- Uses `strchars`/`strcharpart` so multibyte text is never cut mid-character.
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

-- Suffix holding the LSP code (e.g. `unused-import`), or "" when absent.
---@param diagnostic vim.Diagnostic
---@return string
local function code_suffix(diagnostic)
    local code = diagnostic.code
    if code == nil or code == "" then
        return ""
    end
    return " [" .. tostring(code) .. "]"
end

-- Inline-text budget derived from the split width: roomy on wide splits,
-- tight on narrow ones, never below 30 cells.
---@param bufnr integer?
---@return integer
local function inline_budget(bufnr)
    return math.max(30, math.min(100, buf_width(bufnr) - 40))
end

-- Expanded-line budget for virtual_lines/floats: more generous than inline,
-- still capped so long messages never stretch edge to edge.
---@param bufnr integer?
---@return integer
local function expanded_budget(bufnr)
    return math.max(40, math.min(160, buf_width(bufnr) - 20))
end

-- Inline spacing that breathes on wide splits and stays out of the way on
-- narrow ones.
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
        -- Function form (not a plain table) so `LazyVim.config.icons` is read
        -- after LazyVim is set up. Mutates the merged `opts` in place.
        ---@param _ table
        ---@param opts table
        opts = function(_, opts)
            -- Severity icons follow the active LazyVim icon set, so switching
            -- colorscheme/icon overrides updates diagnostics automatically.
            local SEVERITY_ICON = {
                [vim.diagnostic.severity.ERROR] = LazyVim.config.icons.diagnostics.Error,
                [vim.diagnostic.severity.WARN] = LazyVim.config.icons.diagnostics.Warn,
                [vim.diagnostic.severity.HINT] = LazyVim.config.icons.diagnostics.Hint,
                [vim.diagnostic.severity.INFO] = LazyVim.config.icons.diagnostics.Info,
            }

            ---@type vim.diagnostic.Opts
            opts.diagnostics = {
                underline = {
                    -- Signs and text still cover HINT/INFO; only the underline is gated.
                    severity = { min = vim.diagnostic.severity.WARN },
                },
                signs = {
                    -- Cheap and always visible, even in narrow splits.
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
                -- Function form: re-evaluated per render so spacing, length, and
                -- severity adapt to the current split width.
                ---@param _ integer
                ---@param bufnr integer
                virtual_text = function(_, bufnr)
                    local compact = buf_width(bufnr) < 80
                    return {
                        spacing = inline_spacing(bufnr),
                        source = "if_many",
                        -- Hidden on the cursor line; virtual_lines owns that line.
                        current_line = false,
                        hl_mode = "combine",
                        -- Below 80 columns only ERROR stays inline; the rest
                        -- remain one keypress away via float/jump.
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
                -- Expanded detail for the cursor line only; multiple
                -- diagnostics on the line each get their own row.
                ---@param _ integer
                ---@param bufnr integer
                virtual_lines = function(_, bufnr)
                    local width = buf_width(bufnr)
                    return {
                        current_line = true,
                        severity = { min = vim.diagnostic.severity.WARN },
                        format = function(diagnostic)
                            local icon = SEVERITY_ICON[diagnostic.severity] or "●"
                            -- Source tag only where there is room for it.
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
                -- Function form so the float never overflows a narrow screen.
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
                    -- Peek at the target without stealing focus.
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
                    -- `vim.iter` keeps the fixed severity order (ERROR, WARN,
                    -- INFO, HINT) while dropping zero-count severities: `map`
                    -- returning nil filters the item, and `join` renders the
                    -- survivors in one pass with no intermediate table.
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
                -- Highest severity wins when several diagnostics share a line.
                severity_sort = true,
                -- Refresh on InsertLeave: no flicker while typing.
                update_in_insert = false,
            }
        end,
    },
}
