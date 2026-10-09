return {
    {
        "folke/snacks.nvim",
        opts = function(_, opts)
            opts.picker = opts.picker or {}
            opts.picker.sources = vim.tbl_extend("force", opts.picker.sources or {}, {
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
            })
            opts.indent = vim.tbl_deep_extend("force", opts.indent or {}, {
                indent = {
                    char = "▏",
                },
                scope = {
                    char = "▏",
                    underline = true,
                },
            })
        end,
    },
}
