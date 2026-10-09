-- Advanced fuzzy matcher config for blink.cmp (frizbee, Rust/SIMD).
--
-- Docs: blink.cmp `doc/configuration/fuzzy.md`, `doc/recipes.md#Fuzzy`,
-- `lua/blink/cmp/config/fuzzy.lua`, `lua/blink/cmp/fuzzy/init.lua`,
-- `lua/blink/cmp/fuzzy/rust/lib.rs`, `lua/blink/cmp/fuzzy/rust/sort.rs`.
--
-- IMPORTANT -- validator constraint (learned the hard way):
-- `blink.lib/config.lua` validates `fuzzy.sorts` as a *list* of
-- `function | "label" | "sort_text" | "kind" | "score" | "exact"` and rejects
-- a function value, even though fuzzy.md documents a "Sort list function"
-- (`fuzzy/init.lua` would accept it at runtime). So `sorts` MUST be a static
-- list here. Per-filetype chains are therefore expressed with ONE static
-- list whose custom comparators read `vim.bo.filetype` themselves, instead
-- of swapping the list per filetype.
--
-- Why these choices:
--   * `implementation = "prefer_rust"`: Rust unlocks typo resistance,
--     proximity bonus, frecency, full unicode, and best-match guarantees
--     (`fuzzy.lua` notes every one of these does NOT apply to the Lua
--     fallback). Plain `prefer_rust` (no `_with_warning`) keeps startup
--     quiet while still falling back silently when the binary is missing.
--   * `max_typos`: default is already length-relative
--     (`floor(#keyword / 4)`). Kept explicit with a guard: short keywords
--     (< 5 chars) get 0 typos so `fmt` never matches `fmtx`-style noise,
--     while long identifiers keep full typo resistance.
--   * `frecency`: the Rust matcher boosts recently/frequently picked items
--     (persisted at `state/blink/cmp/frecency.dat`). Explicitly enabled so
--     the behavior survives upstream default flips.
--   * `use_proximity = true`: boosts candidates near surrounding words --
--     the win is biggest in dense code (chained calls, struct literals).
--
-- Sorting (order = priority; first non-tie wins -- see `rust/sort.rs` and
-- `recipes.md#Fuzzy-sorting-filtering`):
--   1. `deprioritize_underscore`: private/dunder names (`_foo`, `__x`) last.
--      A Lua function (upstream recipe), which forces the sort fallback path
--      through `fuzzy/sort.lua` instead of Rust (`fuzzy/init.lua`:
--      `sort_in_rust` is false when any sort is a function). The remaining
--      builtins keep upstream semantics there, and the fuzzy score itself
--      still comes from Rust -- only the final ordering runs in Lua.
--   2. `exact`: case-sensitive exact match always wins (docs recipe
--      "Always prioritize exact matches"; Rust gives exact a +4 bonus only).
--   3. `score`: frizbee match quality (typo/proximity/frecency aware).
--   4. `ranked_kind_sort`: LSP kind with project-aware ranks -- callable,
--      user-defined symbols first (see `KIND_RANK`); deprioritizes
--      Text/Snippet/Keyword noise that LSPs (notably pyright, gopls
--      helpers) rank too highly. Filetype-aware internally: full ranking
--      for go/python/rust/typescript, pass-through otherwise (EmmyLua and
--      markdown sources provide weak `kind` data but good `sortText`).
--   5. `sort_text`: trusts the LSP's own context relevance.
--   6. `label`: alphabetical fallback (also pushes `_` names down, matching
--      the builtin `sort.label` behavior in `fuzzy/sort.lua`).
--
-- Performance notes:
--   * Builtin string sorts would run in Rust (`sort_in_rust`); the two
--     custom comparators keep ordering in Lua. If completion ever feels slow
--     on 10k+ item lists, drop the function sorts and keep pure builtins to
--     restore the all-Rust sort path.
--   * `use_proximity` scans nearby text per keystroke (guarded at 10k chars
--     upstream in `fuzzy/init.lua`); disable it only if profiling points at
--     the matcher on giant minified buffers.

-- Lower number = suggested earlier. Ranks the CompletionItemKind values most
-- useful while writing Go / Python / Rust / TypeScript; everything else
-- falls through to rank 50 in `ranked_kind`.
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

-- Filetypes where LSP `kind` data is trustworthy (gopls, pyright,
-- rust-analyzer, vtsls emit heavy Text/Keyword/Snippet traffic around
-- imports, struct tags, decorators, and JSX props -- exactly where ranking
-- helps). Other filetypes pass through to `sort_text`.
local KIND_RANKED_FTS = {
    go = true,
    python = true,
    rust = true,
    typescript = true,
    typescriptreact = true,
}

-- Lower number = suggested earlier (mirrors the ascending `a.kind < b.kind`
-- comparison in `fuzzy/sort.lua` and `rust/sort.rs`).
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

-- Primary sort: private/dunder identifiers (`_foo`, `__bar`) always lose to
-- public ones. Returns nil on ties so the next sort decides (Lua
-- `table.sort` convention per fuzzy.md "Custom sorting"). Upstream recipe,
-- hardened with nil-label guards.
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

-- `kind` with project-aware ranks instead of raw numeric kind order.
-- Filetype-aware: only applies ranking where LSP kinds are trustworthy;
-- returns nil elsewhere so `sort_text` decides.
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
        fuzzy = {
            -- Rust (frizbee/SIMD) with silent Lua fallback: unlocks typo
            -- resistance, proximity, frecency, and best-match guarantees.
            implementation = "prefer_rust",
            -- No typo tolerance on short keywords (avoids `fmt` ~ `fmtx`
            -- noise); full length-relative tolerance (`floor(len/4)`) above.
            max_typos = function(keyword)
                if #keyword < 5 then
                    return 0
                end
                return math.floor(#keyword / 4)
            end,
            -- Boost recently/frequently accepted items (Rust only).
            -- This IS the cache: Rust persists recent/frequent picks to
            -- `path` and reloads it on startup, no manual caching needed.
            frecency = {
                enabled = true,
                path = vim.fs.joinpath(vim.fn.stdpath("state"), "blink", "cmp", "frecency.dat"),
            },
            -- Boost candidates near surrounding words (Rust only); biggest
            -- win in dense code like chained calls and struct literals.
            use_proximity = true,
            -- Static list (NOT a function): the blink.lib validator rejects
            -- a function value for `sorts` at setup time. Filetype tuning
            -- lives inside `ranked_kind_sort` instead.
            sorts = {
                deprioritize_underscore,
                "exact",
                "score",
                ranked_kind_sort,
                "sort_text",
                "label",
            },
        },
        signature = {
            enabled = true,
        },
    },
}
