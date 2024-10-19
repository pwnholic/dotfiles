local M = {}

---@class keymap_def_t
---@field lhs string
---@field lhsraw string
---@field rhs string?
---@field callback function?
---@field expr boolean?
---@field desc string?
---@field noremap boolean?
---@field script boolean?
---@field silent boolean?
---@field nowait boolean?
---@field buffer boolean?
---@field replace_keycodes boolean?

---Get keymap definition
---@param mode string
---@param lhs string
---@return keymap_def_t
function M.get(mode, lhs)
    local lhs_keycode = vim.keycode(lhs)
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
        if vim.keycode(map.lhs) == lhs_keycode then
            return {
                lhs = map.lhs,
                rhs = map.rhs,
                expr = map.expr == 1,
                callback = map.callback,
                desc = map.desc,
                noremap = map.noremap == 1,
                script = map.script == 1,
                silent = map.silent == 1,
                nowait = map.nowait == 1,
                buffer = true,
                replace_keycodes = map.replace_keycodes == 1,
            }
        end
    end
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
        if vim.keycode(map.lhs) == lhs_keycode then
            return {
                lhs = map.lhs,
                rhs = map.rhs or "",
                expr = map.expr == 1,
                callback = map.callback,
                desc = map.desc,
                noremap = map.noremap == 1,
                script = map.script == 1,
                silent = map.silent == 1,
                nowait = map.nowait == 1,
                buffer = false,
                replace_keycodes = map.replace_keycodes == 1,
            }
        end
    end
    return {
        lhs = lhs,
        rhs = lhs,
        expr = false,
        noremap = true,
        script = false,
        silent = true,
        nowait = false,
        buffer = false,
        replace_keycodes = true,
    }
end

---@param def keymap_def_t
---@return function
function M.fallback_fn(def)
    local modes = def.noremap and "in" or "im"
    ---@param keys string
    ---@return nil
    local function feed(keys)
        local keycode = vim.keycode(keys)
        local keyseq = vim.v.count > 0 and vim.v.count .. keycode or keycode
        vim.api.nvim_feedkeys(keyseq, modes, false)
    end
    if not def.expr then
        return def.callback or function()
            feed(def.rhs)
        end
    end
    if def.callback then
        return function()
            feed(def.callback())
        end
    else
        -- Escape rhs to avoid nvim_eval() interpreting
        -- special characters
        local rhs = vim.fn.escape(def.rhs, "\\")
        return function()
            feed(vim.api.nvim_eval(rhs))
        end
    end
end

---Amend keymap
---Caveat: currently cannot amend keymap with <Cmd>...<CR> rhs
---@param modes string[]|string
---@param lhs string
---@param rhs function(fallback: function)
---@param opts table?
---@return nil
function M.amend(modes, lhs, rhs, opts)
    modes = type(modes) ~= "table" and { modes } or modes --[=[@as string[]]=]
    opts = opts or {}

    for _, mode in ipairs(modes) do
        local key_def = M.get(mode, lhs) -- original key definition
        local rhs_fn = function()
            rhs(M.fallback_fn(key_def))
        end

        if not key_def.buffer or opts.buffer then
            vim.keymap.set(mode, lhs, rhs_fn, opts)
        else
            -- If the original key definition is a buffer mapping, we should also set
            -- our buffer option to true to avoid "leaking" the buffer map to global
            vim.keymap.set(mode, lhs, rhs_fn, vim.tbl_deep_extend("keep", { buffer = true }, opts))
            -- The global keymap with an empty callback as fallback function, i.e.
            -- we shouldn't invoke the original keymap callback when we are not in
            -- that buffer
            vim.keymap.set(mode, lhs, function()
                rhs(function() end)
            end, opts)
        end
    end
end

return M
