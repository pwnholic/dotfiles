return {
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            { "hrsh7th/cmp-cmdline", event = "CmdlineEnter" },
            { "dmitmel/cmp-cmdline-history", event = "CmdlineChanged" },
            { "stevearc/vim-vscode-snippets" },
        },
        opts = function(_, opts)
            local cmp = require("cmp")
            local types = require("cmp.types")
            local luasnip = require("luasnip")
            local tabout = require("utils.tabout")

            opts.performance = { async_budget = 64, max_view_entries = 64 }
            opts.view = { entries = { name = "custom", selection_order = "near_cursor" } }
            -- opts.completion = { completeopt = "menu,menuone,noselect" }
            -- opts.preselect = cmp.PreselectMode.None
            opts.matching = {
                disallow_partial_matching = false,
                disallow_partial_fuzzy_matching = false,
                disallow_prefix_unmatching = false,
                disallow_symbol_nonprefix_matching = false,
            }

            opts.window = { completion = { col_offset = -3, side_padding = 1 } }

            opts.confirmation = {
                default_behavior = cmp.ConfirmBehavior.Replace,
                get_commit_characters = function(commit_characters)
                    vim.list_extend(commit_characters, { ".", ":", "(", "{" })
                    return commit_characters
                end,
            }
            opts.mapping = vim.tbl_extend("force", opts.mapping, {
                ["<S-Tab>"] = {
                    ["c"] = function()
                        if tabout.get_jump_pos(-1) then
                            tabout.jump(-1)
                            return
                        end
                        if cmp.visible() then
                            return cmp.select_prev_item()
                        else
                            return cmp.complete()
                        end
                    end,
                    ["i"] = function(fallback)
                        if luasnip.locally_jumpable(-1) then
                            local prev = luasnip.jump_destination(-1)
                            local _, snip_dest_end = prev:get_buf_position()
                            snip_dest_end[1] = snip_dest_end[1] + 1 -- (1, 0) indexed
                            local tabout_dest = tabout.get_jump_pos(-1)
                            if not tabout.jump_to_closer(snip_dest_end, tabout_dest, -1) then
                                fallback()
                            end
                        else
                            fallback()
                        end
                    end,
                },
                ["<Tab>"] = {
                    ["c"] = function()
                        if tabout.get_jump_pos(1) then
                            tabout.jump(1)
                            return
                        end
                        if cmp.visible() then
                            return cmp.select_next_item()
                        else
                            return cmp.complete()
                        end
                    end,
                    ["i"] = function(fallback)
                        if luasnip.expandable() then
                            return luasnip.expand()
                        elseif luasnip.locally_jumpable(1) then
                            local buf = vim.api.nvim_get_current_buf()
                            local current = luasnip.session.current_nodes[buf]
                            if tabout.node_has_length(current) then
                                local cursor = vim.api.nvim_win_get_cursor(0)
                                local current_range = { current:get_buf_position() }
                                if tabout.cursor_at_end_of_range(current_range, cursor) or tabout.cursor_at_start_of_range(current_range, cursor) then
                                    luasnip.jump(1)
                                else
                                    fallback()
                                end
                            else -- node has zero length
                                local parent = tabout.node_find_parent(current)
                                local parent_range = parent and { parent:get_buf_position() }
                                local tabout_dest = tabout.get_jump_pos(1)
                                if tabout_dest and parent_range and tabout.in_range(parent_range, tabout_dest) then
                                    tabout.jump(1)
                                else
                                    luasnip.jump(1)
                                end
                            end
                        else
                            fallback()
                        end
                    end,
                },
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
                { name = "luasnip", priority = 600, group_index = 1, max_item_count = 3 },
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
    {
        "L3MON4D3/LuaSnip",
        keys = function()
            return {
                {
                    "<Tab>",
                    function()
                        require("luasnip").jump(1)
                    end,
                    mode = "s",
                },
                {
                    "<S-Tab>",
                    function()
                        require("luasnip").jump(-1)
                    end,
                    mode = "s",
                },
                {
                    "<C-n>",
                    function()
                        return require("luasnip").choice_active() and "<Plug>luasnip-next-choice" or "<C-n>"
                    end,
                    expr = true,
                    mode = "s",
                },
                {
                    "<C-p>",
                    function()
                        return require("luasnip").choice_active() and "<Plug>luasnip-prev-choice" or "<C-p>"
                    end,
                    expr = true,
                    mode = "s",
                },
            }
        end,
        opts = function()
            local ls_types = require("luasnip.util.types")
            require("luasnip.loaders.from_vscode").lazy_load({ paths = vim.fn.stdpath("data") .. "/lazy/vim-vscode-snippets" })
            return {
                keep_roots = true,
                link_roots = true,
                exit_roots = false,
                link_children = true,
                region_check_events = "CursorMoved,CursorMovedI",
                delete_check_events = "TextChanged,TextChangedI",
                enable_autosnippets = true,
                store_selection_keys = "<Tab>",
                ext_opts = {
                    [ls_types.choiceNode] = {
                        active = { virt_text = { { "▐", "Number" } } },
                    },
                    [ls_types.insertNode] = {
                        unvisited = {
                            virt_text = { { "▐", "NonText" } },
                            virt_text_pos = "inline",
                        },
                    },
                    [ls_types.exitNode] = {
                        unvisited = {
                            virt_text = { { "▐", "NonText" } },
                            virt_text_pos = "inline",
                        },
                    },
                },
            }
        end,
    },
}
