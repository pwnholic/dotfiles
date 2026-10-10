-- blink.cmp fuzzy (frizbee, Rust/SIMD) + responsive menu/docs windows.
--
-- `fuzzy.sorts` MUST be a static list: `blink.lib/config.lua` validates it
-- as a list and rejects a function, even though fuzzy.md documents a sort
-- function (`fuzzy/init.lua` would accept it). Filetype tuning lives inside
-- `ranked_kind_sort` (reads `vim.bo.filetype`) instead of swapping lists.
--
-- Sort priority (first non-tie wins): deprioritize_underscore (upstream
-- recipe; a function sort forces the Lua ordering path in `fuzzy/sort.lua`,
-- score itself still comes from Rust), exact, score (typo/proximity/frecency
-- aware), ranked_kind_sort (project-aware LSP kind; pyright/gopls rank
-- Text/Snippet/Keyword too high), sort_text, label.
--
-- `draw.components.<name>.width.max` accepts number|function per render
-- (`render/text.lua`); window min/max are static, so values below stay safe
-- down to ~60-col splits. Narrow (<80): tighter budgets, kind column hidden.

-- Lower number = suggested earlier. Everything else falls to rank 50.
local KIND_RANK = {
    Method = 1,
    Function = 2,
    Constructor = 3,
    Field = 4,
    Variable = 5,
    Class = 6,
    Interface = 7,
    Struct = 8,
    Enum = 9,
    EnumMember = 10,
    Module = 11,
    Property = 12,
    Constant = 13,
    Value = 14,
    TypeParameter = 15,
    Event = 16,
    Operator = 17,
    Unit = 18,
    File = 19,
    Folder = 20,
    Reference = 21,
    Color = 22,
    -- Purposefully last: boilerplate that buries real symbols.
    Keyword = 30,
    Snippet = 31,
    Text = 32,
}

-- Only where LSP `kind` data is trustworthy; elsewhere pass through to
-- `sort_text`.
local KIND_RANKED_FTS = {
    go = true,
    python = true,
    rust = true,
    typescript = true,
    typescriptreact = true,
}

---@param kind integer?
---@return integer
local function ranked_kind(kind)
    if kind == nil then
        return 50
    end
    local name = vim.lsp.protocol.CompletionItemKind[kind]
    if name == nil then
        return 50
    end
    return KIND_RANK[name] or 50
end

-- Private/dunder (`_foo`) always loses; nil on ties so the next sort decides.
---@param a blink.cmp.CompletionItem
---@param b blink.cmp.CompletionItem
local function deprioritize_underscore(a, b)
    local a_private = a.label ~= nil and a.label:sub(1, 1) == "_"
    local b_private = b.label ~= nil and b.label:sub(1, 1) == "_"
    if a_private == b_private then
        return nil
    end
    return not a_private
end

-- Project-aware `kind` ranks; nil outside ranked filetypes so `sort_text` decides.
---@param a blink.cmp.CompletionItem
---@param b blink.cmp.CompletionItem
local function ranked_kind_sort(a, b)
    if not KIND_RANKED_FTS[vim.bo.filetype] then
        return nil
    end
    local ra, rb = ranked_kind(a.kind), ranked_kind(b.kind)
    if ra ~= rb then
        return ra < rb
    end
    if a.label ~= nil and b.label ~= nil and a.label ~= b.label then
        return a.label < b.label
    end
    return nil
end

---@return integer
local function split_width()
    local winid = vim.api.nvim_get_current_win()
    if winid ~= nil and vim.api.nvim_win_is_valid(winid) then
        return vim.api.nvim_win_get_width(winid)
    end
    return vim.o.columns
end

---@return boolean
local function is_narrow()
    return split_width() < 80
end

---@return integer
local function label_budget()
    return is_narrow() and 30 or 60
end

---@return integer
local function detail_budget()
    return is_narrow() and 12 or 30
end

return {
    "saghen/blink.cmp",
    dependencies = {
        { "saghen/blink.lib" },
    },
    build = function()
        require("blink.cmp").build():pwait()
    end,
    ---@type blink.cmp.Config
    opts = {
        completion = {
            list = {
                max_items = 50,
            },
            menu = {
                min_width = 15,
                max_height = 10,
                scrolloff = 2,
                scrollbar = true,
                draw = {
                    align_to = "label",
                    padding = 1,
                    gap = 1,
                    treesitter = { "lsp" },
                    -- Icon + label only; kind text adds noise the icon already carries.
                    columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
                    components = {
                        label = {
                            -- Runtime accepts fun(ctx): integer (`render/text.lua:16`);
                            -- `DrawWidth` EmmyLua type lags behind.
                            ---@diagnostic disable-next-line: assign-type-mismatch
                            width = { fill = true, max = label_budget },
                        },
                        label_description = {
                            ---@diagnostic disable-next-line: assign-type-mismatch
                            width = { max = detail_budget },
                        },
                    },
                },
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 250,
                update_delay_ms = 50,
                treesitter_highlighting = true,
                window = {
                    min_width = 10,
                    max_width = 45,
                    max_height = 20,
                    desired_min_width = 30,
                    desired_min_height = 10,
                    scrollbar = true,
                    direction_priority = {
                        menu_north = { "e", "w", "n", "s" },
                        menu_south = { "e", "w", "s", "n" },
                    },
                },
            },
            ghost_text = {
                -- AI off (`vim.g.ai_cmp = false`): no inline suggestion text.
                enabled = false,
                show_with_menu = true,
                show_without_menu = true,
                show_with_selection = true,
                show_without_selection = false,
            },
        },
        signature = {
            enabled = true,
            window = {
                min_width = 10,
                -- Narrower than docs: signatures are single-purpose rows.
                max_width = 60,
                max_height = 10,
                scrollbar = false,
            },
        },
        appearance = {
            nerd_font_variant = "mono",
        },
        fuzzy = {
            implementation = "prefer_rust",
            max_typos = function(keyword)
                if #keyword < 5 then
                    return 0
                end
                return math.floor(#keyword / 4)
            end,
            frecency = {
                enabled = true,
                path = vim.fs.joinpath(vim.fn.stdpath("state"), "blink", "cmp", "frecency.dat"),
            },
            use_proximity = true,
            sorts = {
                deprioritize_underscore,
                "exact",
                "score",
                ranked_kind_sort,
                "sort_text",
                "label",
            },
        },
        -- Cmdline-only: label-only rows, no docs/ghost (ghost flickers on `:` redraw).
        cmdline = {
            completion = {
                menu = {
                    min_width = 15,
                    max_height = 8,
                    draw = {
                        align_to = "label",
                        padding = 1,
                        gap = 1,
                        treesitter = {},
                        columns = { { "label" } },
                    },
                },
                documentation = {
                    auto_show = false,
                },
                -- Ghost flickers on `:` (full-line redraw per keystroke).
                ghost_text = {
                    enabled = false,
                },
            },
        },
    },
}
