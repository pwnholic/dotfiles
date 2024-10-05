local M = {}

---@class fallbak_tbl_t each key shares a default / fallback pattern table
---that can be used for pattern matching if corresponding key is not present
---or non patterns stored in the key are matched
---@field __content table closing patterns for each filetype
---@field __default table
local fallback_tbl_t = {}

function fallback_tbl_t:__index(k)
    return fallback_tbl_t[k] or self:fallback(k)
end

function fallback_tbl_t:__newindex(k, v)
    self.__content[k] = v
end

---Get the table with the fallback patterns for kdest
---@param k string key
---@return table concatenated table
function fallback_tbl_t:fallback(k)
    local dest = self.__content[k]
    local default = self.__default
    if dest and default then
        if vim.islist(dest) and vim.islist(default) then
            return vim.list_extend(dest, default)
        else
            dest = vim.tbl_deep_extend("keep", dest, default)
            return dest
        end
    elseif dest then
        return dest
    elseif default then
        return default
    end
    return {}
end

---Create a new shared table
---@param args table
---@return fallbak_tbl_t
function fallback_tbl_t:new(args)
    args = args or {}
    local fallback_tbl = { __content = args.content or {}, __default = args.default or {} }
    return setmetatable(fallback_tbl, self)
end

local patterns = fallback_tbl_t:new({
    default = {
        "\\%)",
        "\\%)",
        "\\%]",
        "\\}",
        "%)",
        "%]",
        "}",
        '"',
        "'",
        "`",
        ",",
        ";",
        "%.",
    },
    content = {
        c = { "%*/" },
        cpp = { "%*/" },
        lua = { "%]=*%]" },
        python = { '"""', "'''" },
        html = { "<[^>]*>" },
        xml = { "<[^>]*>" },
        markdown = {
            "\\right\\rfloor",
            "\\right\\rceil",
            "\\right\\vert",
            "\\right\\Vert",
            "\\right%)",
            "\\right%]",
            "\\right}",
            "\\right>",
            "\\%]",
            "\\}",
            "-->",
            "<[^>]*>",
            "%*%*%*",
            "%*%*",
            "%*",
            "%$",
            "|",
        },
        tex = {
            "\\right\\rfloor",
            "\\right\\rceil",
            "\\right\\vert",
            "\\right\\Vert",
            "\\right%)",
            "\\right%]",
            "\\right}",
            "\\right>",
            "\\%]",
            "\\}",
            "%$",
        },
    },
})

local opening_pattern_lookup_tbl = {
    ["'"] = "'",
    ['"'] = '"',
    [","] = ".",
    [";"] = ".",
    ["`"] = "`",
    ["|"] = "|",
    ["}"] = "{",
    ["%."] = ".",
    ["%$"] = "%$",
    ["%)"] = "%(",
    ["%]"] = "%[",
    ["%*"] = "%*",
    ["<<<"] = ">>>",
    ["%*%*"] = "%*%*",
    ["%*%*%*"] = "%*%*%*",
    ['"""'] = '"""',
    ["'''"] = "'''",
    ["%*/"] = "/%*",
    ["\\}"] = "\\{",
    ["-->"] = "<!--",
    ["\\%)"] = "\\%(",
    ["\\%]"] = "\\%[",
    ["%]=*%]"] = "--%[=*%[",
    ["<[^>]*>"] = "<[^>]*>",
    ["\\right}"] = "\\left{",
    ["\\right>"] = "\\left<",
    ["\\right%)"] = "\\left%(",
    ["\\right%]"] = "\\left%[",
    ["\\right\\vert"] = "\\left\\vert",
    ["\\right\\Vert"] = "\\left\\lVert",
    ["\\right\\rceil"] = "\\left\\lceil",
    ["\\right\\rfloor"] = "\\left\\lfloor",
}

---Get the index where Shift-Tab should jump to
---1. If there is only whitespace characters or no character in between
---   the opening and closing pattern, jump to the end of the whitespace
---   characters (i.e. right before the closing pattern)
---
---       1.1. Special case: if there is exactly two whitespace characters,
---            jump to the middle of the two whitespace characters
---
---2. If there is contents (non-whitespace characters) in between the
---   opening and closing pattern, jump to the end of the contents

