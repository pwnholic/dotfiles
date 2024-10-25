local M = {}

---Compiled vim regex that decides if a command is a TUI app
M.TUI_REGEX = vim.regex(
    [[\v^(sudo(\s+--?(\w|-)+((\s+|\=)\S+)?)*\s+)?]]
        .. [[(/usr/bin/)?]]
        .. [[(n?vim?|vimdiff|emacs(client)?|lem|nano|helix|kak|]]
        .. [[tmux|lazygit|h?top|gdb|fzf|nmtui|sudoedit|ssh|crontab|asciinema)]]
)

---Check if any of the processes in terminal buffer `buf` is a TUI app
---@param buf integer? buffer handler
---@return boolean?
function M.running_tui(buf)
    local cmds = M.fg_cmds(buf)
    for _, cmd in ipairs(cmds) do
        if M.TUI_REGEX:match_str(cmd) then
            return true
        end
    end
    return false
end

---Get the command running in the foreground in the terminal buffer 'buf'
---@param buf integer? terminal buffer handler, default to 0 (current)
---@return string[]: command running in the foreground
function M.fg_cmds(buf)
    buf = buf or 0
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].bt ~= "terminal" then
        return {}
    end
    local channel = vim.bo[buf].channel
    local chan_valid, pid = pcall(vim.fn.jobpid, channel)
    if not chan_valid then
        return {}
    end

    local cmds = {}
    for _, stat_cmd_str in ipairs(vim.split(vim.fn.system("ps h -o stat,args -g " .. pid), "\n", { trimempty = true })) do
        local stat, cmd = unpack(vim.split(stat_cmd_str, "%s+", { trimempty = true }))
        if stat:find("^%w+%+") then
            table.insert(cmds, cmd)
        end
    end

    return cmds
end

function M.fold_virt_text(result, s, lnum, coloff)
    if not coloff then
        coloff = 0
    end
    local text = ""
    local hl
    for i = 1, #s do
        local char = s:sub(i, i)
        local hls = vim.treesitter.get_captures_at_pos(0, lnum, coloff + i - 1)
        local _hl = hls[#hls]
        if _hl then
            local new_hl = "@" .. _hl.capture
            if new_hl ~= hl then
                table.insert(result, { text, hl })
                text = ""
                hl = nil
            end
            text = text .. char
            hl = new_hl
        else
            text = text .. char
        end
    end
    table.insert(result, { text, hl })
end

function M.custom_foldtext()
    local start = vim.fn.getline(vim.v.foldstart):gsub("\t", string.rep(" ", vim.o.tabstop))
    local end_str = vim.fn.getline(vim.v.foldend)
    local end_ = vim.trim(end_str)
    local result = {}
    M.fold_virt_text(result, start, vim.v.foldstart - 1)
    table.insert(result, { " ... ", "Delimiter" })
    M.fold_virt_text(result, end_, vim.v.foldend - 1, #(end_str:match("^(%s+)") or ""))
    return result
end

return setmetatable(M, {
    __index = function(_, key)
        return require("utils." .. key)
    end,
})
