local opts = {
	query = vim.treesitter.query.parse(
		"markdown",
		[[
    (atx_heading [ (atx_h1_marker) (atx_h2_marker) (atx_h3_marker) (atx_h4_marker) (atx_h5_marker) (atx_h6_marker) ] @headline)
    (thematic_break) @dash
    (fenced_code_block) @codeblock
    (block_quote_marker) @quote
    (block_quote (paragraph (inline (block_continuation) @quote)))
    (block_quote (paragraph (block_continuation) @quote))
    (block_quote (block_continuation) @quote)
 ]]
	),
	headline_highlights = {
		"@markup.heading.1.markdown",
		"@markup.heading.2.markdown",
		"@markup.heading.3.markdown",
		"@markup.heading.4.markdown",
		"@markup.heading.5.markdown",
		"@markup.heading.6.markdown",
	},
	bullet_highlights = {
		"@markup.heading.1.markdown",
		"@markup.heading.2.markdown",
		"@markup.heading.3.markdown",
		"@markup.heading.4.markdown",
		"@markup.heading.5.markdown",
		"@markup.heading.6.markdown",
	},
	bullets = {},
	codeblock_highlight = "CodeBlock",
	dash_highlight = "Dash",
	dash_string = "━",
	quote_highlight = "Quote",
	quote_string = "┃",
	fat_headlines = false,
}
return vim.schedule(function()
	require("headlines").setup({ markdown = opts, rmd = opts })
	require("headlines").refresh()
end)
