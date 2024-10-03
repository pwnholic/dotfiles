local M = {}

return setmetatable(M, {
    __index = function(_, key)
        return require("utils." .. key)
    end,
})
