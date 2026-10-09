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
--
-- Border/separator override: stock night paints floats, splits, and plugin
-- widgets with a blue tint (`border_highlight = blend_bg(blue1, 0.8)`).
-- Here everything becomes flat grey (`dark3`, the same grey used for
-- `NonText`) with no background of its own, so floats/splits/statusline
-- read as one continuous surface. `on_highlights` runs after all group
-- files (theme.lua applies groups first, then the hook), so this wins over
-- `groups/base.lua` and every plugin border that links to `FloatBorder`.
-- Title chip override: picker/input/`vim.ui.select` titles become a bright
-- `blue` badge with dark `bg_dark` text on top (reads before the grey
-- border). The chain is:
--   picker titles  -> FloatTitle -> SnacksTitle -> SnacksPickerTitle ...
--     actually `winhl()` maps picker FloatTitle to `SnacksPickerTitle`
--     (= orange on `bg_float` in tokyonight's snacks.lua), list/input box
--     titles to `SnacksPickerBoxTitle` / `SnacksPickerInputTitle`;
--   `Snacks.input` / `vim.ui.input` -> `SnacksInputTitle` (-> `Title` glue
--     in input.lua maps to `DiagnosticInfo` = cyan fg, hence stock cyan);
--   plain floats (help, hover) -> `FloatTitle` directly.
-- All of them land here: `Title`/`FloatTitle` for the generic path plus the
-- concrete Snacks groups. `bg_dark` text on `blue` keeps ~7:1 contrast on
-- both light and dark floats.
return {
    "folke/tokyonight.nvim",
    opts = {
        style = "night",
        on_highlights = function(hl, c)
            -- core float + window edges (border grey, title chip blue)
            hl.FloatBorder = { fg = c.dark3, bg = c.none }
            hl.WinSeparator = { fg = c.dark3, bg = c.none }
            hl.VertSplit = { fg = c.dark3, bg = c.none }
            hl.StatusLine = { bg = c.none }
            hl.StatusLineNC = { bg = c.none }
            hl.TabLineFill = { bg = c.none }
            -- Title chips: bright bg, dark fg. Everything is covered
            -- except `SnacksPickerBorder`, set once below with the grey
            -- chrome (no duplicate assignment).
            hl.Title = { fg = c.bg_dark, bg = c.blue, bold = true }
            hl.FloatTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            -- Snacks picker (list/input/box windows) + select provider
            -- (`vim.ui.select` goes through the same picker).
            hl.SnacksTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            hl.SnacksPickerTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            hl.SnacksPickerBoxTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            hl.SnacksPickerInputTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            -- Snacks input (also backs `vim.ui.input`).
            hl.SnacksInputTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            -- Which-key / noice titles ride along (borders below stay grey).
            hl.WhichKeyTitle = { fg = c.bg_dark, bg = c.blue, bold = true }
            -- keep borders grey: Blink completion/doc/signature borders
            -- don't link to FloatBorder; they set the blue tint directly.
            hl.BlinkCmpMenuBorder = { fg = c.dark3, bg = c.none }
            hl.BlinkCmpDocBorder = { fg = c.dark3, bg = c.none }
            hl.BlinkCmpSignatureHelpBorder = { fg = c.dark3, bg = c.none }
            -- LSP hover/signature + mason popups.
            hl.LspFloatBorder = { fg = c.dark3, bg = c.none }
            hl.LspInfoBorder = { fg = c.dark3, bg = c.none }
            hl.MasonNormal = { bg = c.none }
            hl.MasonHeader = { fg = c.dark3, bg = c.none }
            hl.MasonHighlightBlock = { bg = c.none }
            -- Snacks picker/input chrome (grey, not title chips).
            hl.SnacksPickerBorder = { fg = c.dark3, bg = c.none }
            hl.SnacksInputBorder = { fg = c.dark3, bg = c.none }
            hl.SnacksDashboardHeader = { fg = c.dark3 }
            -- LSP inline aids: same muted family. Stock tokyonight
            -- paints `LspInlayHint` with a blue7 wash bg
            -- (`blend_bg(blue7, 0.1)`); here both hints and codelens
            -- become plain `comment` text with no background, matching the
            -- LSP toggle behaviour (`InsertEnter` hides both; `InsertLeave`
            -- restores them). `LspCodeLensSeparator` (`|` between lenses)
            -- rides along; document references drop the gutter wash for an
            -- underline so the current symbol reads without stealing
            -- severity colors, and the active signature parameter keeps
            -- its visual-select bg.
            hl.LspInlayHint = { fg = c.comment, bg = c.none, underline = true, sp = c.teal }
            hl.LspCodeLens = { fg = c.comment, bg = c.none, italic = true }
            hl.LspCodeLensSeparator = { fg = c.dark3, bg = c.none }
            hl.LspReferenceText = { bg = c.none, underline = true }
            hl.LspReferenceRead = { bg = c.none, underline = true }
            hl.LspReferenceWrite = { bg = c.none, underline = true }
            -- Treesitter context: underline only, no bg wash. Stock
            -- tokyonight paints `TreesitterContext` with a fg_gutter wash
            -- bg; here the context lines stay transparent and only the
            -- bottom edge draws a line (the plugin's own README suggests
            -- exactly this: `hi TreesitterContextBottom gui=underline`).
            -- Both rules use `blue7` — the same desaturated slate the
            -- theme uses for scrollbars, indent guides and git signs —
            -- quiet against the code, visible against the gutter.
            hl.TreesitterContext = { bg = c.none }
            hl.TreesitterContextBottom = { bg = c.none, underline = true, sp = c.blue7 }
            hl.TreesitterContextLineNumberBottom = { bg = c.none, underline = true, sp = c.blue7 }
            -- Oil preview/confirmation floats set their own bg too.
            hl.OilPreview = { bg = c.none }
            -- Notifier borders follow severity. Snacks maps each level's
            -- border to its Diagnostic group at runtime (`notifier.lua`
            -- links `SnacksNotifierBorder<Level>` -> `Diagnostic<Level>`,
            -- trace/debug -> NonText), but tokyonight's snacks.lua paints
            -- them with low-alpha blends (`blend_bg(severity, 0.4)`) while
            -- this theme family greys every other border. Full-strength
            -- severity fg restores the signal: error red1, warn yellow,
            -- info cyan-blue2, trace purple, debug muted comment — the
            -- same signal colors used for the notify icons/titles.
            hl.WhichKeyBorder = { fg = c.dark3, bg = c.none }
            hl.NoiceCmdlinePopupBorder = { fg = c.dark3, bg = c.none }
            hl.SnacksNotifierBorderError = { fg = c.red1, bg = c.none }
            hl.SnacksNotifierBorderWarn = { fg = c.yellow, bg = c.none }
            hl.SnacksNotifierBorderInfo = { fg = c.blue2, bg = c.none }
            hl.SnacksNotifierBorderTrace = { fg = c.purple, bg = c.none }
            hl.SnacksNotifierBorderDebug = { fg = c.comment, bg = c.none }
        end,
    },
}
