return {
    "yioneko/nvim-cmp",
    branch = "perf",
    event = "InsertEnter",
    dependencies = {
        { "hrsh7th/cmp-nvim-lsp" },
        { "hrsh7th/cmp-cmdline" },
        { "lukas-reineke/cmp-rg" },
        { "saadparwaiz1/cmp_luasnip" },
        { "stevearc/vim-vscode-snippets" },
    },
    keys = function()
        return {
            { "<S-Tab>", mode = { "c", "i" } },
            { "<Tab>", mode = { "c", "i" } },
            { "<C-p>", mode = { "c", "i" } },
            { "<C-n>", mode = { "c", "i" } },
            { "<Down>", mode = { "c", "i" } },
            { "<Up>", mode = { "c", "i" } },
            { "<PageDown>", mode = { "c", "i" } },
            { "<C-u>", mode = { "c", "i" } },
            { "<C-d>", mode = { "c", "i" } },
            { "<C-e>", mode = { "c", "i" } },
            { "<CR>", mode = "i" },
            { "<C-y>", mode = "i" },
        }
    end,
    opts = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")
        local utils = require("utils.completion")
        return {
            auto_brackets = {},
            performance = { async_budget = 1, max_view_entries = 64, debounce = 1, throttle = 1 },
            completion = { completeopt = "menu,menuone,noinsert" },
            preselect = true,
            mapping = {
                ["<S-Tab>"] = {
                    ["c"] = function()
                        if utils.get_jump_pos(-1) then
                            utils.jump(-1)
                            return
                        end
                        if cmp.visible() then
                            cmp.select_prev_item()
                        else
                            cmp.complete()
                        end
                    end,
                    ["i"] = function(fallback)
                        if luasnip.locally_jumpable(-1) then
                            local prev = luasnip.jump_destination(-1)
                            local _, snip_dest_end = prev:get_buf_position()
                            snip_dest_end[1] = snip_dest_end[1] + 1 -- (1, 0) indexed
                            local tabout_dest = utils.get_jump_pos(-1)
                            if not utils.jump_to_closer(snip_dest_end, tabout_dest, -1) then
                                fallback()
                            end
                        else
                            fallback()
                        end
                    end,
                },
                ["<Tab>"] = {
                    ["c"] = function()
                        if utils.get_jump_pos(1) then
                            utils.jump(1)
                            return
                        end
                        if cmp.visible() then
                            cmp.select_next_item()
                        else
                            cmp.complete()
                        end
                    end,
                    ["i"] = function(fallback)
                        if luasnip.expandable() then
                            luasnip.expand()
                        elseif luasnip.locally_jumpable(1) then
                            local buf = vim.api.nvim_get_current_buf()
                            local cursor = vim.api.nvim_win_get_cursor(0)
                            local current = luasnip.session.current_nodes[buf]
                            if utils.node_has_length(current) then
                                if current.next_choice or utils.cursor_at_end_of_range({ current:get_buf_position() }, cursor) then
                                    luasnip.jump(1)
                                else
                                    fallback()
                                end
                            else -- node has zero length
                                local parent = utils.node_find_parent(current)
                                local range = parent and { parent:get_buf_position() }
                                local tabout_dest = utils.get_jump_pos(1)
                                if tabout_dest and range and utils.in_range(range, tabout_dest) then
                                    utils.jump(1)
                                else
                                    luasnip.jump(1)
                                end
                            end
                        else
                            fallback()
                        end
                    end,
                },
                ["<C-p>"] = {
                    ["c"] = cmp.mapping.select_prev_item(),
                    ["i"] = function()
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.choice_active() then
                            luasnip.change_choice(-1)
                        else
                            cmp.complete()
                        end
                    end,
                },
                ["<C-n>"] = {
                    ["c"] = cmp.mapping.select_next_item(),
                    ["i"] = function()
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.choice_active() then
                            luasnip.change_choice(1)
                        else
                            cmp.complete()
                        end
                    end,
                },
                ["<C-e>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.abort()
                    else
                        fallback()
                    end
                end, { "i", "c" }),
                ["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
                ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
                ["<CR>"] = cmp.mapping(utils.confirm({ select = true }), { "i" }),
                ["<C-y>"] = cmp.mapping(utils.confirm({ behavior = cmp.ConfirmBehavior.Replace }), { "i" }),
            },
            sources = cmp.config.sources({
                { name = "luasnip", max_item_count = 3, group_index = 1, priority = 600 },
                { name = "rg", keyword_length = 4, group_index = 2, priority = 400 },
                {
                    name = "nvim_lsp",
                    max_item_count = 12,
                    priority = 800,
                    group_index = 1,
                    entry_filter = function(entry, _)
                        local kinds = require("cmp.types").lsp.CompletionItemKind[entry:get_kind()]
                        if kinds == "Text" then
                            return false
                        end
                        return true
                    end,
                },
            }),
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },
            formatting = {
                expandable_indicator = true, -- ist mean show this ~ char when item to long
                fields = { "kind", "abbr", "menu" },
                format = function(entry, items)
                    local kind_icons = require("utils.icons").kinds
                    if items.kind == "Folder" then
                        items.menu = items.kind
                        items.menu_hl_group = "Directory"
                        items.kind = kind_icons.Folder
                        items.kind_hl_group = "Directory"
                    elseif items.kind == "File" then
                        local icon, hl_group = require("mini.icons").get("file", vim.fs.basename(items.word))
                        items.menu = items.kind
                        items.menu_hl_group = hl_group or "CmpItemKindFile"
                        items.kind = icon or kind_icons.File
                        items.kind_hl_group = hl_group or "CmpItemKindFile"
                    elseif entry.source.name == "rg" then
                        items.menu = "RipGrep"
                        items.menu_hl_group = "@tag.tsx"
                        items.kind = kind_icons.RipGrep
                        items.kind_hl_group = "@tag.tsx"
                    else
                        items.menu = items.kind
                        items.menu_hl_group = string.format("CmpItemKind%s", items.kind)
                        items.kind = vim.fn.strcharpart(kind_icons[items.kind] or "", 0, 2)
                    end
                    -- utils.clamp_cmp_item("abbr", vim.go.pw, math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.24)), items)
                    -- utils.clamp_cmp_item("menu", 0, math.max(10, math.ceil(vim.api.nvim_win_get_width(0) * 0.10)), items)
                    return items
                end,
            },
            experimental = { ghost_text = { hl_group = "CmpGhostText" } },
            sorting = {
                priority_weight = 2,
                comparators = {
                    cmp.config.compare.offset,
                    cmp.config.compare.exact,
                    cmp.config.compare.score,
                    cmp.config.compare.recently_used,
                    cmp.config.compare.locality,
                    cmp.config.compare.kind,
                    cmp.config.compare.lenght,
                },
            },
        }
    end,
    config = function(_, opts)
        local cmp = require("cmp")
        local utils = require("utils.completion")
        local parse = require("cmp.utils.snippet").parse
        require("cmp.utils.snippet").parse = function(input)
            local ok, ret = pcall(parse, input)
            if ok then
                return ret
            end
            return utils.snippet_preview(input)
        end

        cmp.setup.cmdline({ "/", "?" }, {
            enabled = true,
            window = { documentation = false },
            formatting = { fields = { "abbr" } },
            sources = { { name = "rg" } },
        })

        -- Use cmdline & path source for ':'.
        cmp.setup.cmdline(":", {
            enabled = true,
            ---@diagnostic disable-next-line: missing-fields
            formatting = { fields = { "abbr" } },
            sources = {
                { name = "cmdline", group_index = 1 },
            },
        })

        cmp.setup.cmdline("@", { enabled = false })
        cmp.setup.cmdline(">", { enabled = false })
        cmp.setup.cmdline("-", { enabled = false })
        cmp.setup.cmdline("=", { enabled = false })

        cmp.setup.filetype({ "sql", "mysql" }, { sources = { { name = "nvim_lsp" } } })

        cmp.setup(opts)

        cmp.event:on("confirm_done", function(event)
            if vim.tbl_contains(opts.auto_brackets or {}, vim.bo.filetype) then
                utils.auto_brackets(event.entry)
            end
        end)

        cmp.event:on("menu_opened", function(event)
            utils.add_missing_snippet_docs(event.window)
        end)
    end,
}
