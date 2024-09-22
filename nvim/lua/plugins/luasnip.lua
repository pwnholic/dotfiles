return {
    "L3MON4D3/LuaSnip",
    build = "make install_jsregexp",
    version = false,
    event = "ModeChanged *:[iRss\x13vV\x16]*",
    keys = function()
        return {
                -- stylua: ignore start
				{ "<Tab>", function() require("luasnip").jump(1) end, mode = "s", },
				{ "<S-Tab>", function() require("luasnip").jump(-1) end, mode = "s", },
				{ "<C-n>", function() return require("luasnip").choice_active() and "<Plug>luasnip-next-choice" or "<C-n>" end, expr = true, mode = "s", },
				{ "<C-p>", function() return require("luasnip").choice_active() and "<Plug>luasnip-prev-choice" or "<C-p>" end, expr = true, mode = "s", },
            -- stylua: ignore end
        }
    end,
    opts = function()
        local ls = require("luasnip")
        local ls_types = require("luasnip.util.types")
        local utils = require("utils")
        require("luasnip.loaders.from_vscode").lazy_load({ paths = vim.fn.stdpath("data") .. "/lazy/vim-vscode-snippets" })

        vim.api.nvim_create_autocmd("ModeChanged", {
            group = vim.api.nvim_create_augroup("unlink_current", { clear = true }),
            desc = "Cancel the snippet session when leaving insert mode",
            pattern = { "s:n", "i:*" },
            callback = function(args)
                if ls.session and ls.session.current_nodes[args.buf] and not ls.session.jump_active and not ls.choice_active() then
                    ls.unlink_current()
                end
            end,
        })
        return {
            keep_roots = true,
            link_roots = false,
            link_children = true,
            delete_check_events = "TextChanged,TextChangedI",
            enable_autosnippets = false,
            store_selection_keys = "<Tab>",
            ext_opts = {
                [ls_types.choiceNode] = { active = { virt_text = { { utils.icons.misc.vertical_bar_bold, "ChoiceNode" } }, virt_text_pos = "inline" } },
                [ls_types.insertNode] = { unvisited = { virt_text = { { utils.icons.misc.vertical_bar_bold, "InsertNode" } }, virt_text_pos = "inline" } },
                [ls_types.exitNode] = { unvisited = { virt_text = { { utils.icons.misc.vertical_bar_bold, "ExitNode" } }, virt_text_pos = "inline" } },
            },
            snip_env = {
                ts_show = function(pred)
                    return function()
                        local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                        local ok, node = pcall(vim.treesitter.get_node, { pos = { row - 1, col - 1 } })
                        if not ok or not node then
                            return true
                        end
                        return pred(node:type())
                    end
                end,
            },
        }
    end,
}
