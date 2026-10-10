return {
    "folke/tokyonight.nvim",
    ---@class tokyonight.Config
    opts = {
        style = "night",
        styles = {
            sidebars = "normal", -- style for sidebars, see below
            floats = "normal", -- style for floating windows
        },
        on_highlights = function(hl, c)
            hl.FloatBorder = { fg = c.dark3, bg = c.none }
            hl.WinSeparator = { fg = c.dark3, bg = c.none }
            hl.VertSplit = { fg = c.dark3, bg = c.none }
            hl.StatusLine = { bg = c.none }
            hl.StatusLineNC = { bg = c.none }
            hl.TabLineFill = { bg = c.none }

            hl.BlinkCmpMenuBorder = { fg = c.dark3, bg = c.none }
            hl.BlinkCmpDocBorder = { fg = c.dark3, bg = c.none }
            hl.BlinkCmpSignatureHelpBorder = { fg = c.dark3, bg = c.none }

            hl.MasonNormal = { bg = c.none }
            hl.MasonHeader = { fg = c.dark3, bg = c.none }
            hl.MasonHighlightBlock = { bg = c.none }
            -- Chrome grey; notify keeps severity colors; titles are blue chips.

            hl.LspInlayHint = { fg = c.comment, bg = c.none, underline = true, sp = c.teal, italic = true }
            hl.LspCodeLens = { fg = c.comment, bg = c.none, italic = true }
            hl.LspCodeLensSeparator = { fg = c.dark3, bg = c.none }
            hl.LspReferenceText = { bg = c.none, underline = true }
            hl.LspReferenceRead = { bg = c.none, underline = true }
            hl.LspReferenceWrite = { bg = c.none, underline = true }
            hl.LspFloatBorder = { fg = c.dark3, bg = c.none }
            hl.LspInfoBorder = { fg = c.dark3, bg = c.none }

            hl.TreesitterContext = { bg = c.none }
            hl.TreesitterContextBottom = { bg = c.none, underline = true, sp = c.cyan }
            hl.TreesitterContextLineNumberBottom = { bg = c.none, underline = true, sp = c.cyan }

            hl.OilPreview = { bg = c.none }
            -- Mutation markers reuse stock diagnostic-style faces
            -- (Oil stock already links Create/Delete); yank target is cyan.
            hl.OilCopy = { fg = c.blue, bold = true }
            hl.OilMove = { fg = c.yellow, bold = true }
            hl.OilChange = { fg = c.yellow, bold = true }
            hl.OilLinkTarget = { fg = c.cyan }
            hl.OilSecurityContext = { fg = c.magenta }
            hl.OilSecurityExtended = { fg = c.magenta }

            -- `ls`-style permissions; size/mtime reuse stock Number/String.
            hl.OilPermissionNone = { fg = c.dark3 }
            hl.OilPermissionRead = { fg = c.blue }
            hl.OilPermissionWrite = { fg = c.yellow }
            hl.OilPermissionExecute = { fg = c.green }
            hl.OilPermissionSetuid = { fg = c.red, bold = true }
            hl.OilTypeFile = { fg = c.comment }
            hl.OilTypeDir = { fg = c.blue }
            hl.OilTypeLink = { fg = c.cyan }
            hl.OilTypeFifo = { fg = c.yellow }
            hl.OilTypeSocket = { fg = c.magenta }

            hl.WhichKeyBorder = { fg = c.dark3, bg = c.none }
            hl.WhichKeyTitle = { fg = c.bg_dark, bg = c.blue, bold = true }

            hl.NoiceCmdlinePopupBorder = { fg = c.dark3, bg = c.none }
            hl.NoiceCmdlinePopupBorderInput = { fg = c.dark3, bg = c.none }
            hl.NoiceCmdlinePopupBorderLua = { fg = c.dark3, bg = c.none }
            hl.NoiceCmdlinePopupTitleInput = { fg = c.bg_dark, bg = c.blue, bold = true }
            hl.NoiceCmdlinePopupTitleLua = { fg = c.bg_dark, bg = c.blue, bold = true }
            hl.NoiceCmdlineIconInput = { fg = c.dark3 }
            hl.NoiceCmdlineIconLua = { fg = c.dark3 }

            hl.SnacksNotifierBorderError = { fg = c.red1, bg = c.none }
            hl.SnacksNotifierBorderWarn = { fg = c.yellow, bg = c.none }
            hl.SnacksNotifierBorderInfo = { fg = c.blue2, bg = c.none }
            hl.SnacksNotifierBorderTrace = { fg = c.purple, bg = c.none }
            hl.SnacksNotifierBorderDebug = { fg = c.comment, bg = c.none }
            hl.SnacksNotifierTitleError = { fg = c.bg_dark, bg = c.red1, bold = true }
            hl.SnacksNotifierTitleWarn = { fg = c.bg_dark, bg = c.yellow, bold = true }
            hl.SnacksNotifierTitleInfo = { fg = c.bg_dark, bg = c.blue2, bold = true }
            hl.SnacksNotifierTitleTrace = { fg = c.bg_dark, bg = c.purple, bold = true }
            hl.SnacksNotifierTitleDebug = { fg = c.bg_dark, bg = c.comment, bold = true }
            hl.SnacksPickerBorder = { fg = c.dark3, bg = c.none }
            hl.SnacksPickerInputBorder = { fg = c.dark3, bg = c.none }
            hl.SnacksInputBorder = { fg = c.dark3, bg = c.none }
            hl.SnacksInputIcon = { fg = c.dark3 }
            hl.SnacksIndentScope = { fg = c.orange, nocombine = true }
            hl.SnacksDashboardHeader = { fg = c.dark3 }
            hl.SnacksTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            hl.SnacksPickerTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            hl.SnacksPickerBoxTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            hl.SnacksPickerInputTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            hl.SnacksInputTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
        end,
    },
}
