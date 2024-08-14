return {
	{
		"epwalsh/obsidian.nvim",
		ft = "markdown",
		opts = function()
			return {
				workspaces = { { name = "Notes", path = os.getenv("HOME") .. "/Notes", overrides = {} } },
				notes_subdir = nil,
				log_level = vim.log.levels.INFO,
				daily_notes = {
					folder = "01_FLEETING",
					date_format = "%Y-%m-%d",
					alias_format = "%B %-d, %Y",
					default_tags = { "daily-notes" },
					template = nil,
				},
				completion = { nvim_cmp = true, min_chars = 2 },
				mappings = {
					["gf"] = {
						action = function()
							return require("obsidian").util.gf_passthrough()
						end,
						opts = { noremap = false, expr = true, buffer = true },
					},
					["<leader>ch"] = {
						action = function()
							return require("obsidian").util.toggle_checkbox()
						end,
						opts = { buffer = true },
					},
					["<cr>"] = {
						action = function()
							return require("obsidian").util.smart_action()
						end,
						opts = { buffer = true, expr = true },
					},
				},
				new_notes_location = "current_dir",
				note_id_func = function(title)
					local suffix = ""
					if title ~= nil then
						suffix = title:gsub("%s+", " ")
					else
						for _ = 1, 4 do
							suffix = suffix .. string.char(math.random(65, 90))
						end
					end
					return tostring(os.date("%Y%m%d")) .. " " .. suffix
				end,
				note_path_func = function(spec)
					local path = spec.dir / tostring(spec.id)
					return path:with_suffix(".md")
				end,
				wiki_link_func = function(opts)
					return require("obsidian.util").wiki_link_id_prefix(opts)
				end,
				markdown_link_func = function(opts)
					return require("obsidian.util").markdown_link(opts)
				end,
				preferred_link_style = "wiki",
				---@return table
				note_frontmatter_func = function(note)
					if note.title then
						note:add_alias(note.title)
					end
					local out = { id = note.id, aliases = note.aliases, tags = note.tags }
					if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
						for k, v in pairs(note.metadata) do
							out[k] = v
						end
					end

					return out
				end,
				templates = {
					folder = "templates",
					date_format = "%Y-%m-%d",
					time_format = "%H:%M",
					substitutions = {},
				},
				---@param url string
				follow_url_func = function(url)
					vim.fn.jobstart({ "xdg-open", url }) -- linux
				end,

				-- Optional, set to true if you use the Obsidian Advanced URI plugin.
				-- https://github.com/Vinzent03/obsidian-advanced-uri
				use_advanced_uri = true,

				picker = {
					name = "fzf-lua",
					note_mappings = { new = "<C-x>", insert_link = "<C-l>" },
					tag_mappings = { tag_note = "<C-x>", insert_tag = "<C-l>" },
				},
				sort_by = "modified",
				sort_reversed = true,
				search_max_lines = 1000,
				open_notes_in = "current",
				ui = { enable = false },
				attachments = {
					img_folder = "assets/imgs", -- This is the default
					img_name_func = function()
						return string.format("%s-", os.time())
					end,
					img_text_func = function(client, path)
						path = client:vault_relative_path(path) or path
						return string.format("![%s](%s)", path.name, path)
					end,
				},
			}
		end,
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "ipynb", "markdown" },
		opts = function()
			return {
				enabled = true,
				max_file_size = 10.0,
				debounce = 100,
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

                        (block_quote) @quote

                        (pipe_table) @table
                ]],
				-- Capture groups that get pulled from quote nodes
				markdown_quote_query = [[
                         [
                             (block_quote_marker)
                             (block_continuation)
                         ] @quote_marker
                     ]],
				-- Capture groups that get pulled from inline markdown
				inline_query = [[
                        (code_span) @code

                        (shortcut_link) @shortcut

                        [(inline_link) (full_reference_link) (image)] @link
                    ]],
				log_level = "error",
				file_types = { "markdown" },
				render_modes = { "n", "c" },
				acknowledge_conflicts = false,
				anti_conceal = {
					enabled = true,
				},
				heading = {
					enabled = true,
					sign = true,
					position = "overlay",
					icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
					signs = { "󰫎 " },
					width = "full",
					backgrounds = {
						"RenderMarkdownH1Bg",
						"RenderMarkdownH2Bg",
						"RenderMarkdownH3Bg",
						"RenderMarkdownH4Bg",
						"RenderMarkdownH5Bg",
						"RenderMarkdownH6Bg",
					},
					-- The 'level' is used to index into the array using a clamp
					-- Highlight for the heading and sign icons
					foregrounds = {
						"RenderMarkdownH1",
						"RenderMarkdownH2",
						"RenderMarkdownH3",
						"RenderMarkdownH4",
						"RenderMarkdownH5",
						"RenderMarkdownH6",
					},
				},
				bullet = {
					enabled = true,
					icons = { "●", "○", "◆", "◇" },
					right_pad = 1,
					highlight = "RenderMarkdownBullet",
				},
				pipe_table = {
					enabled = true,
					style = "full",
					cell = "padded",
					alignment_indicator = "━",
					border = { "┌", "┬", "┐", "├", "┼", "┤", "└", "┴", "┘", "│", "─" },
					head = "RenderMarkdownTableHead",
					row = "RenderMarkdownTableRow",
					filler = "RenderMarkdownTableFill",
				},
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
	},
	{
		"ray-x/go.nvim",
		branch = "master",
		ft = { "go", "gomod", "gosum", "gotmpl", "gohtmltmpl", "gotexttmpl" },
		dependencies = { "ray-x/guihua.lua", branch = "master", build = "cd lua/fzy && make" },
		opts = function()
			return {
				disable_defaults = false,
				go = "go",
				goimports = "goimports",
				gofmt = false,
				fillstruct = "fillstruct",
				tag_options = "",
				icons = { breakpoint = "🧘", currentpos = "🏃" },
				verbose = false,
				lsp_cfg = true,
				lsp_gofumpt = false,
				lsp_keymaps = false,
				lsp_codelens = true,
				diagnostic = require("utils.lsp").diagnostics_config,
				go_input = vim.ui.input,
				go_select = vim.ui.select,
				lsp_document_formatting = false,
				lsp_inlay_hints = { enable = false },
				textobjects = false,
				trouble = true,
				luasnip = true,
			}
		end,
	},
}
