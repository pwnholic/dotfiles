--- mini.statusline: the one-line UI (mode, git, diff, diagnostics, LSP, file).
---
--- Configured together with `mini.nvim` (one repository = one pack spec):
--- `lua/plugins/mini.lua` calls `M.setup()` from its config hook, after the
--- module is on 'runtimepath'. The section list is data-driven through
--- `defaults.ui.statusline`; `mini.statusline` itself sets `'statusline'` to an
--- expression that dispatches to `active()`/`inactive()`.
---
--- `mini.git` supplies the branch (`vim.b.minigit_summary_string`) and
--- `mini.diff` the hunk summary (`vim.b.minidiff_summary_string`); both are set
--- up in `lua/plugins/mini.lua`.
---
--- @class plugins.mini_statusline
local M = {}

--- `%<` marks where narrowing windows truncate the left side, `%=` right-aligns.
--- @param o table `defaults.ui.statusline`
--- @return fun(): string
local function build_active(o)
    return function()
        local Mini = require("mini.statusline")
        local mode, mode_hl = Mini.section_mode({ trunc_width = 120 })
        local spell = vim.wo.spell and (Mini.is_truncated(120) and "S" or "SPELL") or ""

        local function section(enabled, fn, trunc_width, extra)
            if enabled == false then
                return ""
            end
            return fn(vim.tbl_extend("force", { trunc_width = trunc_width }, extra or {}))
        end

        -- mini.statusline renders each severity with `args.signs[level]` or its own
        -- `E`/`W`/`I`/`H` default: hand it icons instead (documented `args.signs`).
        local _, diag_signs = require("core.lsp").diagnostic_icons()

        return Mini.combine_groups({
            { hl = mode_hl, strings = { mode, spell } },
            {
                hl = "MiniStatuslineDevinfo",
                strings = {
                    section(o.git, Mini.section_git, 40),
                    section(o.diff, Mini.section_diff, 75),
                    section(o.diagnostics, Mini.section_diagnostics, 75, {
                        signs = require("core.defaults").get("diagnostics.icons", true)
                                and diag_signs
                            or {},
                    }),
                },
            },
            "%<",
            {
                hl = "MiniStatuslineFilename",
                strings = { section(o.filename, Mini.section_filename, 140) },
            },
            "%=",
            {
                hl = "MiniStatuslineFileinfo",
                strings = {
                    section(o.lsp, Mini.section_lsp, 75),
                    section(o.fileinfo, Mini.section_fileinfo, 120),
                },
            },
            {
                hl = mode_hl,
                strings = {
                    section(o.location, Mini.section_location, 75),
                    section(o.searchcount, Mini.section_searchcount, 75),
                },
            },
        })
    end
end

--- Inactive windows show the file and the position only.
--- @param o table `defaults.ui.statusline`
--- @return fun(): string
local function build_inactive(o)
    return function()
        local Mini = require("mini.statusline")
        local filename = o.filename == false and "" or Mini.section_filename({ trunc_width = 140 })
        local location = o.location == false and "" or Mini.section_location({ trunc_width = 75 })
        return Mini.combine_groups({
            { hl = "MiniStatuslineFilename", strings = { filename } },
            "%=",
            { hl = "MiniStatuslineFileinfo", strings = { location } },
        })
    end
end

--- @param o? table `defaults.ui.statusline`
function M.setup(o)
    o = o or require("core.defaults").get("ui.statusline", {})
    if o.enabled == false then
        return
    end

    local Mini = require("mini.statusline")
    Mini.setup({
        use_icons = o.icons ~= false,
        content = {
            active = build_active(o),
            inactive = build_inactive(o),
        },
    })
end

return M
