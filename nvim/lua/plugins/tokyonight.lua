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
            local util = require("tokyonight.util")
            hl.TreesitterContextLineNumber = { fg = c.comment, bg = c.none }
            hl.CursorLineNr = { fg = c.orange, bg = c.none, bold = true }
            hl.LineNr = { fg = c.orange, bg = c.none, bold = true }
            hl.LineNrAbove = { fg = c.red, bg = c.none }
            hl.LineNrBelow = { fg = c.blue1, bg = c.none }
            hl.LspCodeLens = { link = "DiagnosticVirtualTextHint", default = true }
            hl.LspCodeLensText = { link = "DiagnosticVirtualTextHint", default = true }
            hl.LspCodeLensSign = { link = "DiagnosticVirtualTextHint", default = true }
            hl.LspCodeLensSeparator = { link = "Boolean", default = true }
            hl.LspInlayHint = { fg = c.dark5, bg = c.none, underline = true, italic = true }
            hl.LspSignatureActiveParameter = { fg = c.magenta2, italic = true, bold = true, sp = c.yellow1, underline = true }
            hl.GitSignsCurrentLineBlame = { fg = c.dark5, bg = c.none }
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
            hl.FzfLuaDirPart = { fg = c.magenta }
            hl.FzfLuaBorder = { fg = c.green, bg = c.none }
            hl.FzfLuaPreviewBorder = { fg = c.purple, bg = c.none }
            hl.FzfLuaFilePart = { fg = "#ffffff" }
            hl.FzfLuaFzfCursorLine = { bg = c.fg_gutter }
            hl.FzfLuaFzfInfo = { fg = c.info, bg = c.none }
            hl.RenderMarkdownBullet = { fg = c.red, bg = c.none }
            hl.GoJsonTags = { fg = c.red, bg = c.bg_dark }
            hl.PmenuSel = { bg = c.fg_gutter, bold = true, underline = true, sp = c.orange }
            hl.Pmenu = { link = "FzfLuaFilePart" }
            hl.FloatBorder = { fg = c.comment, bg = c.none }
            hl.WinSeparator = { bg = c.none, fg = c.comment }
            hl.MiniHipatternsJson = { fg = c.purple, bg = c.none, bold = true }
            hl.MiniHipatternsGorm = { fg = c.yellow, bg = c.none, bold = true }
            hl.MiniHipatternsValidate = { fg = c.blue1, bg = c.none, bold = true }
            hl.MiniHipatternsBinding = { fg = c.teal, bg = c.none, bold = true }
            hl.NvimDapVirtualText = { fg = c.comment, bg = c.none, italic = true, underline = true, sp = c.teal }
            hl.SnacksDashboardHeader = { fg = c.green, bg = c.none }
            hl.SnacksDashboardIcon = { fg = c.red1, bg = c.none }
            hl["@variable.parameter"] = { fg = c.yellow, italic = true, bg = c.none }
            hl["@keyword.return"] = { fg = c.purple, bold = true, bg = c.none }
            hl["@type.builtin"] = { fg = c.blue1, bold = true, bg = c.none }
            hl.DiagnosticVirtualTextError = { bg = util.blend_bg(c.error, 0.1), fg = c.error, bold = true }
            hl.DiagnosticVirtualTextWarn = { bg = util.blend_bg(c.warning, 0.1), fg = c.warning, italic = true }
            hl.TreesitterContext = { underline = true, sp = c.purple, bold = true }
            -- hl.FzfLuaTitle = { fg = c.bg_dark, bg = c.yellow, bold = true }
            -- hl.FzfLuaPreviewTitle = { fg = c.bg_dark, bg = c.cyan, bold = true }
            hl.LualineLspClient = { fg = c.blue1, bg = c.bg_dark }
        end,
    },
}
