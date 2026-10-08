-- noice.nvim: disabled.
--
-- LazyVim's core `ui` spec enables noice with all three `lsp.override` hooks, which replaces
-- `vim.lsp.util.convert_input_to_markdown_lines` and `stylize_markdown` process-wide: noice's
-- version wraps `plaintext` documentation into a fenced code block, so every completion doc that
-- blink.cmp renders (`blink.cmp/lib/window/docs.lua`) shows up as a code block instead of text.
-- The rest of noice's UI is redundant here: the cmdline is the native `vim._core.ui2` UI.
--
-- `enabled = false` is a lazy.nvim plugin option, so this fragment and LazyVim's merge into one
-- spec and the value survives. Nothing loads, the markdown hooks stay native, and the noice
-- keymaps from the LazyVim spec (`<leader>sn*`, `<S-Enter>`, `<C-f>`/`<C-b>`) are not created.
-- The plugin stays on disk; `:Lazy clean` keeps it because disabled specs are retained.
return {
    "folke/noice.nvim",
    enabled = false,
}
