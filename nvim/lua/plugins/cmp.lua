return {
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            { "hrsh7th/cmp-cmdline", event = "CmdlineEnter" },
            {
                "garymjr/nvim-snippets",
                dependencies = "stevearc/vim-vscode-snippets",
                opts = { search_paths = { vim.fn.stdpath("data") .. "/lazy/vim-vscode-snippets" } },
            },
        },
        opts = function(_, opts)
            local cmp = require("cmp")
            opts.mapping = vim.tbl_extend("force", opts.mapping, {
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    else
                        fallback()
                    end
                end, { "c", "i" }),
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    else
                        fallback()
                    end
                end, { "c", "i" }),
            })

            opts.sorting = vim.tbl_extend("force", opts.sorting, {
                priority_weight = 2,
                comparators = {
                    cmp.config.compare.offset,
                    cmp.config.compare.exact,
                    cmp.config.compare.score,
                    cmp.config.compare.recently_used,
                    cmp.config.compare.locality,
                    cmp.config.compare.kind,
                },
            })

            opts.formatting = vim.tbl_extend("force", opts.formatting, {
                expandable_indicator = true,
                fields = { "kind", "abbr", "menu" },
                format = function(entry, items)
                    local kind_icons = LazyVim.config.icons.kinds
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
                        local kinds = require("cmp.types").lsp.CompletionItemKind[entry:get_kind()]
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
                sources = { { name = "buffer" } },
            })

            cmp.setup.cmdline(":", {
                enabled = true,
                formatting = { fields = { "abbr" } },
                sources = { { name = "cmdline", group_index = 1 } },
            })
        end,
    },
}
