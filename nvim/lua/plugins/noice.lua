-- Noice UI: messages, classic cmdline, and LSP presentation.
--
-- LazyVim already ships a `folke/noice.nvim` spec
-- (`LazyVim/lua/lazyvim/plugins/ui.lua`): routes (`%d+L, %d+B` writes to
-- `mini`), presets, and the `<leader>sn*` / `<S-Enter>` / `<C-f>` / `<C-b>`
-- keys. A spec here merges over it (`opts` deep-merge), so only the parts
-- that differ from LazyVim -- or need an explicit anti-conflict decision --
-- are listed. Keys and routes are inherited, not repeated.
--
-- Conflict map (checked against `lua/plugins/{snacks,blink-cmp}.lua` and
-- the official noice docs at `:h noice.nvim-noice-...`):
--   * `cmdline.view = "cmdline"`: classic bottom-line `:`, `/`, `?`
--     instead of the centered popup. Search stays classic too
--     (`bottom_search`), matching the ivy picker aesthetic (bottom bar).
--     Works with `opts.cmdheight = 0` -- noice only shows the line while
--     typing.
--   * `popupmenu.enabled = false`: blink.cmp already draws the `:`
--     completion menu (`cmdline.completion.menu` in `blink-cmp.lua`);
--     leaving noice's nui popupmenu on would double-render it.
--   * `lsp.signature` off: blink's signature window is tuned
--     (`max_width 60`, no scrollbar); noice `auto_open` would stack a
--     second signature float on every trigger character.
--   * `notify.view = "notify"` + message views: noice's `notify` backend
--     tries snacks first (`backend = { "snacks", "notify" }` in
--     `noice/config/views.lua`), so notifications land in
--     `Snacks.notifier` (with `<leader>n` history) instead of a competing
--     renderer. Early-boot messages replay via the LazyVim `vim.notify`
--     restore hack in `lazyvim/plugins/init.lua`.
--   * `vim.ui.input()` stays with snacks (`input = { enabled = true }`
--     in `snacks.lua`); noice never claims it, so `cmdline_input` below
--     is fallback-only.
--   * hover stays with noice (`lsp.hover` + markdown overrides):
--     treesitter-highlighted `K` docs. Border set to `single` to match
--     `opts.winborder`; blink docs (completion menu) and noice hover never
--     overlap -- different triggers.
-- Requires `vim`, `regex`, `lua`, `bash`, `markdown`, `markdown_inline`
-- treesitter parsers (all installed) for cmdline/docs highlighting.
return {
    {
        "folke/noice.nvim",
        opts = {
            cmdline = {
                enabled = true, -- enables the Noice cmdline UI
                view = "cmdline", -- classic bottom cmdline, not `cmdline_popup`
                opts = {}, -- global options for the cmdline. See section on views
                ---@type table<string, CmdlineFormat>
            },
            messages = {
                enabled = true, -- enables the Noice messages UI
                view = "notify", -- default view for messages (snacks backend, see above)
                view_error = "notify", -- view for errors
                view_warn = "notify", -- view for warnings
                view_history = "messages", -- view for :messages
                view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
            },
            popupmenu = {
                enabled = false, -- blink.cmp owns the `:` completion menu; nui backend would double-render
                ---@type 'nui'|'cmp'
                backend = "nui", -- backend to use to show regular cmdline completions
                ---@type NoicePopupmenuItemKind|false
                -- Icons for completion item kinds (see defaults at noice.config.icons.kinds)
                kind_icons = {}, -- set to `false` to disable icons
            },
            notify = {
                -- Noice can be used as `vim.notify` so you can route any notification like other messages
                -- Notification messages have their level and other properties set.
                -- event is always "notify" and kind can be any log level as a string
                -- The default routes will forward notifications to nvim-notify
                -- Benefit of using Noice for this is the routing and consistent history view
                enabled = true,
                view = "notify",
            },
            lsp = {
                progress = {
                    enabled = true,
                    -- Lsp Progress is formatted using the builtins for lsp_progress. See config.format.builtin
                    -- See the section on formatting for more details on how to customize.
                    --- @type NoiceFormat|string
                    format = "lsp_progress",
                    --- @type NoiceFormat|string
                    format_done = "lsp_progress_done",
                    throttle = 1000 / 30, -- frequency to update lsp progress message
                    view = "mini",
                },
                override = {
                    -- override the default lsp markdown formatter with Noice
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    -- override the lsp markdown formatter with Noice
                    ["vim.lsp.util.stylize_markdown"] = true,
                    -- override cmp documentation with Noice (needs the other options to work).
                    -- nvim-cmp is not installed (blink.cmp is), so this stays off.
                    ["cmp.entry.get_documentation"] = false,
                },
                hover = {
                    enabled = true,
                    silent = false, -- set to true to not show a message if hover is not available
                    view = nil, -- when nil, use defaults from documentation
                    ---@type NoiceViewOptions
                    opts = {}, -- merged with defaults from documentation
                },
                signature = {
                    -- Off: blink.cmp's signature window already auto-opens
                    -- on trigger characters (see `blink-cmp.lua`).
                    enabled = false,
                    auto_open = {
                        enabled = false,
                        trigger = true, -- Automatically show signature help when typing a trigger character from the LSP
                        luasnip = true, -- Will open signature help when jumping to Luasnip insert nodes
                        throttle = 50, -- Debounce lsp signature help request by 50ms
                    },
                    view = nil, -- when nil, use defaults from documentation
                    ---@type NoiceViewOptions
                    opts = {}, -- merged with defaults from documentation
                },
                message = {
                    -- Messages shown by lsp servers
                    enabled = true,
                    view = "notify",
                    opts = {},
                },
                -- defaults for hover and signature help
                documentation = {
                    view = "hover",
                    ---@type NoiceViewOptions
                    opts = {
                        lang = "markdown",
                        replace = true,
                        render = "plain",
                        format = { "{message}" },
                        win_options = { concealcursor = "n", conceallevel = 3 },
                    },
                },
            },
            ---@type NoicePresets
            presets = {
                -- you can enable a preset by setting it to true, or a table that will override the preset config
                -- you can also add custom presets that you can enable/disable with enabled=true
                bottom_search = true, -- use a classic bottom cmdline for search
                command_palette = false, -- position the cmdline and popupmenu together (needs popup cmdline + menu; both classic/off here)
                long_message_to_split = true, -- long messages will be sent to a split
                inc_rename = false, -- enables an input dialog for inc-rename.nvim
                lsp_doc_border = false, -- add a border to hover docs and signature help (border set manually in `views` below)
            },
            throttle = 1000 / 30, -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
            ---@type NoiceConfigViews
            views = {
                -- `single` borders everywhere to match `opts.winborder`.
                -- (`hover` upstream is borderless; the rest default to
                -- `rounded`. `mini`/`split` keep their defaults: `mini` is
                -- borderless by design, `split` follows `FloatBorder`.)
                popup = { border = { style = "single" } },
                hover = { border = { style = "single" } },
                cmdline_popup = { border = { style = "single" } },
                confirm = { border = { style = "single" } },
            }, ---@see section on views
        },
    },
}
