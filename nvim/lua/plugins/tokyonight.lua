return {
    "folke/tokyonight.nvim",
    priority = 1000,
    lazy = false,
    opts = function()
        return {
            style = "night",
            transparent = false,
            terminal_colors = true,
            styles = {
                comments = { italic = false },
                keywords = { italic = true },
                functions = { bold = true },
                sidebars = "dark",
                floats = "dark",
            },
            on_colors = function(c)
                c.red2 = "#ed3326"
                c.green3 = "#30ed26"
                c.yellow1 = "#eaed26"
            end,
            on_highlights = function(hl, c)
                hl.WinBar = { bg = c.bg_statusline, underline = true, sp = c.blue2 }
                hl.WinBarNC = { link = "WinBar" }
                hl.StatusLine = { bg = c.bg_statusline }
                hl.CursorLineNr = { fg = c.cyan, bg = c.none, bold = true }
                hl.WinSeparator = { link = "Comment" }
                hl.FloatBorder = { fg = c.bg_statusline, bg = c.bg_statusline }
                hl.MarkIcons = { fg = c.cyan, bold = true }

                hl.DashboardHeader = { fg = c.teal, bg = c.none }
                hl.DashboardIcon = { fg = c.yellow, bg = c.none }
                hl.DashboardFooter = { fg = c.green, bg = c.none, bold = true }
                hl.DashboardDesc = { fg = c.grey, bg = c.none, bold = true }
                hl.DashboardKey = { fg = c.magenta2, bg = c.none, bold = true }

                hl.LspReferenceText = { italic = true, bold = true, reverse = true }
                hl.LspReferenceRead = { italic = true, bold = true, reverse = true }
                hl.LspReferenceWrite = { italic = true, bold = true, reverse = true }
                hl.LspSignatureActiveParameter = { italic = true, bold = true, reverse = true }
                hl.LspCodeLens = { link = "DiagnosticVirtualTextHint", default = true }
                hl.LspCodeLensText = { link = "DiagnosticVirtualTextHint", default = true }
                hl.LspCodeLensSign = { link = "DiagnosticVirtualTextHint", default = true }
                hl.LspCodeLensSeparator = { link = "Boolean", default = true }

                hl.OilDir = { fg = c.orange, bg = c.none, bold = true }
                hl.OilDirIcon = { fg = c.orange, bg = c.none }
                hl.OilLink = { link = "Constant" }
                hl.OilLinkTarget = { link = "Comment" }
                hl.OilCopy = { link = "DiagnosticSignHint", bold = true }
                hl.OilMove = { link = "DiagnosticSignWarn", bold = true }
                hl.OilChange = { link = "DiagnosticSignWarn", bold = true }
                hl.OilCreate = { link = "DiagnosticSignInfo", bold = true }
                hl.OilDelete = { link = "DiagnosticSignError", bold = true }
                hl.OilPermissionNone = { link = "NonText" }
                hl.OilPermissionRead = { fg = c.red1, bg = c.none, bold = true }
                hl.OilPermissionWrite = { fg = c.yellow, bg = c.none, bold = true }
                hl.OilPermissionExecute = { fg = c.teal, bg = c.none, bold = true }
                hl.OilTypeDir = { link = "Directory" }
                hl.OilTypeFifo = { link = "Special" }
                hl.OilTypeFile = { link = "NonText" }
                hl.OilTypeLink = { link = "Constant" }
                hl.OilTypeSocket = { link = "OilSocket" }
                hl.OilSize = { fg = c.teal, bg = c.none }
                hl.OilMtime = { fg = c.purple, bg = c.none }

                hl.FzfLuaDirPart = { fg = c.blue2 }
                hl.FzfLuaBorder = { fg = c.bg_dark, bg = c.bg_dark }
                hl.FzfLuaFilePart = { fg = "#ffffff" }
                hl.FzfLuaFzfCursorLine = { bg = c.fg_gutter }

                hl.RenderMarkdownBullet = { fg = c.red, bg = c.none }

                hl.ChoiceNode = { fg = c.orange, bg = c.bg_dark }
                hl.InsertNode = { fg = c.green, bg = c.bg_dark }
                hl.ExitNode = { fg = c.red, bg = c.bg_dark }
            end,
            cache = true,
        }
    end,
    config = function(_, opts)
        require("tokyonight").setup(opts)
        vim.cmd.colorscheme("tokyonight")
    end,
}
