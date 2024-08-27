return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "ipynb", "markdown", "tex" },
	opts = function()
		return {
			preset = "obsidian",
			heading = { border = "thick", left_pad = 1 },
			code = { width = "full", style = "language", left_pad = 2 },
			bullet = { left_pad = 4, highlight = "RenderMarkdownBullet" },
			sign = { enabled = true, highlight = "RenderMarkdownSign" },
			callout = {
				note = { raw = "[!NOTE]", rendered = "󰋽  Note", highlight = "RenderMarkdownInfo" },
				tip = { raw = "[!TIP]", rendered = "󰌶  Tip", highlight = "RenderMarkdownSuccess" },
				important = { raw = "[!IMPORTANT]", rendered = "󰅾  Important", highlight = "RenderMarkdownHint" },
				warning = { raw = "[!WARNING]", rendered = "󰀪  Warning", highlight = "RenderMarkdownWarn" },
				caution = { raw = "[!CAUTION]", rendered = "󰳦  Caution", highlight = "RenderMarkdownError" },
				abstract = { raw = "[!ABSTRACT]", rendered = "󰨸  Abstract", highlight = "RenderMarkdownInfo" },
				todo = { raw = "[!TODO]", rendered = "󰗡  Todo", highlight = "RenderMarkdownInfo" },
				success = { raw = "[!SUCCESS]", rendered = "󰄬  Success", highlight = "RenderMarkdownSuccess" },
				question = { raw = "[!QUESTION]", rendered = "󰘥  Question", highlight = "RenderMarkdownWarn" },
				failure = { raw = "[!FAILURE]", rendered = "󰅖  Failure", highlight = "RenderMarkdownError" },
				danger = { raw = "[!DANGER]", rendered = "󱐌  Danger", highlight = "RenderMarkdownError" },
				bug = { raw = "[!BUG]", rendered = "󰨰  Bug", highlight = "RenderMarkdownError" },
				example = { raw = "[!EXAMPLE]", rendered = "󰉹  Example", highlight = "RenderMarkdownHint" },
				quote = { raw = "[!QUOTE]", rendered = "󱆨  Quote", highlight = "RenderMarkdownQuote" },
			},
		}
	end,
	config = function(_, opts)
		require("render-markdown").setup(opts)
	end,
}
