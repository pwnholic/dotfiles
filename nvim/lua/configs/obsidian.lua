local function vault(name)
	return vim.fn.fnamemodify(string.format("%s/Notes/%s", vim.fn.expand("~"), name), ":~:.") --- @type string
end

local new_noteid ---@type string
local function generate_new_id()
	math.randomseed(os.time())
	local len = 7
	local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local name = ""
	for _ = 1, len do
		local ridx = math.random(1, #chars)
		name = string.format("%s%s", name, string.sub(chars, ridx, ridx))
	end
	if string.len(name) > len then
		string.lower(name:gsub(" ", "_"))
	end
	new_noteid = string.format("%s_%s%s", os.date("%d%m%Y"), os.date("%S"), name)
	return new_noteid
end

require("obsidian").setup({
	workspaces = {
		{
			name = "planning",
			path = vault("private/planning"),
			overrides = {
				notes_subdir = vim.NIL,
				new_notes_location = "current_dir",
				templates = { subdir = vim.NIL },
			},
		},
		{
			name = "workspace",
			path = vault("private/workspace"),
			overrides = {
				notes_subdir = vim.NIL,
				new_notes_location = "current_dir",
				templates = { subdir = vim.NIL },
			},
		},
	},
	preferred_link_style = "markdown",
	picker = { name = "fzf-lua", mappings = { new = "<C-x>", insert_link = "<C-l>" } },
	daily_notes = {
		folder = vault("private/dailies"),
		date_format = os.date("%d%m%Y"),
		alias_format = "%B %-d, %Y",
		template = "dailies.md",
	},
	completion = { nvim_cmp = true, min_chars = 3 },
	new_notes_location = "current_dir",
	use_advanced_uri = true,
	mappings = {
		["gf"] = {
			action = function()
				return require("obsidian").util.gf_passthrough()
			end,
			opts = { noremap = false, expr = true, buffer = true, desc = "Go Note File" },
		},
		["<leader>nh"] = {
			action = function()
				return require("obsidian").util.toggle_checkbox()
			end,
			opts = { buffer = true, desc = "Toggle Check Box" },
		},
		["<cr>"] = {
			action = function()
				return require("obsidian").util.smart_action()
			end,
			opts = { buffer = true, expr = true, desc = "Smart action depending on context" },
		},
	},
	note_id_func = function()
		return generate_new_id
	end,
	note_frontmatter_func = function(note)
		if note.title then
			note:add_alias(note.title)
		end
		-- TODO: do some experiment with this...
		local out = { id = note.id, aliases = note.aliases, tags = note.tags }
		if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
			for k, v in pairs(note.metadata) do
				out[k] = v
			end
		end
		return out
	end,
	ui = {
		enable = true, -- set to false to disable all additional syntax features
		update_debounce = 150, -- update delay after a text change (in milliseconds)
		checkboxes = {
			[" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
			["x"] = { char = "", hl_group = "ObsidianDone" },
			[">"] = { char = "", hl_group = "ObsidianRightArrow" },
			["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
			-- You can also add more custom ones...
		},
	},
	attachments = {
		img_folder = "assets/images", -- This is the default
		-- TODO: do experiment with this also
		img_text_func = function(client, path)
			path = client:vault_relative_path(path) or path
			return string.format("![%s](%s)", path.name, path)
		end,
	},
	templates = {
		subdir = vault("templates"),
		date_format = "%Y-%m-%d",
		time_format = "%H:%M",
		substitutions = {},
	},
})