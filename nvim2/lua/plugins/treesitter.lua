--- nvim-treesitter: parsers and queries.
---
--- Neovim 0.12 has built-in highlighting (`vim.treesitter.start()`); this
--- module therefore only enables it for buffers whose parser is installed and
--- reports missing parsers with an actionable hint instead of failing.
---
--- Parsers are *not* installed automatically: installing them needs network,
--- a compiler and an explicit user decision (`:TSInstall <lang>`,
--- `:checkhealth config` lists what is missing).
---
--- @class plugins.treesitter
local M = {}

local SRC = "https://github.com/nvim-treesitter/nvim-treesitter"

function M.setup()
    require("core.pack").register({
        src = SRC,
        name = "nvim-treesitter",
        -- Loaded on real buffers only: `FileType` also fires for scratch/health
        -- buffers, which should never trigger a plugin install.
        event = { "BufReadPost", "BufNewFile" },
        reloadable = true,
        config = M.configure,
    })
end

function M.configure()
    local notify = require("core.notify")
    local lifecycle = require("lib.lifecycle")

    -- Owned by a lifecycle object so `:ConfigReload` removes it and re-creates it
    -- exactly once (config is declared `reloadable`).
    local lc = lifecycle.new({ name = "plugins.treesitter" })

    lc:autocmd("FileType", {
        group_name = "treesitter_start",
        desc = "plugins: start Treesitter highlighting when a parser exists",
        callback = function(args)
            local ft = vim.bo[args.buf].filetype
            if ft == "" then
                return
            end
            local lang = vim.treesitter.language.get_lang(ft) or ft
            -- `language.add()` returns `nil, err` when the parser does not exist; it
            -- does not raise, so the return value is the availability check.
            local loaded = vim.treesitter.language.add(lang)
            if not loaded then
                -- Only complain for languages nvim-treesitter actually supports
                -- (it ships queries for them): "text", "help", ... have no
                -- parser upstream, so warning about them would be noise.
                local queries = vim.api.nvim_get_runtime_file("queries/" .. lang, true)
                if #queries > 0 then
                    notify.once(
                        "treesitter.missing." .. lang,
                        ("no Treesitter parser for %q -- install it with :TSInstall %s (see :checkhealth config)"):format(
                            lang,
                            lang
                        ),
                        "WARN"
                    )
                end
                return
            end
            pcall(vim.treesitter.start, args.buf, lang)
        end,
    })

    lc:activate()

    -- `require('nvim-treesitter')` is only needed for the install/query helpers;
    -- it is safe to leave unloaded until the user asks for it.
    if package.loaded["nvim-treesitter"] == nil then
        notify.debug("nvim-treesitter loaded; install parsers with :TSInstall <lang>")
    end
end

function M.teardown()
    -- the lifecycle sweep in `core.teardown()` removes the autocommand
end

return M
