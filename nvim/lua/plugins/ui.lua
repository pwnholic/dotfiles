return {
    { "nvim-lualine/lualine.nvim", opts = { extensions = { "oil", "mason", "trouble", "nvim-dap-ui", "fzf" } } },
    {
        "lukas-reineke/indent-blankline.nvim",
        opts = {
            indent = { char = "▏", tab_char = "▏", smart_indent_cap = true },
            debounce = 200,
            scope = {
                show_exact_scope = false,
                priority = 500,
                show_start = true,
                show_end = false,
                highlight = {
                    "@markup.heading.1.markdown",
                    "@markup.heading.2.markdown",
                    "@markup.heading.3.markdown",
                    "@markup.heading.4.markdown",
                    "@markup.heading.5.markdown",
                    "@markup.heading.6.markdown",
                },
            },
        },
    },
    {
        "folke/noice.nvim",
        opts = {
            cmdline = { enabled = true, view = "cmdline", format = { input = { view = "cmdline" } } },
            notify = { enabled = true, view = "notify" },
            popupmenu = { enabled = true, backend = "cmp" },
        },
    },
    {
        "folke/which-key.nvim",
        opts = {
            preset = "helix",
            icons = {
                breadcrumb = "",
                separator = "",
                group = "",
                ellipsis = "...",
                mappings = true,
                rules = false,
                colors = true,
            },
        },
    },
    {
        "nvimdev/dashboard-nvim",
        opts = {
            config = {
                header = vim.split(string.rep("\n", 1) .. [[
██████╗  ██╗ ███████╗ ███╗   ███╗ ██╗ ██╗      ██╗       █████╗  ██╗  ██╗    ██████╗  ██╗   ██╗ ██╗      ██╗   ██╗ ██╗ ██╗
██╔══██╗ ██║ ██╔════╝ ████╗ ████║ ██║ ██║      ██║      ██╔══██╗ ██║  ██║    ██╔══██╗ ██║   ██║ ██║      ██║   ██║ ██║ ██║
██████╔╝ ██║ ███████╗ ██╔████╔██║ ██║ ██║      ██║      ███████║ ███████║    ██║  ██║ ██║   ██║ ██║      ██║   ██║ ██║ ██║
██╔══██╗ ██║ ╚════██║ ██║╚██╔╝██║ ██║ ██║      ██║      ██╔══██║ ██╔══██║    ██║  ██║ ██║   ██║ ██║      ██║   ██║ ╚═╝ ╚═╝
██████╔╝ ██║ ███████║ ██║ ╚═╝ ██║ ██║ ███████╗ ███████╗ ██║  ██║ ██║  ██║    ██████╔╝ ╚██████╔╝ ███████╗ ╚██████╔╝ ██╗ ██╗
╚═════╝  ╚═╝ ╚══════╝ ╚═╝     ╚═╝ ╚═╝ ╚══════╝ ╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝    ╚═════╝   ╚═════╝  ╚══════╝  ╚═════╝  ╚═╝ ╚═╝
    ]] .. "\n", "\n"),
            },
        },
    },
    {
        "folke/tokyonight.nvim",
        opts = {
            style = "night",
            on_highlights = function(hl, c)
                -- hl.LspReferenceText = { italic = true, bold = true, reverse = true }
                -- hl.LspReferenceRead = { italic = true, bold = true, reverse = true }
                -- hl.LspReferenceWrite = { italic = true, bold = true, reverse = true }
                hl.LspCodeLens = { link = "DiagnosticVirtualTextHint", default = true }
                hl.LspCodeLensText = { link = "DiagnosticVirtualTextHint", default = true }
                hl.LspCodeLensSign = { link = "DiagnosticVirtualTextHint", default = true }
                hl.LspCodeLensSeparator = { link = "Boolean", default = true }
                hl.LspInlayHint = { fg = c.dark5, bg = c.none, underline = true, italic = true }
                hl.LspSignatureActiveParameter = { fg = c.magenta2, italic = true, bold = true, sp = c.yellow1, underline = true }

                hl.GitSignsCurrentLineBlame = { fg = c.dark5, bg = c.none }

                hl.OilDir = { fg = c.orange, bg = c.none, bold = true }
                hl.OilDirIcon = { fg = c.orange, bg = c.none }
                hl.OilLink = { link = "Constant" }
                hl.OilLinkTarget = { link = "Comment" }
                hl.OilCopy = { link = "DiagnosticSignHint", bold = true }
                hl.OilMove = { link = "DiagnosticSignWarn", bold = true }
                hl.OilChange = { link = "DiagnosticSignWarn", bold = true }
                hl.OilCreate = { link = "DiagnosticSignInfo", bold = true }
                hl.OilDelete = { link = "DiagnosticSignError", bold = true }
                hl.OilPermissionNone = { link = "NonText" }
                hl.OilPermissionRead = { fg = c.red1, bg = c.none, bold = true }
                hl.OilPermissionWrite = { fg = c.yellow, bg = c.none, bold = true }
                hl.OilPermissionExecute = { fg = c.teal, bg = c.none, bold = true }
                hl.OilTypeDir = { link = "Directory" }
                hl.OilTypeFifo = { link = "Special" }
                hl.OilTypeFile = { link = "NonText" }
                hl.OilTypeLink = { link = "Constant" }
                hl.OilTypeSocket = { link = "OilSocket" }
                hl.OilSize = { fg = c.teal, bg = c.none }
                hl.OilMtime = { fg = c.purple, bg = c.none }

                hl.FzfLuaDirPart = { fg = c.green }
                hl.FzfLuaBorder = { fg = c.bg_dark, bg = c.bg_dark }
                hl.FzfLuaFilePart = { fg = "#ffffff" }
                hl.FzfLuaFzfCursorLine = { bg = c.fg_gutter }
                hl.RenderMarkdownBullet = { fg = c.red, bg = c.none }
                hl.GoJsonTags = { fg = c.red, bg = c.bg_dark }

                hl.FloatBorder = { fg = c.comment, bg = c.bg_statusline }
                hl.WinSeparator = { link = "Comment" }
            end,
        },
    },
}
