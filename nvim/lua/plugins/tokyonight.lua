return {
    "folke/tokyonight.nvim",
    opts = {
        style = "night",
        dim_inactive = true,
        transparent = false,
        lualine_bold = true,
        cache = true,
        styles = {
            sidebars = "normal",
            floats = "normal",
            keywords = { italic = true },
            functions = { bold = true },
            variables = {},
        },
        on_highlights = function(hl, c)
            hl.LspCodeLens = { link = "DiagnosticVirtualTextHint", default = true }
            hl.LspCodeLensText = { link = "DiagnosticVirtualTextHint", default = true }
            hl.LspCodeLensSign = { link = "DiagnosticVirtualTextHint", default = true }
            hl.LspCodeLensSeparator = { link = "Boolean", default = true }
            hl.LspInlayHint = { fg = c.dark5, bg = c.none, underline = true, italic = true }
            hl.LspSignatureActiveParameter =
                { fg = c.magenta2, italic = true, bold = true, sp = c.yellow1, underline = true }

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
            hl.FzfLuaBorder = { fg = c.bg_dark, bg = c.bg_dark }
            hl.FzfLuaFilePart = { fg = "#ffffff" }
            hl.FzfLuaFzfCursorLine = { bg = c.fg_gutter }
            hl.RenderMarkdownBullet = { fg = c.red, bg = c.none }
            hl.GoJsonTags = { fg = c.red, bg = c.bg_dark }

            hl.PmenuSel = { bg = c.fg_gutter, bold = true, underline = true, sp = c.teal }
            hl.Pmenu = { link = "FzfLuaFilePart" }
            hl.CmpItemKindText = { fg = "#82bab5", bg = c.none }
            hl.FloatBorder = { fg = c.comment, bg = c.none }
            hl.WinSeparator = { bg = c.none, fg = c.comment }
            hl.PmenuDark = { bg = c.bg_dark }

            hl.MiniHipatternsJson = { fg = c.purple, bg = c.none, bold = true }
            hl.MiniHipatternsGorm = { fg = c.yellow, bg = c.none, bold = true }
            hl.MiniHipatternsValidate = { fg = c.blue1, bg = c.none, bold = true }
            hl.MiniHipatternsBinding = { fg = c.teal, bg = c.none, bold = true }

            hl["@variable.parameter"] = { fg = c.yellow, italic = true, bg = c.none }
            hl["@keyword.return"] = { fg = c.purple, bold = true, bg = c.none }
            hl["@type.builtin"] = { fg = c.blue1, bold = true, bg = c.none }
        end,
    },
}