return {
    "folke/tokyonight.nvim",
    opts = {
        style = "night",
        styles = {
            comments = { italic = true },
            keywords = { italic = true },
            sidebars = "dark",
            floats = "dark",
        },
        on_highlights = function(hl, c)
            local comment = { link = "Comment" }
            local border = { fg = c.comment, bg = c.none }
            local border_dark = { fg = c.comment, bg = c.bg_dark }

            hl.WinSeparator = border_dark
            hl.FloatBorder = border_dark

            hl.BlinkCmpLabelDescription = comment
            hl.BlinkCmpLabelDetail = { fg = c.blue, bg = c.none, italic = true }

            hl.LualineTabActive = { fg = c.blue1, bg = c.none, bold = true }
            hl.LualineTabInActive = { fg = c.fg_dark, bg = c.none }

            hl.BlinkCmpMenuBorder = border_dark
            hl.BlinkCmpDocBorder = border_dark
            hl.BlinkCmpSignatureHelpBorder = border_dark

            local title = { fg = c.black, bg = c.orange, bold = true }
            hl.SnacksInputTitle = title
            hl.SnacksPickerInputTitle = title
            hl.SnacksPickerInputBorder = border_dark
            hl.SnacksPickerBoxTitle = title

            hl.FzfLuaDirPart = { fg = c.blue, bg = c.none }

            hl.TreesitterContext = { bg = c.bg_dark, bold = true, italic = true, underline = true, sp = c.blue }

            hl.CursorLineNr = { fg = c.bg_dark, bg = c.green, bold = true }
            -- hl.LineNr = { fg = c.magenta2, bg = c.none, bold = true }
            hl.LineNrAbove = { fg = c.magenta, bg = c.none }
            hl.LineNrBelow = { fg = c.blue2, bg = c.none }
            hl.LspCodeLens = { link = "DiagnosticVirtualTextHint" }
            hl.LspInlayHint = { fg = c.comment, bg = c.none, underline = true, sp = c.purple, italic = true }

            hl.MiniHipatternsJson = { fg = c.purple, bg = c.none, bold = true }
            hl.MiniHipatternsGorm = { fg = c.red, bg = c.none, bold = true }
            hl.MiniHipatternsValidate = { fg = c.blue1, bg = c.none, bold = true }
            hl.MiniHipatternsBinding = { fg = c.teal, bg = c.none, bold = true }

            hl.NvimLintRun = { link = "Constant" }

            hl.NoiceCmdlinePopupBorder = border
            hl.NoiceCmdlinePopupBorderCalculator = border
            hl.NoiceCmdlinePopupBorderCmdline = border
            hl.NoiceCmdlinePopupBorderFilter = border
            hl.NoiceCmdlinePopupBorderHelp = border
            hl.NoiceCmdlinePopupBorderInput = border
            hl.NoiceCmdlinePopupBorderLua = border
            hl.NoiceCmdlinePopupBorderSearch = border
        end,
    },
}
