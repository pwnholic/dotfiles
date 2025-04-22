return {
    "folke/tokyonight.nvim",
    opts = {
        style = "night",
        dim_inactive = true,
        transparent = false,
        lualine_bold = true,
        cache = true,
        styles = {
            sidebars = "dark",
            floats = "normal",
            keywords = { italic = true },
            functions = { bold = true, italic = true },
            variables = {},
        },
        on_highlights = function(hl, c)
            hl.WinSeparator = { bg = c.none, fg = c.comment }
            hl.FloatBorder = { link = "Comment" }
            hl.LualineLspClient = { fg = c.cyan, bg = c.none }
            hl.LualineTabActive = { fg = c.blue1, bg = c.none, bold = true }
            hl.LualineTabInActive = { fg = c.fg_dark, bg = c.none }

            hl.TreesitterContext = { bg = c.none, underline = true, sp = c.purple, bold = true }

            hl.CursorLineNr = { fg = c.magenta2, bg = c.none, bold = true }
            hl.LineNr = { fg = c.magenta2, bg = c.none, bold = true }
            hl.LineNrAbove = { fg = c.magenta, bg = c.none }
            hl.LineNrBelow = { fg = c.blue2, bg = c.none }
            hl.LspCodeLens = { link = "DiagnosticVirtualTextHint", default = true }
            hl.LspInlayHint = { fg = c.comment, bg = c.none, underline = true, sp = c.purple }

            hl.SnacksInputTitle = { fg = c.black, bg = c.orange, bold = true }

            hl.PomoTimer = { fg = c.orange, bg = c.none, bold = true }

            hl.OilTypeDir = { link = "Directory" }
            hl.OilTypeFifo = { link = "Special" }
            hl.OilTypeFile = { link = "NonText" }
            hl.OilTypeLink = { link = "Constant" }
            hl.OilTypeSocket = { link = "OilSocket" }
            hl.OilPermissionNone = { link = "NonText" }
            hl.OilPermissionRead = { fg = c.red1, bg = c.none, bold = true }
            hl.OilPermissionWrite = { fg = c.yellow, bg = c.none, bold = true }
            hl.OilPermissionExecute = { fg = c.teal, bg = c.none, bold = true }

            hl.MiniHipatternsJson = { fg = c.purple, bg = c.none, bold = true }
            hl.MiniHipatternsGorm = { fg = c.yellow, bg = c.none, bold = true }
            hl.MiniHipatternsValidate = { fg = c.blue1, bg = c.none, bold = true }
            hl.MiniHipatternsBinding = { fg = c.teal, bg = c.none, bold = true }
        end,
    },
}