---@param leading any leading texts on current line
---@param closing_pattern any closing pattern
---@param cursor number[] cursor position
---@return number[] cursor position after jump
local function jumpin_idx(leading, closing_pattern, cursor)
    local success, result = pcall(function()
        local opening_pattern = opening_pattern_lookup_tbl[closing_pattern]

        local _, _, content_str, closing_pattern_str = leading:find(string.format("%s(%s)(%s)$", opening_pattern, "%s*", closing_pattern))
        if content_str == nil or closing_pattern_str == nil then
            _, _, content_str, closing_pattern_str = leading:find(string.format("^(%s)(%s)$", "%s*", closing_pattern))
        end

        if content_str and closing_pattern_str then
            if #content_str == 2 then
                return { cursor[1], cursor[2] - #closing_pattern_str - 1 }
            else
                return { cursor[1], cursor[2] - #closing_pattern_str }
            end
        end

        _, _, _, closing_pattern_str = leading:find(string.format("%s%s(%s)$", opening_pattern .. "%s*", ".*%S", "%s*" .. closing_pattern .. "%s*"))
        if closing_pattern_str == nil then
            _, _, closing_pattern_str = leading:find(string.format("%s(%s)$", "%S", "%s*" .. closing_pattern .. "%s*"))
        end

        if closing_pattern_str == nil then
            vim.notify("Warning: No closing pattern found.", vim.log.levels.WARN)
            return cursor
        end

        return { cursor[1], cursor[2] - #closing_pattern_str }
    end)

    if not success then
        vim.notify("Error in jumpin_idx: " .. result, vim.log.levels.ERROR)
        return cursor -- Return the original cursor position in case of error
    end
    return result
end

---Check if the cursor is in cmdline
---@return boolean
local function in_cmdline()
    return vim.fn.mode():match("^c") ~= nil
end

---Get the cursor position, whether in cmdline or normal buffer
---@return number[] cursor: 1,0-indexed cursor position
local function get_cursor()
    return in_cmdline() and { 1, vim.fn.getcmdpos() - 1 } or vim.api.nvim_win_get_cursor(0)
end

---Get current line, whether in cmdline or normal buffer
---@return string current_line: current line
local function get_line()
    return in_cmdline() and vim.fn.getcmdline() or vim.api.nvim_get_current_line()
end

---Getting the jump position for Tab
---@return number[]? cursor position after jump; nil if no jump
local function get_tabout_pos()
    local cursor = get_cursor()
    local current_line = get_line()
    local trailing = current_line:sub(cursor[2] + 1, -1)
    local leading = current_line:sub(1, cursor[2])

    -- Do not jump if the cursor is at the beginning/end of the current line
    if leading:match("^%s*$") or trailing == "" then
        return
    end

    for _, pattern in ipairs(patterns[vim.bo.ft or ""]) do
        local _, jump_pos = trailing:find("^%s*" .. pattern)
        if jump_pos then
            return { cursor[1], cursor[2] + jump_pos }
        end
    end
end

---Getting the jump position for Shift-Tab
---@return number[]? cursor position after jump; nil if no jump
local function get_tabin_pos()
    local cursor = get_cursor()
    local current_line = get_line()
    local leading = current_line:sub(1, cursor[2])

    for _, pattern in ipairs(patterns[vim.bo.ft or ""]) do
        local _, closing_pattern_end = leading:find(pattern .. "%s*$")
        if closing_pattern_end then
            return jumpin_idx(leading:sub(1, closing_pattern_end), pattern, cursor)
        end
    end
end

---@param direction 1|-1 1 for tabout, -1 for tabin
---@return number[]? cursor position after jump; nil if no jump
function M.get_jump_pos(direction)
    if direction == 1 then
        return get_tabout_pos()
    else
        return get_tabin_pos()
    end
end

local RIGHT = vim.api.nvim_replace_termcodes("<Right>", true, true, true)
local LEFT = vim.api.nvim_replace_termcodes("<Left>", true, true, true)

---Set the cursor position, whether in cmdline or normal buffer
---@param pos number[] cursor position
---@return nil
local function set_cursor(pos)
    if in_cmdline() then
        local cursor = get_cursor()
        local diff = pos[2] - cursor[2]
        local termcode = string.rep(diff > 0 and RIGHT or LEFT, math.abs(diff))
        vim.api.nvim_feedkeys(termcode, "nt", true)
    else
        vim.api.nvim_win_set_cursor(0, pos)
    end
end

local TAB = vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
local S_TAB = vim.api.nvim_replace_termcodes("<S-Tab>", true, true, true)

---Get the position to jump for Tab or Shift-Tab, perform the jump if
---there is a position to jump to, otherwise fallback (feedkeys)
---@param direction 1|-1 1 for tabout, -1 for tabin
function M.jump(direction)
    local pos = M.get_jump_pos(direction)
    if pos then
        set_cursor(pos)
        return
    end
    vim.api.nvim_feedkeys(direction == 1 and TAB or S_TAB, "nt", false)
end

------
--- COMPLETION TAB KEY
------

---Choose the closer destination between two destinations
---@param dest1 number[]?
---@param dest2 number[]?
---@return number[]|nil
local function choose_closer(dest1, dest2)
    if not dest1 then
        return dest2
    end
    if not dest2 then
        return dest1
    end

    local current_pos = vim.api.nvim_win_get_cursor(0)
    local line_width = vim.api.nvim_win_get_width(0)
    local dist1 = math.abs(dest1[2] - current_pos[2]) + math.abs(dest1[1] - current_pos[1]) * line_width
    local dist2 = math.abs(dest2[2] - current_pos[2]) + math.abs(dest2[1] - current_pos[1]) * line_width
    if dist1 <= dist2 then
        return dest1
    else
        return dest2
    end
end

---Check if a node has length larger than 0
---@param node table
---@return boolean
function M.node_has_length(node)
    local start_pos, end_pos = node:get_buf_position()
    return start_pos[1] ~= end_pos[1] or start_pos[2] ~= end_pos[2]
end

---Check if range1 contains range2
---If range1 == range2, return true
---@param range1 integer[][] 0-based range
---@param range2 integer[][] 0-based range
---@return boolean
function M.range_contains(range1, range2)
    return (range2[1][1] > range1[1][1] or (range2[1][1] == range1[1][1] and range2[1][2] >= range1[1][2]))
        and (range2[1][1] < range1[2][1] or (range2[1][1] == range1[2][1] and range2[1][2] <= range1[2][2]))
        and (range2[2][1] > range1[1][1] or (range2[2][1] == range1[1][1] and range2[2][2] >= range1[1][2]))
        and (range2[2][1] < range1[2][1] or (range2[2][1] == range1[2][1] and range2[2][2] <= range1[2][2]))
end

---Check if the cursor position is in the given range
---@param range integer[][] 0-based range
---@param cursor integer[] 1,0-based cursor position
---@return boolean
function M.in_range(range, cursor)
    local cursor0 = { cursor[1] - 1, cursor[2] }
    return (cursor0[1] > range[1][1] or (cursor0[1] == range[1][1] and cursor0[2] >= range[1][2]))
        and (cursor0[1] < range[2][1] or (cursor0[1] == range[2][1] and cursor0[2] <= range[2][2]))
end

---Find the parent (a previous node that contains the current node) of the node
---@param node table current node
---@return table|nil
function M.node_find_parent(node)
    local range_start, range_end = node:get_buf_position()
    local prev = node.parent.snippet and node.parent.snippet.prev.prev
    while prev do
        local range_start_prev, range_end_prev = prev:get_buf_position()
        if M.range_contains({ range_start_prev, range_end_prev }, { range_start, range_end }) then
            return prev
        end
        prev = prev.parent.snippet and prev.parent.snippet.prev.prev
    end
end

---Check if the cursor is at the end of a node
---@param range table 0-based range
---@param cursor number[] 1,0-based cursor position
---@return boolean
function M.cursor_at_end_of_range(range, cursor)
    return range[2][1] + 1 == cursor[1] and range[2][2] == cursor[2]
end

---Check if the cursor is at the end of a node
---@param range table 0-based range
---@param cursor number[] 1,0-based cursor position
---@return boolean
function M.cursor_at_start_of_range(range, cursor)
    return range[1][1] + 1 == cursor[1] and range[1][2] == cursor[2]
end

---Jump to the closer destination between a snippet and tabout
---@param snip_dest number[]
---@param tabout_dest number[]?
---@param direction number 1 or -1
---@return boolean true if a jump is performed
function M.jump_to_closer(snip_dest, tabout_dest, direction)
    direction = direction or 1
    local dest = choose_closer(snip_dest, tabout_dest)
    if not dest then
        return false
    end
    if vim.deep_equal(dest, tabout_dest) then
        M.jump(direction)
    else
        require("luasnip").jump(direction)
    end
    return true
end

return M
