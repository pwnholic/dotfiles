require("tokyonight").setup({
	style = "night",
	transparent = false,
	styles = { sidebars = "normal", floats = "normal" },
	sidebars = {
		"toggleterm",
		"qf",
		"oil",
		"help",
		"terminal",
		"neotest-summary",
		"dashboard",
		"Trouble",
		"lazyterm",
	},
	on_highlights = function(hl, c)
		local util = require("tokyonight.util")

		hl.Visual = { bg = c.bg_visual, bold = true, italic = true }
		hl.VisualNOS = { bg = c.bg_visual, bold = true, italic = true }
		hl.WinBar = { bg = c.bg_statusline, underline = true, sp = c.blue2 }
		hl.WinBarNC = { link = "WinBar" }
		hl.PmenuSel = { bg = util.darken(c.purple, 0.4), bold = true }
		hl.StatusLine = { bg = c.bg_statusline }
		hl.TreesitterContext = { underline = true, sp = util.darken(c.purple, 0.7) }
		hl.WinSeparator = { link = "Comment" }
		hl.LineNr = { fg = util.darken(c.purple, 0.6), bg = c.none, bold = true }
		hl.CursorLineNr = { fg = c.cyan, bg = c.none, bold = true }
		hl.FloatBorder = { link = "Comment" }

		hl.TermCursor = { bg = c.green }

		hl.WhichKey = { fg = c.cyan, bg = c.none, bold = true }
		hl.WhichKeyGroup = { fg = c.orange, bg = c.none, bold = true }

		hl.CmpGhostText = { fg = util.darken(c.yellow, 0.7), bg = c.none, bold = true }
		hl.CmpItemAbbr = { fg = "#ffffff", bg = c.none }
		hl.CmpItemAbbrMatch = { fg = c.cyan1, bg = c.none }
		hl.CmpItemAbbrMatchFuzzy = { fg = c.orange, bg = c.none }

		-- Gitsign
		hl.GitSignsAdd = { fg = c.green2, bg = c.none }
		hl.GitSignsChange = { fg = c.yellow1, bg = c.none }
		hl.GitSignsDelete = { fg = c.red1, bg = c.none }
		hl.GitSignsCurrentLineBlame = { fg = util.darken(c.purple, 0.7), bg = c.none }

		-- Mason
		hl.MasonHeader = { bg = c.red, fg = c.none }
		hl.MasonHighlight = { fg = c.blue }
		hl.MasonHighlightBlock = { fg = c.none, bg = c.green }
		hl.MasonHighlightBlockBold = { link = "MasonHighlightBlock" }
		hl.MasonHeaderSecondary = { link = "MasonHighlightBlock" }
		hl.MasonMuted = { fg = c.grey }
		hl.MasonMutedBlock = { fg = c.grey, bg = c.one_bg }

		-- Syntax
		hl.Constant = { fg = c.orange, italic = true, bold = true }
		hl.String = { fg = c.green, italic = true }
		hl.Boolean = { fg = c.blue1, italic = true }
		hl.Function = { fg = c.blue, bold = true, italic = false }
		hl.Conditional = { fg = c.cyan, italic = true }
		hl.Operator = { fg = c.blue5, bold = true }
		hl.Keyword = { fg = c.purple, italic = true }
		hl.Structure = { fg = c.magenta, italic = true }
		hl.Label = { fg = c.orange, bold = true }
		hl.Type = { fg = c.blue1, italic = true }

		-- LSP
		hl.IlluminatedWordText = { italic = true, bold = true, reverse = true }
		hl.IlluminatedWordRead = { italic = true, bold = true, reverse = true }
		hl.IlluminatedWordWrite = { italic = true, bold = true, reverse = true }
		hl.LspReferenceText = { italic = true, bold = true, reverse = true }
		hl.LspReferenceRead = { italic = true, bold = true, reverse = true }
		hl.LspReferenceWrite = { italic = true, bold = true, reverse = true }
		hl.LspSignatureActiveParameter = { italic = true, bold = true, reverse = true }
		hl.LspCodeLens = { link = "DiagnosticVirtualTextHint", default = true }
		hl.LspCodeLensText = { link = "DiagnosticVirtualTextHint", default = true }
		hl.LspCodeLensSign = { link = "DiagnosticVirtualTextHint", default = true }
		hl.LspCodeLensSeparator = { link = "Boolean", default = true }
		hl.LspInlayHint = { fg = c.comment, underline = true, sp = util.darken(c.purple1, 0.8) }
		hl.CodeActionVirtulText = { fg = c.orange, bg = c.none, italic = true }

		hl.DiagnosticFloatingError = { link = "DiagnosticError", default = true }
		hl.DiagnosticFloatingWarn = { link = "DiagnosticWarn", default = true }
		hl.DiagnosticFloatingInfo = { link = "DiagnosticInfo", default = true }
		hl.DiagnosticFloatingHint = { link = "DiagnosticHint", default = true }

		-- hl.OilFile = { link = "CmpItemAbbr" }
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
		hl.OilPermissionWrite = { fg = util.lighten(c.yellow, 0.5), bg = c.none, bold = true }
		hl.OilPermissionExecute = { fg = c.teal, bg = c.none, bold = true }
		hl.OilTypeDir = { link = "Directory" }
		hl.OilTypeFifo = { link = "Special" }
		hl.OilTypeFile = { link = "NonText" }
		hl.OilTypeLink = { link = "Constant" }
		hl.OilTypeSocket = { link = "OilSocket" }

		hl.DashboardHeader = { fg = c.cyan1, bg = c.none }
		hl.DashboardIcon = { fg = c.yellow1, bg = c.none }
		hl.DashboardFooter = { fg = c.green2, bg = c.none, bold = true }
		hl.DashboardDesc = { fg = c.grey, bg = c.none, bold = true }
		hl.DashboardKey = { fg = c.magenta2, bg = c.none, bold = true }

		hl.FzfLuaBorder = { link = "Comment" }
		hl.FzfLuaTitle = { link = "DashboardIcon" }
		hl.FzfLuaHeaderText = { fg = c.cyan, bg = c.none, bold = true }
		hl.FzfLuaHeaderBind = { fg = c.orange, bg = c.none, bold = true }
		hl.FzfLuaPrompt = { fg = c.green2, bg = c.none, bold = true }
		hl.FzfLuaDirIcon = { link = "OilDirIcon" }

		hl["@task_list_marker_unchecked"] = { fg = c.error, bg = c.none, bold = true }
		hl["@task_list_marker_checked"] = { fg = c.green, bg = c.none, italic = true }
		hl["@block_quote_marker"] = { fg = c.yellow1 }
		hl["@strong_emphasis"] = { fg = c.orange, bold = true, underline = true }
		hl["@strikethrough"] = { fg = c.teal, italic = true }
		hl["@emphasis"] = { fg = c.cyan1, italic = true, underline = true }
		hl["@string_scalar"] = { fg = c.yellow, bold = true } -- yaml
		hl["@pipe_table_header"] = { fg = c.green, bold = true }
		hl["@markup.link.label"] = { fg = c.cyan1, italic = true, underline = true, sp = c.yellow1 }
	end,
	on_colors = function(color)
		color.green2 = "#2bff05"
		color.yellow1 = "#faf032"
		color.cyan1 = "#00ffee"
		color.purple1 = "#f242f5"
		color.red2 = "#eb0000"
		color.black1 = "#000000"
	end,
})

vim.cmd.colorscheme("tokyonight-night")
