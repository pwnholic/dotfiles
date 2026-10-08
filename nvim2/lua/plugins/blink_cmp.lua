--- blink.cmp: completion (LSP, path, snippets, buffer).
---
--- Pinned to the stable `1.*` release tags: the default branch is the in-progress
--- V2 (which additionally requires the `blink.lib` repository), while `1.*` is the
--- documented stable API and ships a prebuilt fuzzy-matching binary.
---
--- Completion capabilities must be registered *before* the first LSP client
--- starts. Clients attach while file arguments are opened (before
--- `User VeryLazy`), so `plugins/lsp.lua` loads this spec early when
--- `defaults.blink.load_early_for_lsp` is true; otherwise the plugin loads from
--- its own `InsertEnter`/`CmdlineEnter` triggers.
---
--- @class plugins.blink_cmp
local M = {}

local SRC = "https://github.com/Saghen/blink.cmp"

function M.setup()
    local o = require("core.defaults").get("blink", {})
    if o.enabled == false then
        return
    end

    local ok, err = require("core.pack").register({
        src = SRC,
        name = "blink.cmp",
        --- Release tags only: stable API plus the prebuilt fuzzy binary.
        version = "main",
        event = { "InsertEnter", "CmdlineEnter" },
        reloadable = true,
        config = M.configure,
    })
    if not ok then
        require("core.notify").error("blink_cmp: " .. tostring(err))
    end
end

function M.configure()
    local o = require("core.defaults").get("blink", {})
    local blink = require("blink.cmp")

    blink.setup({
        -- 'default' preset: C-space opens/accepts docs, C-n/C-p select, C-e hides.
        keymap = { preset = "default" },
        appearance = { nerd_font_variant = "mono" },
        completion = {
            documentation = { auto_show = o.documentation_auto_show ~= false },
        },
        sources = { default = { "lsp", "path", "snippets", "buffer" } },
        fuzzy = { implementation = "prefer_rust_with_warning" },
    })

    -- The `*` config applies to every server, so clients started later (or
    -- restarted) receive blink's capabilities.
    vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
end

function M.teardown()
    -- Nothing to own: blink installs its own autocmds/keymaps, and the `*` LSP
    -- config is re-applied by the reloadable configuration.
end

return M
