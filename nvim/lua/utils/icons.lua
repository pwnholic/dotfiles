local M = {}

M.border = {
	rounded = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
	single = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
	double = { "═", "║", "═", "║", "╔", "╗", "╝", "╚" },
	double_header = { "═", "│", "─", "│", "╒", "╕", "┘", "└" },
	double_bottom = { "─", "│", "═", "│", "┌", "┐", "╛", "╘" },
	double_horizontal = { "═", "│", "═", "│", "╒", "╕", "╛", "╘" },
	double_left = { "─", "│", "─", "│", "╓", "┐", "┘", "╙" },
	double_right = { "─", "│", "─", "│", "┌", "╖", "╜", "└" },
	double_vertical = { "─", "│", "─", "│", "╓", "╖", "╜", "╙" },
	vintage = { "-", "|", "-", "|", "+", "+", "+", "+" },
	rounded_clc = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
	single_clc = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
	double_clc = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
	double_header_clc = { "╒", "═", "╕", "│", "┘", "─", "└", "│" },
	double_bottom_clc = { "┌", "─", "┐", "│", "╛", "═", "╘", "│" },
	double_horizontal_clc = { "╒", "═", "╕", "│", "╛", "═", "╘", "│" },
	double_left_clc = { "╓", "─", "┐", "│", "┘", "─", "╙", "│" },
	double_right_clc = { "┌", "─", "╖", "│", "╜", "─", "└", "│" },
	double_vertical_clc = { "╓", "─", "╖", "│", "╜", "─", "╙", "│" },
	vintage_clc = { "+", "-", "+", "|", "+", "-", "+", "|" },
	solid = { " ", " ", " ", " ", " ", " ", " ", " " },
	none = { "", "", "", "", "", "", "", "" },
}

M.box = {
	single = {
		tl = "┌",
		tr = "┐",
		bl = "└",
		br = "┘",
		hr = "─",
		vt = "│",
	},
	double = {
		tl = "╔",
		tr = "╗",
		bl = "╚",
		br = "╝",
		hr = "═",
		vt = "║",
	},
	rounded = {
		tl = "╭",
		tr = "╮",
		bl = "╰",
		br = "╯",
		hr = "─",
		vt = "│",
	},
	bold = {
		tl = "┏",
		tr = "┓",
		bl = "┗",
		br = "┛",
		hr = "━",
		vt = "┃",
	},
	vintage = {
		tl = "+",
		tr = "+",
		bl = "+",
		br = "+",
		hr = "-",
		vt = "|",
	},
}

M.misc = {
	dots = "󰇘 ",
	plus = " ",
	circle = "   ",
	find = "   ",
	right_arrow1 = "   ",
	share = " ",
	scripd = " ",
	next = "󰼧 ",
	prev = "󰼨 ",
	neovim = " ",
	cubes = " ",
	test = " ",
	square = " ",
	neovim2 = " ",
}

M.dap = {
	Stopped = " ",
	Breakpoint = " ",
	BreakpointCondition = " ",
	BreakpointRejected = " ",
	LogPoint = " ",
}

M.diagnostics = {
	Error = " ",
	Warn = " ",
	Info = " ",
	Hint = " ",
}

M.git = {
	added = " ",
	modified = " ",
	removed = " ",
	renamed = " ",
	unstage = " ",
	stage = " ",
	untracked = " ",
	conflict = " ",
	ignored = " ",
}

M.kinds = {
	Obs = "Obs",
	ObsNew = "ObsNew",
	ObsTags = "ObsTags",
	RipGrep = " ",
	Namespace = "󰌗 ",
	Text = "󰉿 ",
	Method = "󰆧 ",
	Function = "󰆧 ",
	Constructor = " ",
	Field = "󰜢 ",
	Variable = "󰀫 ",
	Class = "󰠱 ",
	Interface = " ",
	Module = " ",
	Property = "󰜢 ",
	Unit = "󰑭 ",
	Value = "󰎠 ",
	Enum = " ",
	Keyword = "󰌋 ",
	Snippet = " ",
	Color = "󰏘 ",
	File = "󰈚 ",
	Reference = "󰈇 ",
	Folder = "󰉋 ",
	EnumMember = " ",
	Constant = "󰏿 ",
	Struct = "󰙅 ",
	Event = " ",
	Operator = "󰆕 ",
	TypeParameter = "󰊄 ",
	Table = " ",
	Object = "󰅩 ",
	Tag = " ",
	Array = "[]",
	Boolean = " ",
	Number = " ",
	Null = "󰟢 ",
	String = "󰉿 ",
	Calendar = " ",
	Watch = "󰥔 ",
	Package = " ",
	Copilot = " ",
	Codeium = " ",
	TabNine = " ",
}

M.logo = [[
██████╗  ███████╗ ███╗   ███╗  ██████╗  ██╗  ██╗     ██████╗  ███████╗ ██╗   ██╗
██╔══██╗ ██╔════╝ ████╗ ████║ ██╔═══██╗ ██║ ██╔╝     ██╔══██╗ ██╔════╝ ██║   ██║
██████╔╝ █████╗   ██╔████╔██║ ██║   ██║ █████╔╝      ██║  ██║ █████╗   ██║   ██║
██╔══██╗ ██╔══╝   ██║╚██╔╝██║ ██║   ██║ ██╔═██╗      ██║  ██║ ██╔══╝   ╚██╗ ██╔╝
██║  ██║ ███████╗ ██║ ╚═╝ ██║ ╚██████╔╝ ██║  ██╗     ██████╔╝ ███████╗  ╚████╔╝ 
╚═╝  ╚═╝ ╚══════╝ ╚═╝     ╚═╝  ╚═════╝  ╚═╝  ╚═╝     ╚═════╝  ╚══════╝   ╚═══╝  
]]

return M
