return {
    {
        "echasnovski/mini.hipatterns",
        opts = {
            highlighters = {
                json = { pattern = [[json%s*:%s*]], group = "MiniHipatternsJson" },
                gorm = { pattern = [[gorm%s*:%s*]], group = "MiniHipatternsGorm" },
            },
        },
    },
    {
        "nvim-lualine/lualine.nvim",
        opts = function(_, opts)
            opts.extensions = { "oil", "mason", "trouble", "nvim-dap-ui", "fzf", "man", "quickfix" }
            table.insert(opts.sections.lualine_x, {
                function()
                    local names = {}
                    for _, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
                        table.insert(names, server.name)
                    end
                    return table.concat(names, " ")
                end,
                cond = function()
                    return vim.lsp.get_clients({ bufnr = 0 }) ~= nil
                end,
                color = function()
                    return LazyVim.ui.fg("Special")
                end,
            })
        end,
    },
    { "rcarriga/nvim-notify", opts = { render = "wrapped-compact", stages = "slide" } },
    {
        "lukas-reineke/indent-blankline.nvim",
        opts = {
            indent = { char = "▏", tab_char = "▏", smart_indent_cap = true },
            debounce = 200,
            scope = {
                show_exact_scope = false,
                priority = 500,
                show_start = true,
                show_end = true,
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
            presets = {
                bottom_search = true, -- use a classic bottom cmdline for search
                command_palette = true, -- position the cmdline and popupmenu together
                long_message_to_split = false, -- long messages will be sent to a split
                inc_rename = false,
                lsp_doc_border = true, -- add a border to hover docs and signature help
            },
            lsp = {
                hover = {
                    opts = { border = vim.g.border },
                },
                signature = {
                    enabled = true,
                    opts = { border = vim.g.border },
                },
                documentation = {
                    opts = { border = vim.g.border },
                },
            },
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
            dim_inactive = true,
            transparent = false,
            lualine_bold = true,
            cache = true,
            styles = {
                sidebars = "normal",
                floats = "normal",
                keywords = { italic = true },
                functions = { bold = true },
                variables = {},
            },
            on_highlights = function(hl, c)
                hl.LspCodeLens = { link = "DiagnosticVirtualTextHint", default = true }
                hl.LspCodeLensText = { link = "DiagnosticVirtualTextHint", default = true }
                hl.LspCodeLensSign = { link = "DiagnosticVirtualTextHint", default = true }
                hl.LspCodeLensSeparator = { link = "Boolean", default = true }
                hl.LspInlayHint = { fg = c.dark5, bg = c.none, underline = true, italic = true }
                hl.LspSignatureActiveParameter =
                    { fg = c.magenta2, italic = true, bold = true, sp = c.yellow1, underline = true }

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

                hl.FzfLuaDirPart = { fg = c.magenta }
                hl.FzfLuaBorder = { fg = c.bg_dark, bg = c.bg_dark }
                hl.FzfLuaFilePart = { fg = "#ffffff" }
                hl.FzfLuaFzfCursorLine = { bg = c.fg_gutter }
                hl.RenderMarkdownBullet = { fg = c.red, bg = c.none }
                hl.GoJsonTags = { fg = c.red, bg = c.bg_dark }

                hl.PmenuSel = { bg = c.fg_gutter, bold = true, underline = true, sp = c.orange }
                hl.Pmenu = { link = "FzfLuaFilePart" }
                hl.CmpItemKindText = { fg = "#82bab5", bg = c.none }
                hl.FloatBorder = { fg = c.comment, bg = c.none }
                hl.WinSeparator = { bg = c.none, fg = c.comment }
                hl.PmenuDark = { bg = c.bg_dark }

                hl.MiniHipatternsJson = { fg = c.purple, bg = c.none, bold = true }
                hl.MiniHipatternsGorm = { fg = c.yellow, bg = c.none, bold = true }

                hl["@variable.parameter"] = { fg = c.yellow, italic = true, bg = c.none }
                hl["@keyword.return"] = { fg = c.purple, bold = true, bg = c.none }
                hl["@type.builtin"] = { fg = c.blue1, bold = true, bg = c.none }
            end,
        },
    },
}
