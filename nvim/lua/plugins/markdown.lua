return {
	{
		"epwalsh/obsidian.nvim",
		ft = "markdown",
		keys = function()
			local function map(cmd, prompt)
				return function()
					if prompt == nil then
						return vim.cmd[cmd]()
					else
						vim.ui.input({ prompt = prompt .. " : " }, function(input)
							input = input:gsub("%s+", " ")
							if input == "" then
								return vim.cmd[cmd]()
							else
								return vim.cmd[cmd](input)
							end
						end)
					end
				end
			end

			return {
				{ "<leader>nn", map("ObsidianNew", "[opts] Title"), desc = "New Note", ft = "markdown" },
				{
					"<leader>nf",
					map("ObsidianFollowLink", "[vsplit|split] Link Under Cursor"),
					desc = "Follow Link",
					ft = "markdown",
				},
				{ "<leader>nx", map("ObsidianExtractNote", "Title"), desc = "Extract Note", ft = "markdown" },
				{ "<leader>np", map("ObsidianPasteImg", "Image Name"), desc = "Paste Image", ft = "markdown" },
				{ "<leader>nr", map("ObsidianRename", "New Name"), desc = "Rename Note", ft = "markdown" },
				{ "<leader>nm", vim.cmd.ObsidianTemplate, desc = "Template", ft = "markdown" },
				{ "<leader>nw", vim.cmd.ObsidianWorkspace, desc = "Workspace", ft = "markdown" },
				{ "<leader>nT", vim.cmd.ObsidianTags, desc = "Tags", ft = "markdown" },
				{ "<leader>ns", vim.cmd.ObsidianQuickSwitch, desc = "Quick Swicth", ft = "markdown" },
				{ "<leader>nL", vim.cmd.ObsidianLinks, desc = "Collect Link", ft = "markdown" },
				{ "<leader>ny", vim.cmd.ObsidianYesterday, desc = "Yesterday Note", ft = "markdown" },
				{ "<leader>nw", vim.cmd.ObsidianTomorrow, desc = "Tomorrow Note", ft = "markdown" },
				{ "<leader>no", vim.cmd.ObsidianOpen, desc = "Open App", ft = "markdown" },
				{ "<leader>nd", vim.cmd.ObsidianDailies, desc = "Dailies Note", ft = "markdown" },
				{ "<leader>ns", vim.cmd.ObsidianSearch, desc = "Search Note", ft = "markdown" },
				{ "<leader>nl", vim.cmd.ObsidianLink, desc = "Link", ft = "markdown" },
				{ "<leader>nt", vim.cmd.ObsidianToday, desc = "Today Note", ft = "markdown" },
				{ "<leader>nb", vim.cmd.ObsidianBacklinks, desc = "Back Link", ft = "markdown" },
				{ "<leader>nN", vim.cmd.ObsidianLinkNew, desc = "Create New Link", ft = "markdown" },
			}
		end,
		opts = function()
			local obsidian = require("obsidian")
			return {
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
			}
		end,
	},
	{
		"MeanderingProgrammer/markdown.nvim",
		ft = "markdown",
		opts = {
			start_enabled = true,
			latex_enabled = true,
			max_file_size = 1.5,
			markdown_query = [[
            (atx_heading [
                (atx_h1_marker)
                (atx_h2_marker)
                (atx_h3_marker)
                (atx_h4_marker)
                (atx_h5_marker)
                (atx_h6_marker)
            ] @heading)
    
            (thematic_break) @dash
    
            (fenced_code_block) @code
    
            [
                (list_marker_plus)
                (list_marker_minus)
                (list_marker_star)
            ] @list_marker
    
            (task_list_marker_unchecked) @checkbox_unchecked
            (task_list_marker_checked) @checkbox_checked
    
            (block_quote (block_quote_marker) @quote_marker)
            (block_quote (paragraph (inline (block_continuation) @quote_marker)))
    
            (pipe_table) @table
            (pipe_table_header) @table_head
            (pipe_table_delimiter_row) @table_delim
            (pipe_table_row) @table_row
        ]],
			inline_query = [[
            (code_span) @code
    
            (shortcut_link) @callout
        ]],
			latex_converter = "latex2text",
			log_level = "error",
			file_types = { "markdown" },
			render_modes = { "n", "c" },
			headings = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
			dash = "—",
			bullets = { "●", "○", "◆", "◇" },
			checkbox = {
				unchecked = "󰄱 ",
				checked = "󰱒 ",
			},
			quote = "┃",
			callout = {
				note = "󰋽  Note",
				tip = "󰌶  Tip",
				important = "󰅾  Important",
				warning = "󰀪  Warning",
				caution = "󰳦  Caution",
			},
			win_options = {
				conceallevel = {
					default = vim.api.nvim_get_option_value("conceallevel", {}),
					rendered = 3,
				},
				-- See :h 'concealcursor'
				concealcursor = {
					default = vim.api.nvim_get_option_value("concealcursor", {}),
					rendered = "nvic",
				},
			},
			table_style = "full",
			highlights = {
				heading = {
					backgrounds = { "DiffAdd", "DiffChange", "DiffDelete" },
					foregrounds = {
						"markdownH1",
						"markdownH2",
						"markdownH3",
						"markdownH4",
						"markdownH5",
						"markdownH6",
					},
				},
				dash = "LineNr",
				code = "ColorColumn",
				bullet = "Normal",
				checkbox = {
					unchecked = "@markup.list.unchecked",
					checked = "@markup.heading",
				},
				table = {
					head = "@markup.heading",
					row = "Normal",
				},
				latex = "@markup.math",
				quote = "@markup.quote",
				callout = {
					note = "DiagnosticInfo",
					tip = "DiagnosticOk",
					important = "DiagnosticHint",
					warning = "DiagnosticWarn",
					caution = "DiagnosticError",
				},
			},
		},
	},
}
