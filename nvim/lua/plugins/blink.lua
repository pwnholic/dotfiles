return {
    "saghen/blink.cmp",
    opts = function(_, opts)
        opts.enabled = function()
            return vim.fn.reg_recording() == "" and vim.fn.reg_executing() == ""
        end
        opts.fuzzy = {
            implementation = pcall(require, "blink.cmp.fuzzy.rust") and "prefer_rust" or "lua",
            sorts = { "score", "sort_text", "label" },
        }
        opts.completion = {
            list = {
                selection = {
                    preselect = true,
                    auto_insert = true,
                },
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 5,
            },
        }
        opts.sources = {
            default = { "snippets", "lsp", "path", "buffer" },
            providers = {
                lsp = { timeout_ms = 500 },
                buffer = {
                    opts = {
                        get_bufnrs = function()
                            return vim.tbl_filter(function(bufnr)
                                return vim.api.nvim_buf_is_valid(bufnr)
                                    and vim.api.nvim_buf_is_loaded(bufnr)
                                    and vim.bo[bufnr].buftype == ""
                                    and vim.bo[bufnr].buflisted
                                    and vim.api.nvim_buf_get_name(bufnr) ~= ""
                            end, vim.api.nvim_list_bufs())
                        end,
                    },
                    transform_items = function(ctx, items)
                        local keyword = ctx.get_keyword()
                        if not keyword:match("^[A-Za-z]") then
                            return items
                        end

                        local is_lower = keyword:match("^%l")
                        local pattern = is_lower and "^%u%l+$" or "^%l+$"
                        local case = is_lower and string.lower or string.upper
                        local seen = {}

                        return vim.iter(items)
                            :map(function(item)
                                local text = item.insertText
                                if not text then
                                    return item
                                end
                                if text:match(pattern) then
                                    text = case(text:sub(1, 1)) .. text:sub(2)
                                    item.insertText = text
                                    item.label = text
                                end
                                return item
                            end)
                            :filter(function(item)
                                local text = item.insertText
                                if not text or seen[text] then
                                    return false
                                end
                                seen[text] = true
                                return true
                            end)
                            :totable()
                    end,
                },
            },
        }
    end,
}
