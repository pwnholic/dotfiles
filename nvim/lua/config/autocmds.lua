---@diagnostic disable: undefined-field
---@alias AugroupOpts { clear?: boolean }
---@alias AutocmdOpts vim.api.keyset.create_autocmd

---Create an augroup and return its id.
---@param name string
---@param opts? AugroupOpts
---@return integer
local function augroup(name, opts)
    return vim.api.nvim_create_augroup(name, vim.tbl_extend("force", { clear = true }, opts or {}))
end

---Create an autocmd. Accepts an optional augroup name as the first argument.
---@param group string|integer|nil Augroup name or i ed. If string, creates one automatically.
---@param events string|string[]
---@param opts AutocmdOpts
---@return integer autocmd_id
local function autocmd(group, events, opts)
    if type(group) == "string" then
        group = augroup(group)
    end
    return vim.api.nvim_create_autocmd(events, vim.tbl_extend("force", opts, { group = group or nil }))
end

---Run a callback only if the buffer is a real, writable file.
---@param buf integer
---@param file string
---@param callback fun()
local function if_real_file(buf, file, callback)
    vim.uv.fs_stat(file, function(err, stat)
        if err or not stat or stat.type ~= "file" then
            return
        end
        vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf) then
                callback()
            end
        end)
    end)
end

---Save a buffer silently if it is a real file.
---@param buf integer
---@param file string
local function buf_save(buf, file)
    if_real_file(buf, file, function()
        vim.api.nvim_buf_call(buf, function()
            vim.cmd.update({ mods = { emsg_silent = true } })
        end)
    end)
end

autocmd("Autosave", { "BufLeave", "WinLeave", "FocusLost" }, {
    nested = true,
    desc = "Autosave on focus change.",
    callback = function(args)
        buf_save(args.buf, args.file)
    end,
})
