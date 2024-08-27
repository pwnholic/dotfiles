return {
	"folke/which-key.nvim",
	event = "BufRead",
	opts = function()
		return {
			preset = "helix",
			spec = {
				{ "<leader>g", desc = "LSP" },
				{ "<leader>b", desc = "Buffer" },
				{ "<leader>f", desc = "Find" },
				{ "<leader>s", desc = "Search" },
				{ "<leader>d", desc = "Debug" },
				{ "<leader>h", desc = "Git" },
				{ "<leader>t", desc = "Test" },
				{ "<leader>u", desc = "Toggle" },
				{ "<leader>w", desc = "Window" },
				{ "<leader>x", desc = "Diagnostics" },
				{ "<leader>df", desc = "Find Debug" },
			},
			icons = {
				breadcrumb = "",
				separator = "",
				group = "",
				ellipsis = "...",
				mappings = true,
				rules = false,
				colors = true,
			},
		}
	end,
}
