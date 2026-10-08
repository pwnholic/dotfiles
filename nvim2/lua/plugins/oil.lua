--- oil.nvim: edit the filesystem like a buffer.
---
--- Loaded by `:Oil` or by the `-` mapping (both are lazy triggers).
---
--- LSP rename awareness: oil performs file operations itself and applies
--- `workspace/willRenameFiles` edits when the server supports it. That is
--- enabled below (`lsp_file_methods`), which is the supported path for renames
--- done *through oil*. For programmatic renames elsewhere, the
--- capability-checked helper is `core.lsp.file_operations.rename()`.
---
--- Oil buffers are also understood by `core.root` (their `oil://` name resolves
--- to the directory) and therefore by the terminal context synchronization.
---
--- @class plugins.oil
local M = {}

local SRC = "https://github.com/stevearc/oil.nvim"

function M.setup()
    require("core.pack").register({
        src = SRC,
        name = "oil.nvim",
        cmd = { "Oil" },
        keys = { { "-", mode = "n", desc = "open parent directory (oil)" } },
        reloadable = true,
        config = M.configure,
    })
end

function M.configure()
    local ok, oil = pcall(require, "oil")
    if not ok then
        require("core.notify").error("oil.nvim could not be loaded: " .. tostring(oil))
        return
    end

    oil.setup({
        default_file_explorer = true,
        columns = { "icon" },
        buf_options = { buflisted = false, bufhidden = "hide" },
        win_options = {
            wrap = false,
            signcolumn = "no",
            foldcolumn = "0",
            spell = false,
            list = false,
            conceallevel = 3,
            concealcursor = "nvic",
        },
        delete_to_trash = false,
        skip_confirm_for_simple_edits = false,
        prompt_save_on_select_new_entry = true,
        -- LSP file operations: oil checks each client's capabilities itself and
        -- falls back to a plain rename when the server does not support them.
        lsp_file_methods = {
            enabled = true,
            timeout_ms = 1000,
            autosave_changes = false,
        },
        view_options = { show_hidden = false, natural_order = "fast" },
        -- No border here: the float inherits `vim.opt.winborder`.
        float = { padding = 2, max_width = 0.6, max_height = 0.6 },
    })

    -- Re-created after a reload because oil's config is reloadable.
    vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "open parent directory" })
end

function M.teardown()
    pcall(vim.keymap.del, "n", "-")
end

return M
