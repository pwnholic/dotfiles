return {
    "folke/tokyonight.nvim",
    opts = {
        transparent = false,
        style = "night",
        styles = {
            sidebars = "normal", -- style for sidebars, see below
            floats = "normal", -- style for floating windows
        },
        on_highlights = function(hl, c)
            -- core float + window edges (border grey, title chip blue)
            hl.FloatBorder = { fg = c.dark3, bg = c.none }
            hl.WinSeparator = { fg = c.dark3, bg = c.none }
            hl.VertSplit = { fg = c.dark3, bg = c.none }
            hl.StatusLine = { bg = c.none }
            hl.StatusLineNC = { bg = c.none }
            hl.TabLineFill = { bg = c.none }

            hl.SnacksTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            hl.SnacksPickerTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            hl.SnacksPickerBoxTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            hl.SnacksPickerInputTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            -- Snacks input (also backs `vim.ui.input`).
            hl.SnacksInputTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            -- Which-key / noice titles ride along (borders below stay grey).
            hl.WhichKeyTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            -- keep borders grey: Blink completion/doc/signature borders
            -- don't link to FloatBorder; they set the blue tint directly.
            hl.BlinkCmpMenuBorder = { fg = c.dark3, bg = c.none }
            hl.BlinkCmpDocBorder = { fg = c.dark3, bg = c.none }
            hl.BlinkCmpSignatureHelpBorder = { fg = c.dark3, bg = c.none }
            -- LSP hover/signature + mason popups.
            hl.LspFloatBorder = { fg = c.dark3, bg = c.none }
            hl.LspInfoBorder = { fg = c.dark3, bg = c.none }
            hl.MasonNormal = { bg = c.none }
            hl.MasonHeader = { fg = c.dark3, bg = c.none }
            hl.MasonHighlightBlock = { bg = c.none }
            -- Snacks picker/input chrome (grey, not title chips).
            hl.SnacksPickerBorder = { fg = c.dark3, bg = c.none }
            hl.SnacksPickerInputBorder = { fg = c.dark3, bg = c.none }
            hl.SnacksInputBorder = { fg = c.dark3, bg = c.none }
            hl.SnacksInputIcon = { fg = c.dark3 }

            hl.SnacksIndentScope = { fg = c.orange, nocombine = true }
            hl.SnacksDashboardHeader = { fg = c.dark3 }

            hl.LspInlayHint = { fg = c.comment, bg = c.none, underline = true, sp = c.teal }
            hl.LspCodeLens = { fg = c.comment, bg = c.none, italic = true }
            hl.LspCodeLensSeparator = { fg = c.dark3, bg = c.none }
            hl.LspReferenceText = { bg = c.none, underline = true }
            hl.LspReferenceRead = { bg = c.none, underline = true }
            hl.LspReferenceWrite = { bg = c.none, underline = true }

            hl.TreesitterContext = { bg = c.none }
            hl.TreesitterContextBottom = { bg = c.none, underline = true, sp = c.cyan }
            hl.TreesitterContextLineNumberBottom = { bg = c.none, underline = true, sp = c.cyan }
            -- Oil preview/confirmation floats set their own bg too.
            hl.OilPreview = { bg = c.none }

            hl.WhichKeyBorder = { fg = c.dark3, bg = c.none }
            hl.SnacksNotifierBorderError = { fg = c.red1, bg = c.none }
            hl.SnacksNotifierBorderWarn = { fg = c.yellow, bg = c.none }
            hl.SnacksNotifierBorderInfo = { fg = c.blue2, bg = c.none }
            hl.SnacksNotifierBorderTrace = { fg = c.purple, bg = c.none }
            hl.SnacksNotifierBorderDebug = { fg = c.comment, bg = c.none }
        end,
    },
}
