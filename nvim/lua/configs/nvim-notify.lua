local notify = require("notify")

local stages_util = require("notify.stages.util")
local direction = stages_util.DIRECTION

local function animation(post_dir)
	return {
		function(state)
			local next_row = stages_util.available_slot(state.open_windows, state.message.height, post_dir)
			if not next_row then
				return nil
			end
			return {
				relative = "editor",
				anchor = "NE",
				width = 1,
				height = state.message.height,
				col = vim.opt.columns:get(),
				row = next_row,
				border = "rounded",
				style = "minimal",
				focusable = false,
			}
		end,
		function(state, win)
			return {
				width = { state.message.width },
				col = { vim.opt.columns:get() },
				row = {
					stages_util.slot_after_previous(win, state.open_windows, post_dir),
					frequency = 2.5,
					complete = function()
						return true
					end,
				},
			}
		end,
		function(state, win)
			return {
				col = { vim.opt.columns:get() },
				time = true,
				row = {
					stages_util.slot_after_previous(win, state.open_windows, post_dir),
					frequency = 2.5,
					complete = function()
						return true
					end,
				},
			}
		end,
		function(state, win)
			return {
				border = "FloatBorder",
				width = {
					1,
					frequency = 2,
					damping = 0.9,
					complete = function(cur_width)
						return cur_width < 3
					end,
				},
				col = { vim.opt.columns:get() },
				row = {
					stages_util.slot_after_previous(win, state.open_windows, post_dir),
					frequency = 2.5,
					complete = function()
						return true
					end,
				},
			}
		end,
	}
end

notify.setup({
	fps = 60,
	timeout = 4000, -- 4 sec
	stages = animation(direction.TOP_DOWN),
	render = "wrapped-compact",
	max_width = 60,
})
