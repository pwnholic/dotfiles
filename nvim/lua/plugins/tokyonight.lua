-- TokyoNight style: night instead of LazyVim's default moon.
--
-- LazyVim declares this plugin itself in `lazyvim/plugins/colorscheme.lua` with
-- `opts = { style = "moon" }`, and loads it through the `colorscheme` function in
-- `lazyvim/config/init.lua` (`require("tokyonight").load()`). A spec here is merged over that
-- one, so `opts.style` replaces the value above it; the plugin stays lazy either way because
-- LazyVim's own spec is the one that declares `lazy = true`.
--
-- The style has to be set before the colorscheme is loaded, which is what `opts` does:
-- `tokyonight/init.lua` calls `config.extend(opts)` first and passes the result to
-- `theme.setup`, and `theme.setup` is where `vim.g.colors_name` becomes
-- `"tokyonight-" .. opts.style`. Setting it after the fact would leave the old highlights in
-- place, since `colorscheme.lua` only registers the colorscheme for later loading.
--
-- Styles, per `doc/tokyonight.nvim.txt` and `README.md`: night, storm, moon, day. `moon` is
-- the upstream default and lighter than `night`; `night` is the darkest of the three dark
-- variants (background `#1a1b26` against moon's `#222436`). `day` is selected by the theme
-- itself when `vim.o.background = "light"` (`light_style`), so it is not set here.
--
-- The switch also matches the terminal: the same night palette is available as a kitty theme
-- at `~/.local/share/nvim/lazy/tokyonight.nvim/extras/kitty/tokyonight_night.conf`.
return {
    "folke/tokyonight.nvim",
    opts = { style = "night" },
}
