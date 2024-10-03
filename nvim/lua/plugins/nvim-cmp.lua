return {
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            { "hrsh7th/cmp-cmdline", event = "CmdlineEnter" },
            { "dmitmel/cmp-cmdline-history", event = "CmdlineEnter" },
            {
                "garymjr/nvim-snippets",
                dependencies = "stevearc/vim-vscode-snippets",
                opts = { search_paths = { vim.fn.stdpath("data") .. "/lazy/vim-vscode-snippets" } },
            },
        },
        opts = function(_, opts)
            local cmp = require("cmp")
            local types = require("cmp.types")

            opts.performance = { async_budget = 64, max_view_entries = 64 }
            opts.view = { entries = { name = "custom", selection_order = "near_cursor" } }
            opts.preselect = cmp.PreselectMode.None
            opts.matching = {
                disallow_partial_matching = false,
                disallow_partial_fuzzy_matching = false,
                disallow_prefix_unmatching = false,
                disallow_symbol_nonprefix_matching = false,
            }
            opts.confirmation = {
                default_behavior = cmp.ConfirmBehavior.Replace,
                get_commit_characters = function(commit_characters)
                    vim.list_extend(commit_characters, { ".", ":", "(", "{" })
                    return commit_characters
                end,
            }

            opts.mapping = vim.tbl_extend("force", opts.mapping, {
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        if #cmp.get_entries() == 1 then
                            cmp.confirm({ select = true })
                        else
                            cmp.select_next_item()
                        end
                    else
                        fallback()
                    end
                end, { "i", "c" }),
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    else
                        fallback()
                    end
                end, { "c", "i" }),
                ["<BS>"] = cmp.mapping(function(fallback)
                    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                    if row == 1 and col == 0 then
                        return
                    end

                    if cmp.visible() then
                        cmp.close()
                    end

                    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
                    local ts = require("nvim-treesitter.indent")
                    local ok, indent = pcall(ts.get_indent, row)
                    if not ok then
                        indent = 0
                    end
                    if vim.fn.strcharpart(line, indent - 1, col - indent + 1):gsub("%s+", "") == "" then
                        if indent > 0 and col > indent then
                            local new_line = vim.fn.strcharpart(line, 0, indent) .. vim.fn.strcharpart(line, col)
                            vim.api.nvim_buf_set_lines(0, row - 1, row, true, { new_line })
                            vim.api.nvim_win_set_cursor(0, { row, math.min(indent or 0, vim.fn.strcharlen(new_line)) })
                        elseif row > 1 and (indent > 0 and col + 1 > indent) then
                            local prev_line = vim.api.nvim_buf_get_lines(0, row - 2, row - 1, true)[1]
                            if vim.trim(prev_line) == "" then
                                local prev_indent = ts.get_indent(row - 1) or 0
                                local new_line = vim.fn.strcharpart(line, 0, prev_indent) .. vim.fn.strcharpart(line, col)
                                vim.api.nvim_buf_set_lines(0, row - 2, row, true, { new_line })
                                vim.api.nvim_win_set_cursor(0, {
                                    row - 1,
                                    math.max(0, math.min(prev_indent, vim.fn.strcharlen(new_line))),
                                })
                            else
                                local len = vim.fn.strcharlen(prev_line)
                                local new_line = prev_line .. vim.fn.strcharpart(line, col)
                                vim.api.nvim_buf_set_lines(0, row - 2, row, true, { new_line })
                                vim.api.nvim_win_set_cursor(0, { row - 1, math.max(0, len) })
                            end
                        else
                            fallback()
                        end
                    else
                        fallback()
                    end
                end, { "i" }),
            })

            opts.sorting = vim.tbl_extend("force", opts.sorting, {
                priority_weight = 2,
                comparators = {
                    cmp.config.compare.exact,
                    cmp.config.compare.score,
                    cmp.config.compare.locality,
                    cmp.config.compare.recently_used,
                    cmp.config.compare.kind,
                    cmp.config.compare.offset,
                },
            })

            opts.formatting = vim.tbl_extend("force", opts.formatting, {
                expandable_indicator = true,
                fields = { "kind", "abbr", "menu" },
                format = function(_, items)
                    local kind_icons = LazyVim.config.icons.kinds
                    if items.kind == "Folder" then
                        items.menu = items.kind
                        items.menu_hl_group = "Directory"
                        items.kind = kind_icons.Folder
                        items.kind_hl_group = "Directory"
                    elseif items.kind == "File" then
                        local icon, icon_hl = require("mini.icons").get("file", vim.fs.basename(items.word))
                        items.menu = items.kind
                        items.menu_hl_group = icon_hl or "CmpItemKindFile"
                        items.kind = icon or kind_icons.File
                        items.kind_hl_group = icon_hl or "CmpItemKindFile"
                    else
                        items.menu = items.kind
                        items.menu_hl_group = string.format("CmpItemKind%s", items.kind)
                        items.kind = vim.fn.strcharpart(kind_icons[items.kind] or "", 0, 2)
                    end
                    return items
                end,
            })

            opts.sources = cmp.config.sources(vim.tbl_extend("force", {}, {
                { name = "path", priority = 1000, group_index = 1 },
                { name = "snippets", priority = 600, group_index = 1, max_item_count = 3 },
                {
                    name = "nvim_lsp",
                    max_item_count = 12,
                    priority = 800,
                    group_index = 1,
                    entry_filter = function(entry, _)
                        local kinds = types.lsp.CompletionItemKind[entry:get_kind()]
                        if kinds == "Text" then
                            return false
                        end
                        return true
                    end,
                },
            }))

            cmp.setup.cmdline({ "/", "?" }, {
                enabled = true,
                window = { documentation = false },
                formatting = { fields = { "abbr" } },
                sources = { { name = "buffer", group_index = 1 }, { name = "cmdline_history", group_index = 2 } },
            })

            cmp.setup.cmdline(":", {
                enabled = true,
                formatting = { fields = { "abbr" } },
                sources = { { name = "cmdline", group_index = 1 }, { name = "cmdline_history", group_index = 2 } },
            })
        end,
    },
}
