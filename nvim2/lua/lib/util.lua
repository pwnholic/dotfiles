--- Generic, dependency-free helpers.
---
--- This module stays intentionally small: anything Neovim already provides
--- (`vim.tbl_deep_extend`, `vim.split`, `vim.deepcopy`, ...) is used directly
--- instead of being wrapped again.
---
--- @class lib.util
local M = {}

--- Normalize `nil | T | T[]` into a list.
--- @generic T
--- @param v T|T[]|nil
--- @return T[]
function M.to_list(v)
    if v == nil then
        return {}
    end
    if type(v) == "table" and vim.islist(v) then
        return v
    end
    return { v }
end

--- Strip leading/trailing whitespace.
--- @param s string
--- @return string
function M.trim(s)
    return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

return M
