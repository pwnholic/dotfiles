local map = vim.keymap.set
local function rustlsp(args)
	return function()
		vim.cmd.RustLsp(args)
	end
end

map("n", "<leader>ju", rustlsp("moveItem up"), { desc = "Move Item Up" })
map("n", "<leader>jd", rustlsp("moveItem down"), { desc = "Move Item Down" })
map("n", "<leader>jm", rustlsp("expandMacro"), { desc = "Expand Macros Recursively" })
map("n", "<leader>jp", rustlsp("rebuildProcMacros"), { desc = "Rebuild proc macros" })
map("n", "<leader>jx", rustlsp("explainError"), { desc = "Explain errors" })
map("n", "<leader>jc", rustlsp("openCargo"), { desc = "Open Cargo.toml" })
map("n", "<leader>ja", rustlsp("parentModule"), { desc = "Parent Module" })
map("n", "<leader>jl", rustlsp("joinLines"), { desc = "Join Lines" })
map("n", "<leader>js", rustlsp("syntaxTree"), { desc = "Syntax Tree" })
