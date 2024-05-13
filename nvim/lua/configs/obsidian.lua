---@diagnostic disable: undefined-doc-name, unused-local, inject-field
local ok, obsidian = pcall(require, "obsidian")
if not ok then
	return
end

obsidian.setup({
	preferred_link_style = "markdown",
	picker = { name = "fzf-lua", mappings = { new = "<C-x>", insert_link = "<C-l>" } },
	completion = { nvim_cmp = true, min_chars = 3 },
	use_advanced_uri = true,
	wiki_link_func = "prepend_note_path",
	workspaces = { { name = "notes", path = vim.fn.expand("~") .. "/Notes" } },
	daily_notes = { folder = "01_FLEETING", date_format = os.date("%Y%m%d"), alias_format = "%B %-d, %Y" },
	templates = {
		subdir = "Templates",
		date_format = "%Y-%m-%d",
		time_format = "%H:%M",
		substitutions = {},
	},
	mappings = {
		["gf"] = {
			action = function()
				return obsidian.util.gf_passthrough()
			end,
			opts = { noremap = false, expr = true, buffer = true, desc = "Go Note File" },
		},
		["<leader>nh"] = {
			action = function()
				return obsidian.util.toggle_checkbox()
			end,
			opts = { buffer = true, desc = "Toggle Check Box" },
		},
		["<cr>"] = {
			action = function()
				return obsidian.util.smart_action()
			end,
			opts = { buffer = true, expr = true, desc = "Smart action depending on context" },
		},
	},
	note_id_func = function(title)
		if title ~= nil then
			return title:gsub("%s+", "_"):gsub("^%l", string.upper):gsub("_%l", string.upper)
		else
			return string.format("%s_%s", os.date("%Y%m%d"), os.date("%H%M%S"))
		end
	end,
	note_frontmatter_func = function(note)
		local fs_stat = vim.uv.fs_stat(vim.fs.normalize(vim.api.nvim_buf_get_name(0)))

		if note.title then
			note:add_alias(note.title)
		end

		local out = {
			id = note.id,
			aliases = note.aliases,
			tags = note.tags,
			created = tostring(os.date("%Y-%m-%d %H:%M", fs_stat.birthtime.sec)) or "",
			modified = tostring(os.date("%Y-%m-%d %H:%M", fs_stat.mtime.sec)) or "",
		}

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
	callbacks = {

		-- Runs anytime you enter the buffer for a note.
		---@param client obsidian.Client
		---@param note obsidian.Note
		enter_note = function(client, note)
			if note.path.stem == "nav" then
				vim.bo[note.bufnr].wrap = false
			end
		end,

		-- Runs anytime you leave the buffer for a note.
		---@param client obsidian.Client
		---@param note obsidian.Note
		leave_note = function(client, note)
			vim.api.nvim_buf_call(note.bufnr or 0, function()
				vim.cmd("silent w")
			end)
		end,

		-- -- Runs anytime the workspace is set/changed.
		-- ---@param client obsidian.Client
		-- ---@param workspace obsidian.Workspace
		-- post_set_workspace = function(client, workspace)
		-- 	local wpath = tostring(workspace.path)
		-- 	local lcd = pcall(vim.cmd.lcd, wpath)
		-- 	if not lcd then
		-- 		vim.notify("[obsidian.nvim] failed to cd to " .. wpath, vim.log.levels.WARN)
		-- 	end
		-- end,

		-- -- Runs right before writing the buffer for a note.
		-- ---@param client obsidian.Client
		-- ---@param note obsidian.Note
		-- pre_write_note = function(client, note) end,

		-- -- Runs at the end of `obsidian.setup()`.
		-- ---@param client obsidian.Client
		-- post_setup = function(client) end,
	},
})
