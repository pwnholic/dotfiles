local treesj = require("treesj")

local gww = { both = {
	fallback = function()
		vim.cmd("normal! gww")
	end,
} }

local curleyLessIfStatementJoin = {
	-- remove curly brackets in js when joining if statements https://github.com/Wansmer/treesj/issues/150
	statement_block = {
		join = {
			format_tree = function(tsj)
				if tsj:tsnode():parent():type() == "if_statement" then
					tsj:remove_child({ "{", "}" })
				else
					require("treesj.langs.javascript").statement_block.join.format_tree(tsj)
				end
			end,
		},
	},
	-- one-line-if-statement can be split into multi-line https://github.com/Wansmer/treesj/issues/150
	expression_statement = {
		join = { enable = false },
		split = {
			enable = function(tsn)
				return tsn:parent():type() == "if_statement"
			end,
			format_tree = function(tsj)
				tsj:wrap({ left = "{", right = "}" })
			end,
		},
	},
}

---@param preset table?
---@return nil
function _G.treesj_split_recursive(_, preset)
	require("treesj.format")._format(
		"split",
		vim.tbl_deep_extend("force", preset or {}, { split = { recursive = true } })
	)
end

---@param preset table?
---@return nil
function _G.treesj_toggle_recursive(_, preset)
	require("treesj.format")._format(
		nil,
		vim.tbl_deep_extend("force", preset or {}, {
			split = { recursive = true },
			join = { recursive = true },
		})
	)
end

vim.keymap.set("n", "<leader>kj", treesj.join, { desc = "Join Block" })
vim.keymap.set("n", "<leader>kr", function()
	vim.opt.operatorfunc = "v:lua.treesj_split_recursive"
	vim.api.nvim_feedkeys("g@l", "nx", true)
end, { desc = "Split Recursive" })
vim.keymap.set("n", "<leader>ks", treesj.split, { desc = "Just Split" })

treesj.setup({
	use_default_keymaps = false,
	max_join_length = 1024,
	cursor_behavior = "start",
	langs = {
		python = { string_content = gww }, -- python docstrings
		rst = { paragraph = gww }, -- python docstrings (when rsg is injected)
		comment = { source = gww, element = gww }, -- comments in any language
		jsdoc = { source = gww, description = gww },
		javascript = curleyLessIfStatementJoin,
		typescript = curleyLessIfStatementJoin,
	},
})
