local M = {}

function M.setup()
	local harpoon = require("harpoon")
	require("harpoon.config").DEFAULT_LIST = "files"
	harpoon:setup({
		settings = {
			save_on_toggle = true,
			sync_on_ui_close = true,
			key = function()
				return vim.uv.cwd()
			end,
		},
		-- cmd = {
		-- 	display = function(list_item)
		-- 		if string.len(list_item.value) > 75 then
		-- 			return vim.fn.pathshorten(vim.fn.fnamemodify(list_item.value, ":~:."), 3)
		-- 		else
		-- 			return vim.fn.fnamemodify(list_item.value, ":~:.")
		-- 		end
		-- 	end,
		-- },
	})
end

function M.keys()
	local harpoon = require("harpoon")
	local function toggle(list)
		return function()
			harpoon.ui:toggle_quick_menu(harpoon:list(list), { title = "", ui_max_width = 80 })
		end
	end
	local function select(idx)
		return function()
			harpoon:list():select(idx)
		end
	end

	return {
		{
			"<A-a>",
			function()
				harpoon:list():add()
				vim.notify("Added to Harpoon", 2, { title = "Harpoon" })
			end,
			desc = "Add to Mark",
		},
		{
			"<Tab>",
			function()
				harpoon:list():next()
			end,
			desc = "Next Harpoon",
		},
		{
			"<S-Tab>",
			function()
				harpoon:list():prev()
			end,
			desc = "Prev Harpoon",
		},
		{ "<leader>1", select(1), desc = "Mark File 1" },
		{ "<leader>2", select(2), desc = "Mark File 2" },
		{ "<leader>3", select(3), desc = "Mark File 3" },
		{ "<leader>4", select(4), desc = "Mark File 4" },
		{ "<leader>5", select(5), desc = "Mark File 6" },
		{ "<leader>6", select(6), desc = "Mark File 6" },
		{ "<leader>7", select(7), desc = "Mark File 7" },
		{ "<leader>8", select(8), desc = "Mark File 8" },
		{ "<leader>9", select(9), desc = "Mark File 9" },
		{ "<A-space>", toggle("files"), desc = "Harpoon Files", mode = { "i", "n", "v" } },
		{ [[<A-\>]], toggle("terminals"), desc = "Harpoon Term List" },
	}
end

return M
