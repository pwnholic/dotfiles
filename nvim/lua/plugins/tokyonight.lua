return {
    "folke/tokyonight.nvim",
    opts = {
        style = "night",
        light_style = "day",
        transparent = false,
        terminal_colors = true,
        styles = {
            comments = { italic = true },
            keywords = { italic = true },
            functions = {},
            variables = {},
            sidebars = "dark", -- style for sidebars, see below
            floats = "dark", -- style for floating windows
        },
        day_brightness = 0.3, -- Adjusts the brightness of the colors of the **Day** style. Number between 0 and 1, from dull to vibrant colors
        dim_inactive = true,
        lualine_bold = false,
        cache = true,
        on_highlights = function(hl, c)
            local grey_border = { fg = c.comment, bg = c.bg_dark }
            local title = { fg = c.black, bg = c.purple, bold = true }

            hl.FloatBorder = grey_border
            hl.BlinkCmpDocBorder = grey_border
            hl.BlinkCmpMenuBorder = grey_border
            hl.WinSeparator = grey_border

            hl.SnacksInputTitle = title
            hl.SnacksPickerInputTitle = title
            hl.SnacksPickerInputBorder = grey_border
            hl.SnacksPickerBoxTitle = title

            hl.TreesitterContext = { bg = c.bg_dark, bold = true, underline = true, sp = c.purple }
        end,
    },
}
