return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	keys = function()
		return {
                -- stylua: ignore start
			 { "<leader><leader>", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list(), { ui_width_ratio = 0.45, border = "single", title = "" }) end, desc = "Harpoon List", },
			 { "<leader>l", function() require("harpoon").ui:toggle_quick_menu( require("harpoon"):list(), { ui_width_ratio = 0.40, border = "single", title = "" }) end, desc = "Harpoon List", },
			 { "<leader>a", function() vim.notify("Add to Mark", 2) require("harpoon"):list():add() end, desc = "Add to Mark", },
			 { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Mark 1" },
			 { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Mark 2" },
			 { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Mark 3" },
			 { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Mark 4" },
			 { "<leader>5", function() require("harpoon"):list():select(5) end, desc = "Mark 5" },
			 { "<leader>6", function() require("harpoon"):list():select(5) end, desc = "Mark 6" },
			 { "<leader>7", function() require("harpoon"):list():select(5) end, desc = "Mark 7" },
			 { "<leader>8", function() require("harpoon"):list():select(5) end, desc = "Mark 8" },
			 { "<leader>9", function() require("harpoon"):list():select(5) end, desc = "Mark 9" },
			-- stylua: ignore end
			{
				"<A-space>",
				function()
					local fzf = require("fzf-lua")
					local hp = require("harpoon")
					fzf.fzf_exec(function(cb)
						for _, item in ipairs(hp:list().items) do
							cb(item.value)
						end
						cb()
					end, {
						prompt = "Harpoon : ",
						cwd_header = false,
						actions = {
							["enter"] = fzf.actions.file_edit,
							["ctrl-s"] = fzf.actions.file_split,
							["ctrl-v"] = fzf.actions.file_vsplit,
							["ctrl-x"] = function(s)
								for i, v in ipairs(s) do
									table.remove(hp:list().items, i)
									vim.notify(string.format("Remove %s from mark", v), 2, { title = "Harpoon" })
								end
							end,
							["alt-n"] = {
								function(s)
									local items = hp:list().items
									for i, _ in ipairs(s) do
										if i < 1 or i >= #items then
											return vim.notify("index out of bounds", 1)
										end
										local temp = items[#items]
										for k = #items, i + 1, -1 do
											items[k] = items[k - 1]
										end
										items[i] = temp
									end
								end,
								fzf.actions.resume,
							},
							["alt-p"] = {
								function(s)
									local items = hp:list().items
									for i, _ in ipairs(s) do
										if i < 1 or i >= #items then
											return vim.notify("index out of bounds", 1)
										end
										local temp = items[i]
										for k = i, #items - 1 do
											items[k] = items[k + 1]
										end
										items[#items] = temp
									end
								end,
								fzf.actions.resume,
							},
						},
					})
				end,
			},
		}
	end,
	config = function()
		local harpoon = require("harpoon")
		harpoon:setup({
			settings = {
				save_on_toggle = true,
				key = function()
					return vim.uv.cwd() --[[@as string]]
				end,
			},
		})
		harpoon:extend({
			UI_CREATE = function(ctx)
				vim.keymap.set("n", "<C-v>", function()
					harpoon.ui:select_menu_item({ vsplit = true })
				end, { buffer = ctx.bufnr })
				vim.keymap.set("n", "<C-s>", function()
					harpoon.ui:select_menu_item({ split = true })
				end, { buffer = ctx.bufnr })
				vim.keymap.set("n", "<C-t>", function()
					harpoon.ui:select_menu_item({ tabedit = true })
				end, { buffer = ctx.bufnr })
			end,
		})
	end,
}
