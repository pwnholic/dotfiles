return {
    "Bekaboo/deadcolumn.nvim",
    event = "BufRead",
    opts = {
        scope = "visible", ---@type string|fun(): integer
        ---@type string[]|boolean|fun(mode: string): boolean
        modes = function(mode)
            return mode:find("^[iRss\x13]") ~= nil
        end,
    },
}
