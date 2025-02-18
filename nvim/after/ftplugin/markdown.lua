local currrent_buffer = vim.api.nvim_get_current_buf()
local has_spec, markview_spec = pcall(require, "markview.spec")
local has_util, markview_util = pcall(require, "markview.utils")

if not (has_spec and has_util) then
    return
end

_G.heading_foldtext = function()
    local fold_start, fold_end = vim.v.foldstart, vim.v.foldend
    local fold_line = vim.api.nvim_buf_get_lines(0, fold_start - 1, fold_start, false)[1]

    if not fold_line:match("^[%s%>]*%#+") then
        return vim.fn.foldtext()
    end

    local main_config = markview_spec.get({ "markdown", "headings" }, { fallback = nil })
    if not main_config then
        return vim.fn.foldtext()
    end

    local indent, marker, content = fold_line:match("^([%s%>]*)(%#+)(.*)$")
    local level = marker:len()
    local config = markview_spec.get({ "heading_" .. level }, {
        source = main_config,
        fallback = nil,
        eval_args = {
            currrent_buffer,
            {
                class = "markdown_atx_heading",
                marker = marker,
                text = { marker .. content },
                range = { row_start = fold_start - 1, row_end = fold_start, col_start = #indent, col_end = #fold_line },
            },
        },
    })

    if not config then
        return vim.fn.foldtext()
    end

    local shift_width = markview_spec.get({ "shift_width" }, { source = main_config, fallback = 0 })
    local shift = string.rep(" ", level * shift_width)
    local fold_info = { string.format(" 󰘖  %d line folded", fold_end - fold_start), markview_util.set_hl(string.format("Palette%dFg", 7 - level)) }

    if config.style == "simple" then
        return {
            { marker .. content, markview_util.set_hl(config.hl) },
            fold_info,
        }
    elseif config.style == "label" then
        return {
            { shift, markview_util.set_hl(config.hl) },
            { config.corner_left or "", markview_util.set_hl(config.corner_left_hl or config.hl) },
            { config.padding_left or "", markview_util.set_hl(config.padding_left_hl or config.hl) },
            { config.icon or "", markview_util.set_hl(config.padding_left_hl or config.hl) },
            { content:gsub("^%s", ""), markview_util.set_hl(config.hl) },
            { config.padding_right or "", markview_util.set_hl(config.padding_right_hl or config.hl) },
            { config.corner_right or "", markview_util.set_hl(config.corner_right_hl or config.hl) },
            fold_info,
        }
    elseif config.style == "icon" then
        return {
            { shift, markview_util.set_hl(config.hl) },
            { config.icon or "", markview_util.set_hl(config.padding_left_hl or config.hl) },
            { content:gsub("^%s", ""), markview_util.set_hl(config.hl) },
            fold_info,
        }
    end
end

vim.opt_local.fillchars = "fold: "
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt_local.foldtext = "v:lua.heading_foldtext()"
vim.opt_local.number = false
vim.opt_local.relativenumber = false

-- require("lspconfig").iwes.setup()
require("which-key").add({ { "<leader>o", group = "Obsidian", icon = "󰎚 " } })
