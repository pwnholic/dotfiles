return {
    {
        "folke/snacks.nvim",
        opts = function(_, opts)
            opts.picker = opts.picker or {}
            -- Ivy titles centered (upstream ivy preset uses left).
            -- No tbl_extend needed: lazy.nvim deep-merges specs itself
            -- (`M._values` -> `Util.merge`, force behavior), and this fn
            -- receives the merged base as `opts`.
            opts.picker.layouts = opts.picker.layouts or {}
            opts.picker.layouts.ivy = opts.picker.layouts.ivy or {}
            opts.picker.layouts.ivy.layout = opts.picker.layouts.ivy.layout or {}
            opts.picker.layouts.ivy.layout.title_pos = "center"
            opts.picker.layouts.ivy_split = opts.picker.layouts.ivy_split or {}
            opts.picker.layouts.ivy_split.layout = opts.picker.layouts.ivy_split.layout or {}
            opts.picker.layouts.ivy_split.layout.title_pos = "center"
            -- Sources merge key-wise by lazy.nvim; direct assign keeps base keys.
            opts.picker.sources = opts.picker.sources or {}
            opts.picker.sources.files = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.git_files = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.grep = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.git_grep = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.grep_word = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.grep_buffers = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.lines = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.lsp_definitions = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.lsp_declarations = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.lsp_references = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.lsp_implementations = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.lsp_type_definitions = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.lsp_incoming_calls = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.lsp_outgoing_calls = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.lsp_symbols = { layout = { preview = "main", preset = "ivy" } }
            opts.picker.sources.lsp_workspace_symbols = { layout = { preview = "main", preset = "ivy" } }
            -- Indent keeps base `enabled = true`; only chars overridden.
            opts.indent = opts.indent or {}
            opts.indent.indent = { char = "▏" }
            opts.indent.scope = { char = "▏", underline = true }
            -- Dashboard: assign preset fields directly to keep base `pick` fn.
            opts.dashboard = opts.dashboard or {}
            -- Content width matches header (50 cols): header fills the slot
            -- edge-to-edge, so centering is a single outer offset instead of
            -- outer + inner padding stacking two floor() roundings.
            opts.dashboard.width = 50
            opts.dashboard.preset = opts.dashboard.preset or {}
            -- Content width matches header (50 cols): header fills the slot
            -- edge-to-edge, so centering is a single outer offset instead of
            -- outer + inner padding stacking two floor() roundings.
            opts.dashboard.preset.keys = {
                {
                    icon = " ",
                    key = "f",
                    desc = "Find File",
                    action = ":lua Snacks.dashboard.pick('files')",
                },
                { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                {
                    icon = " ",
                    key = "g",
                    desc = "Find Text",
                    action = ":lua Snacks.dashboard.pick('live_grep')",
                },
                {
                    icon = " ",
                    key = "r",
                    desc = "Recent Files",
                    action = ":lua Snacks.dashboard.pick('oldfiles')",
                },
                { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                { icon = " ", key = "q", desc = "Quit", action = ":qa" },
            }
            -- Each Text needs trailing \n (except last): `D:block` only
            -- splits rows on newline, otherwise all lines merge into one row.
            opts.dashboard.preset.header = {
                {
                    "██████╗  ██╗ ███████╗ ███╗   ███╗ ██╗ ██╗      ██╗       █████╗  ██╗  ██╗\n",
                    hl = "SnacksDashboardHeader1",
                },
                {
                    "██╔══██╗ ██║ ██╔════╝ ████╗ ████║ ██║ ██║      ██║      ██╔══██╗ ██║  ██║\n",
                    hl = "SnacksDashboardHeader2",
                },
                {
                    "██████╔╝ ██║ ███████╗ ██╔████╔██║ ██║ ██║      ██║      ███████║ ███████║\n",
                    hl = "SnacksDashboardHeader3",
                },
                {
                    "██╔══██╗ ██║ ╚════██║ ██║╚██╔╝██║ ██║ ██║      ██║      ██╔══██║ ██╔══██║\n",
                    hl = "SnacksDashboardHeader4",
                },
                {
                    "██████╔╝ ██║ ███████║ ██║ ╚═╝ ██║ ██║ ███████╗ ███████╗ ██║  ██║ ██║  ██║\n",
                    hl = "SnacksDashboardHeader5",
                },
                {
                    "╚═════╝  ╚═╝ ╚══════╝ ╚═╝     ╚═╝ ╚═╝ ╚══════╝ ╚══════╝ ╚═╝  ╚═╝ ╚═╝  ╚═╝\n",
                    hl = "SnacksDashboardHeader6",
                },
            }
        end,
    },
}
