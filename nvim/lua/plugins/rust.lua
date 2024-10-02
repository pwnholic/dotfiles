return {
    "zjp-CN/nvim-cmp-lsp-rs",
    ft = "rust",
    opts = {
        unwanted_prefix = { "color", "ratatui::style::Styled" },
        kind = function(k)
            return { k.Module, k.Function }
        end,
        combo = {
            alphabetic_label_but_underscore_last = function()
                local comparators = require("cmp_lsp_rs").comparators
                return { comparators.sort_by_label_but_underscore_last }
            end,
            recentlyUsed_sortText = function()
                local compare = require("cmp").config.compare
                local comparators = require("cmp_lsp_rs").comparators
                return {
                    compare.recently_used,
                    compare.sort_text,
                    comparators.sort_by_label_but_underscore_last,
                }
            end,
        },
    },
    config = function(_, opts)
        local cmp_rust = require("cmp_lsp_rs")
        local cmp = require("cmp")

        cmp_rust.setup(opts)

        cmp.setup.filetype("rust", {
            sorting = {
                priority_weight = 2,
                comparators = {
                    cmp.config.compare.offset,
                    cmp.config.compare.exact,
                    -- comparators.inherent_import_inscope,
                    cmp_rust.comparators.inscope_inherent_import,
                    cmp_rust.comparators.sort_by_label_but_underscore_last,
                },
            },
        })

        local sources = cmp.config.sources({
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
        })

        for _, source in ipairs(sources) do
            cmp_rust.filter_out.entry_filter(source)
        end
    end,
}
