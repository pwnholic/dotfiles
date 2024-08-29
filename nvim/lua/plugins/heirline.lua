return {
    "rebelot/heirline.nvim",
    event = "UIEnter",
    opts = function(_, opts)
        local conditions = require("heirline.conditions")
        local hutils = require("heirline.utils")
        local c = require("tokyonight.colors").setup()
        local cutil = require("tokyonight.util")
        local utils = require("utils")
        local set_hl = vim.api.nvim_set_hl
        local align, space = { provider = "%=" }, { provider = " " }

        local mode_colors = {
            n = c.blue1,
            i = c.green,
            v = c.yellow,
            V = c.magenta2,
            ["\22"] = c.teal,
            c = c.orange,
            s = c.purple,
            S = c.purple,
            ["\19"] = c.purple,
            R = c.red,
            r = c.red,
            ["!"] = c.red,
            t = c.red,
        }

        vim.api.nvim_create_autocmd("ModeChanged", {
            pattern = "*:*",
            callback = function()
                local color = mode_colors[vim.fn.mode():sub(1, 1)]
                set_hl(0, "TermCursor", { bg = color })
                set_hl(0, "lCursor", { bg = color })
                set_hl(0, "WinBarNC", { sp = color, underline = true })
                set_hl(0, "WinBar", { sp = color, underline = true, bg = c.bg_statusline })
                set_hl(0, "Visual", { bg = cutil.darken(color, 0.35), bold = true, italic = true })
                set_hl(0, "VisualNOS", { bg = cutil.darken(color, 0.35), bold = true, italic = true })
                set_hl(0, "TreesitterContext", { bg = cutil.darken(color, 0.2), bold = true })
            end,
        })

        opts.statusline = {
            condition = function()
                return not conditions.buffer_matches({
                    buftype = { "nofile", "prompt", "help", "quickfix", "terminal" },
                    filetype = { "dashboard", "lspinfo", "toggleterm", "lazy", "lazyterm", "netrw" },
                })
            end,
            {
                static = {
                    mode_names = {
                        n = "NORMAL",
                        no = "NORMAL",
                        nov = "NORMAL",
                        noV = "NORMAL",
                        ["no\22"] = "NORMAL",
                        niI = "NORMAL",
                        niR = "NORMAL",
                        niV = "NORMAL",
                        nt = "NORMAL",
                        v = "VISUAL",
                        vs = "VISUAL",
                        V = "VISUAL",
                        Vs = "VISUAL",
                        ["\22"] = "VISUAL",
                        ["\22s"] = "VISUAL",
                        s = "SELECT",
                        S = "SELECT",
                        ["\19"] = "SELECT",
                        i = "INSERT",
                        ic = "INSERT",
                        ix = "INSERT",
                        R = "REPLACE",
                        Rc = "REPLACE",
                        Rx = "REPLACE",
                        Rv = "REPLACE",
                        Rvc = "REPLACE",
                        Rvx = "REPLACE",
                        c = "COMMAND",
                        cv = "Ex",
                        r = "...",
                        rm = "M",
                        ["r?"] = "?",
                        ["!"] = "!",
                        t = "TERMINAL",
                    },
                    mode_colors = mode_colors,
                },
                update = {
                    "ModeChanged",
                    pattern = "*:*",
                    callback = vim.schedule_wrap(function()
                        vim.cmd("redrawstatus")
                    end),
                },
                {
                    provider = function(self)
                        return string.format(" %s ", self.mode_names[vim.fn.mode(1)])
                    end,
                    hl = function(self)
                        return { bg = self.mode_colors[vim.fn.mode(1):sub(1, 1)], bold = true, fg = c.bg_dark }
                    end,
                },
                space,
            },
            {
                condition = conditions.is_git_repo,
                init = function(self)
                    self.status_dict = vim.b.gitsigns_status_dict
                    self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
                end,
                {
                    static = { mode_colors = mode_colors },
                    provider = function(self)
                        return string.format(" %s %s ", utils.icons.git.branch, self.status_dict.head)
                    end,
                    hl = function(self)
                        return { fg = cutil.darken(self.mode_colors[vim.fn.mode(1):sub(1, 1)], 0.8), bold = true, bg = c.fg_gutter }
                    end,
                },
                {
                    provider = function(self)
                        local count = self.status_dict.added or 0
                        return count > 0 and string.format(" %s %s", utils.icons.git.add, count)
                    end,
                    hl = { fg = c.green2, bg = c.bg_statusline, bold = true },
                },
                {
                    provider = function(self)
                        local count = self.status_dict.removed or 0
                        return count > 0 and string.format(" %s %s", utils.icons.git.remove, count)
                    end,
                    hl = { fg = c.red, bg = c.bg_statusline, bold = true },
                },
                {
                    provider = function(self)
                        local count = self.status_dict.changed or 0
                        return count > 0 and string.format(" %s %s", utils.icons.git.modified, count)
                    end,
                    hl = { fg = c.yellow, bg = c.bg_statusline, bold = true },
                },
            },
            align,
            {
                condition = function()
                    return #vim.api.nvim_list_tabpages() >= 2
                end,
                hutils.make_tablist({
                    provider = function(self)
                        return string.format(" %s ", self.tabpage)
                    end,
                    static = { mode_colors = mode_colors },
                    hl = function(self)
                        if not self.is_active then
                            return { bg = self.mode_colors[vim.fn.mode():sub(1, 1)], bold = true, fg = c.bg_dark }
                        else
                            return { bg = c.fg_gutter, bold = true, fg = c.bg_dark }
                        end
                    end,
                }),
            },
            align,
            {
                condition = conditions.has_diagnostics,
                init = function(self)
                    self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
                    self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
                    self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
                    self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
                end,
                update = { "DiagnosticChanged", "BufEnter" },
                {
                    {
                        provider = function(self)
                            return self.errors > 0 and string.format("%s %s", utils.icons.diagnostics.ERROR, self.errors)
                        end,
                        hl = { fg = c.error, bg = c.bg_statusline, bold = true },
                    },
                    {
                        provider = function(self)
                            return self.warnings > 0 and string.format(" %s %s", utils.icons.diagnostics.WARN, self.warnings)
                        end,
                        hl = { fg = c.warning, bg = c.bg_statusline, bold = true },
                    },
                    {
                        provider = function(self)
                            return self.info > 0 and string.format(" %s %s", utils.icons.diagnostics.INFO, self.info)
                        end,
                        hl = { fg = c.info, bg = c.bg_statusline, bold = true },
                    },
                    {
                        provider = function(self)
                            return self.hints > 0 and string.format(" %s %s", utils.icons.diagnostics.HINT, self.hints)
                        end,
                        hl = { fg = c.hint, bg = c.bg_statusline, bold = true },
                    },
                },
                space,
            },
            {
                condition = function()
                    return vim.fn.reg_recording() ~= "" and vim.o.cmdheight == 0
                end,
                {
                    update = { "RecordingEnter", "RecordingLeave", "ModeChanged" },
                    static = { mode_colors = mode_colors },
                    provider = function()
                        return string.format(" recording @%s ", vim.fn.reg_recording())
                    end,
                    hl = function(self)
                        return { fg = cutil.darken(self.mode_colors[vim.fn.mode(1):sub(1, 1)], 0.8), bold = true, bg = c.fg_gutter }
                    end,
                },
                space,
            },
            {
                condition = conditions.lsp_attached,
                update = { "LspAttach", "LspDetach", "ModeChanged" },
                static = { mode_colors = mode_colors },
                {
                    provider = function()
                        local names = {}
                        for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
                            table.insert(names, server.name)
                        end
                        return string.format(" %s ", table.concat(names, " "))
                    end,
                    hl = function(self)
                        return { fg = cutil.darken(self.mode_colors[vim.fn.mode(1):sub(1, 1)], 0.8), bold = true, bg = c.fg_gutter }
                    end,
                },
                space,
            },
            {
                provider = " %l:%c %P ",
                static = { mode_colors = mode_colors },
                hl = function(self)
                    return { bg = self.mode_colors[vim.fn.mode():sub(1, 1)], bold = true, fg = c.bg_dark }
                end,
            },
        }

        local function harpoon_winbar(tab_component)
            return {
                init = function(self)
                    local items = require("harpoon"):list().items
                    local current_buf = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
                    for idx = 1, #items do
                        local child = self[idx]
                        if not (child and child.hpnr == idx) then
                            self[idx] = self:new(tab_component, idx)
                            child = self[idx]
                            child.hpnr = idx
                        end
                        if tostring(items[idx].value) == current_buf then
                            child.is_active = true
                            self.active_child = items[idx].value
                        else
                            child.is_active = false
                        end
                    end

                    if #self > #items then
                        for i = #self, #items + 1, -1 do
                            self[i] = nil
                        end
                    end
                end,
            }
        end

        opts.winbar = {
            {
                init = function(self)
                    self.icon, self.icon_hl = require("mini.icons").get("file", vim.api.nvim_buf_get_name(0))
                end,
                static = { mode_colors = mode_colors },
                {
                    provider = function(self)
                        return string.format(" %s ", self.icon)
                    end,
                    hl = function(self)
                        return {
                            fg = hutils.get_highlight(self.icon_hl).fg,
                            bg = c.bg_statusline,
                            underline = true,
                            sp = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
                        }
                    end,
                },
                space,
                {
                    provider = function()
                        local cwd = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
                        if not conditions.width_percent_below(#cwd, 0.25) then
                            cwd = vim.fn.pathshorten(cwd, 1)
                        end
                        return string.format("%s", cwd)
                    end,
                    hl = function(self)
                        return {
                            fg = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
                            bg = c.bg_statusline,
                            underline = true,
                            sp = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
                            bold = true,
                        }
                    end,
                },
            },
            {
                condition = function()
                    return require("nvim-navic").is_available()
                end,
                static = {
                    type_hl = {
                        File = "Directory",
                        Module = "@include",
                        Namespace = "@namespace",
                        Package = "@include",
                        Class = "@structure",
                        Method = "@method",
                        Property = "@property",
                        Field = "@field",
                        Constructor = "@constructor",
                        Enum = "@field",
                        Interface = "@type",
                        Function = "@function",
                        Variable = "@variable",
                        Constant = "@constant",
                        String = "@string",
                        Number = "@number",
                        Boolean = "@boolean",
                        Array = "@field",
                        Object = "@type",
                        Key = "@keyword",
                        Null = "@comment",
                        EnumMember = "@field",
                        Struct = "@structure",
                        Event = "@keyword",
                        Operator = "@operator",
                        TypeParameter = "@type",
                    },
                    enc = function(line, col, winnr)
                        return bit.bor(bit.lshift(line, 16), bit.lshift(col, 6), winnr)
                    end,
                    dec = function(cl)
                        return bit.rshift(cl, 16), bit.band(bit.rshift(cl, 6), 1023), bit.band(cl, 63)
                    end,
                    mode_colors = mode_colors,
                },
                init = function(self)
                    local data = require("nvim-navic").get_data() or {}
                    local children = {}
                    for i, d in ipairs(data) do
                        local pos = self.enc(d.scope.start.line, d.scope.start.character, self.winnr)
                        local child = {
                            {
                                provider = string.format("%s ", d.icon),
                                hl = {
                                    fg = hutils.get_highlight(self.type_hl[d.type]).fg,
                                    bg = c.bg_statusline,
                                    underline = true,
                                    sp = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
                                },
                            },
                            {
                                provider = d.name:gsub("%%", "%%%%"):gsub("%s*->%s*", ""),
                                hl = {
                                    fg = hutils.get_highlight(self.type_hl[d.type]).fg,
                                    bg = c.bg_statusline,
                                    underline = true,
                                    bold = false,
                                    sp = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
                                },
                                on_click = {
                                    minwid = pos,
                                    callback = function(_, minwid)
                                        local line, col, winnr = self.dec(minwid)
                                        vim.api.nvim_win_set_cursor(vim.fn.win_getid(winnr), { line, col })
                                    end,
                                    name = "heirline_navic",
                                },
                            },
                        }
                        if #data > 1 and i < #data then
                            table.insert(child, {
                                provider = "   ",
                                hl = {
                                    fg = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
                                    bold = true,
                                    underline = true,
                                    sp = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
                                    bg = c.bg_statusline,
                                },
                            })
                        end
                        table.insert(children, child)
                    end
                    self.child = self:new(children, 1)
                end,
                update = { "CursorMoved", "ModeChanged" },
                {
                    provider = "   ",
                    hl = function(self)
                        return {
                            fg = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
                            bold = true,
                            underline = true,
                            sp = self.mode_colors[vim.fn.mode(1):sub(1, 1)],
                            bg = c.bg_statusline,
                        }
                    end,
                },
                {
                    provider = function(self)
                        return self.child:eval()
                    end,
                },
            },
            align,
            {
                condition = function()
                    return require("harpoon"):list():length() > 1
                end,
                static = { mode_colors = mode_colors },
                harpoon_winbar({
                    provider = function(self)
                        return string.format(" %s ", self.hpnr) or ""
                    end,
                    hl = function(self)
                        if not self.is_active then
                            return {
                                bg = c.fg_gutter,
                                bold = true,
                                fg = self.mode_colors[vim.fn.mode():sub(1, 1)],
                                underline = true,
                                sp = self.mode_colors[vim.fn.mode():sub(1, 1)],
                            }
                        else
                            return {
                                bg = self.mode_colors[vim.fn.mode():sub(1, 1)],
                                bold = true,
                                fg = c.bg_dark,
                                underline = true,
                                sp = self.mode_colors[vim.fn.mode():sub(1, 1)],
                            }
                        end
                    end,
                }),
            },
        }

        opts.statuscolumn = {
            condition = function()
                return not conditions.buffer_matches({
                    buftype = { "nofile", "prompt", "help", "quickfix", "terminal" },
                    filetype = { "dashboard", "fzf", "harpoon", "oil", "diff" },
                })
            end,
            provider = utils.stc.statuscolumn,
        }
        opts.opts = {
            disable_winbar_cb = function(args)
                return conditions.buffer_matches({
                    buftype = { "nofile", "prompt", "help", "quickfix", "terminal" },
                    filetype = { "dashboard", "oil", "lspinfo", "toggleterm", "fzf", "diff", "dbui", "dbout" },
                }, args.buf)
            end,
        }
    end,
}
