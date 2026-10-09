-- Snacks modules config: picker layouts + indent guides.
--
-- Pickers for finding files / searching text: bottom "ivy" bar with the preview in the main
-- window (the same layout LazyVim/snacks already uses for the `lines` source, see the screenshot
-- of `M.lines` in lua/snacks/picker/config/sources.lua).
--
-- Docs (docs/picker.md):
--   * `ivy` preset (docs/picker.md, section "Layouts"): `{ box = "vertical", backdrop = false, row = -1, width = 0,
--     height = 0.4, border = "top", title = " {title} {live} {flags}", title_pos = "left",
--     { win = "input", height = 1, border = "bottom" },
--     { box = "horizontal", { win = "list", border = "none" },
--       { win = "preview", title = "{preview}", width = 0.6, border = "left" } } }`
--   * `preview = "main"` (`snacks.picker.layout.Config`): "show preview window in the picker or the
--     main window" — the preview window becomes the current editor window, so the file/text being
--     previewed is shown where you normally edit, with `CursorLine:SnacksPickerPreviewCursorLine`
--     (lua/snacks/picker/core/preview.lua:135-141).
--
-- Where the override goes: `snacks.picker.Config.layout` may be set globally
-- (`opts.picker.layout`) or per source (`opts.picker.sources.<name>.layout`). Per source is used
-- here so the other pickers keep LazyVim's centered default layout (`vim.o.columns >= 120 and
-- "default" or "vertical"`). Merge order is
-- `{ defaults, user, source, call-opts }` (lua/snacks/picker/config/init.lua M.get), so a source
-- layout wins over the global default preset.
--
-- `lines` already ships this exact layout upstream; it is listed here to keep the group visible in
-- one place. The `lsp_*` sources (definitions, declarations, references, implementations,
-- type_definitions, incoming_calls, outgoing_calls, symbols, workspace_symbols) are listed too,
-- so jumping to a result uses the same bottom bar. `main` is left unset so snacks picks the current
-- non-floating file window (lua/snacks/picker/core/main.lua M:find).
return {
    {
        "folke/snacks.nvim",
        opts = {
            picker = {
                sources = {
                    -- file finding
                    files = { layout = { preview = "main", preset = "ivy" } },
                    git_files = { layout = { preview = "main", preset = "ivy" } },
                    -- text search
                    grep = { layout = { preview = "main", preset = "ivy" } },
                    git_grep = { layout = { preview = "main", preset = "ivy" } },
                    grep_word = { layout = { preview = "main", preset = "ivy" } },
                    grep_buffers = { layout = { preview = "main", preset = "ivy" } },
                    lines = { layout = { preview = "main", preset = "ivy" } },
                    -- LSP
                    lsp_definitions = { layout = { preview = "main", preset = "ivy" } },
                    lsp_declarations = { layout = { preview = "main", preset = "ivy" } },
                    lsp_references = { layout = { preview = "main", preset = "ivy" } },
                    lsp_implementations = { layout = { preview = "main", preset = "ivy" } },
                    lsp_type_definitions = { layout = { preview = "main", preset = "ivy" } },
                    lsp_incoming_calls = { layout = { preview = "main", preset = "ivy" } },
                    lsp_outgoing_calls = { layout = { preview = "main", preset = "ivy" } },
                    lsp_symbols = { layout = { preview = "main", preset = "ivy" } },
                    lsp_workspace_symbols = { layout = { preview = "main", preset = "ivy" } },
                },
            },
            indent = {
                indent = {
                    char = "▏",
                },
                scope = {
                    char = "▏",
                    underline = true,
                },
            },
        },
    },
}
