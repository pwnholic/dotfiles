vim.opt_local.spell = false
vim.opt_local.commentstring = "// %s"
vim.opt_local.path = { "/usr/include/**", "/usr/local/include/**" }

local ok, cmp = pcall(require, "cmp")
if ok then
	cmp.setup.filetype("c", {
		comparators = {
			priority_weight = 100,
			comparators = {
				cmp.config.compare.offset,
				cmp.config.compare.exact,
				function(lhs, rhs)
					local diff
					if lhs.completion_item.score and rhs.completion_item.score then
						diff = (rhs.completion_item.score * rhs.score) - (lhs.completion_item.score * lhs.score)
					else
						diff = rhs.score - lhs.score
					end
					return (diff < 0)
				end,
				function(lhs, rhs)
					lhs:get_kind()
					local _, lhs_under = lhs.completion_item.label:find("^_+")
					local _, rhs_under = rhs.completion_item.label:find("^_+")
					lhs_under = lhs_under or 0
					rhs_under = rhs_under or 0
					return lhs_under < rhs_under
				end,
				cmp.config.compare.kind,
				cmp.config.compare.locality,
				cmp.config.compare.recently_used,
				cmp.config.compare.sort_text,
				cmp.config.compare.order,
			},
		},
	})
end
