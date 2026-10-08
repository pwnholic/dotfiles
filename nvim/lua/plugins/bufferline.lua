-- bufferline.nvim: disabled.
--
-- LazyVim's core `ui` spec (`~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/ui.lua:5-60`)
-- declares it on `VeryLazy` and maps its whole key surface:
--
--   <leader>bp / bP / br / bl / bj  -> :BufferLine* (pin, group close, close left/right, pick)
--   <S-h> / <S-l>, [b / ]b          -> :BufferLineCyclePrev/Next   (instead of :bprevious/:bnext)
--   [B / ]B                         -> :BufferLineMovePrev/Next    (instead of :brewind/:blast)
--
-- With the plugin disabled, LazyVim's own core keymaps are restored (they are declared in
-- `lazyvim/config/keymaps.lua` and were shadowed by bufferline's spec keys):
--
--   lua/lazyvim/config/keymaps.lua:34-37    <S-h>/<S-l>/[b/]b  ->  :bprevious / :bnext
--   /usr/share/nvim/runtime/lua/vim/_core/defaults.lua:422-438  [B/]B (Neovim 0.12 default)
--                                                                 ->  :brewind / :blast
--
-- The `<leader>b*` core mappings (`bb`, `bd`, `bo`, `bi`, `bD`) stay. Only the bufferline-only
-- `<leader>bp/bP/br/bl/bj` are gone; `<leader>uA` (showtabline toggle) is a snacks toggle from
-- `lazyvim/config/keymaps.lua:153` and stays mapped, but now only affects native tab pages.
-- No other plugin requires `bufferline` (only LazyVim's own config function does).
return {
    "akinsho/bufferline.nvim",
    enabled = false,
}
