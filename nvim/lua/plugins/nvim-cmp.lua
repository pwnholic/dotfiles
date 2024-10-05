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
            local cmp_core = require("cmp.core")
            local luasnip = require("luasnip")
            local tabout = require("utils.tabout")

            ---@type string?
            local last_key

            vim.on_key(function(k)
                last_key = k
            end)

            ---@type integer
            local last_changed = 0
            local _cmp_on_change = cmp_core.on_change

            ---Improves performance when inserting in large files
            ---@diagnostic disable-next-line: duplicate-set-field
            function cmp_core.on_change(self, trigger_event)
                -- Don't know why but inserting spaces/tabs causes higher latency than other
                -- keys, e.g. when holding down 's' the interval between keystrokes is less
                -- than 32ms (80 repeats/s keyboard), but when holding spaces/tabs the
                -- interval increases to 100ms, guess is is due ot some other plugins that
                -- triggers on spaces/tabs
                -- Spaces/tabs are not useful in triggering completions in insert mode but can
                -- be useful in command-line autocompletion, so ignore them only when not in
                -- command-line mode
                if (last_key == " " or last_key == "\t") and string.sub(vim.fn.mode(), 1, 1) ~= "c" then
                    return
                end

                local now = vim.uv.now()
                local fast_typing = now - last_changed < 32
                last_changed = now

                if not fast_typing or trigger_event ~= "TextChanged" or cmp.visible() then
                    _cmp_on_change(self, trigger_event)
                    return
                end

                vim.defer_fn(function()
                    if last_changed == now then
                        _cmp_on_change(self, trigger_event)
                    end
                end, 200)
            end

            opts.performance = { async_budget = 64, max_view_entries = 64 }
            opts.view = { entries = { name = "custom", selection_order = "near_cursor" } }
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
                ["<BS>"] = {
                    i = function(fallback)
                        local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(0))
                        if not stat or stat.type ~= "file" then
                            return fallback()
                        end

                        if stat.size == vim.g.bigfile_size then
                            return fallback()
                        else
                            if cmp.visible() then
                                cmp.close()
                            end

                            local treesitter_indent = require("nvim-treesitter.indent")
                            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                            if row == 1 and col == 0 then
                                return
                            end

                            local current_line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1] or ""
                            local ok, indent = pcall(treesitter_indent.get_indent, row)
                            indent = ok and indent or 0

                            local function trim_and_set_cursor(new_line, target_row, cursor_col)
                                vim.api.nvim_buf_set_lines(0, target_row - 1, target_row, true, { new_line })
                                vim.api.nvim_win_set_cursor(0, { target_row, math.max(0, cursor_col) })
                            end

                            local function is_block_end(line)
                                return line:match("^%s*[%}%)]") or line:match("^%s*end")
                            end

                            local function is_comment(line)
                                return line:match("^%s*%-%-")
                            end

                            local trimmed_line = vim.fn.strcharpart(current_line, indent - 1, col - indent + 1):gsub("%s+", "")
                            if trimmed_line == "" then
                                if indent > 0 and col > indent then
                                    local new_line = vim.fn.strcharpart(current_line, 0, indent) .. vim.fn.strcharpart(current_line, col)
                                    if is_block_end(current_line) or is_comment(current_line) then
                                        trim_and_set_cursor(new_line, row, vim.fn.strcharlen(new_line))
                                    else
                                        trim_and_set_cursor(new_line, row, vim.fn.strcharlen(new_line))
                                    end
                                elseif row > 1 and indent > 0 and col + 1 > indent then
                                    local prev_line = vim.api.nvim_buf_get_lines(0, row - 2, row - 1, true)[1] or ""
                                    if vim.trim(prev_line) == "" then
                                        local prev_indent = treesitter_indent.get_indent(row - 1) or 0
                                        local new_line = vim.fn.strcharpart(current_line, 0, prev_indent) .. vim.fn.strcharpart(current_line, col)
                                        trim_and_set_cursor(new_line, row - 1, vim.fn.strcharlen(new_line))
                                    else
                                        local new_line = prev_line .. vim.fn.strcharpart(current_line, col)
                                        trim_and_set_cursor(new_line, row - 1, vim.fn.strcharlen(prev_line))
                                    end
                                else
                                    fallback()
                                end
                            else
                                fallback()
                            end
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
                view = { entries = { name = "custom", selection_order = "top_down" } },
            })

            cmp.setup.cmdline(":", {
                enabled = true,
                formatting = { fields = { "abbr" } },
                sources = { { name = "cmdline", group_index = 1 }, { name = "cmdline_history", group_index = 2 } },
                view = { entries = { name = "custom", selection_order = "top_down" } },
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
