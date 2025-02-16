local buffer = vim.api.nvim_get_current_buf()

local got_spec, spec = pcall(require, "markview.spec")
local got_util, utils = pcall(require, "markview.utils")

if not (got_spec and got_util) then
    return
end

_G.heading_foldtext = function()
    local from, to = vim.v.foldstart, vim.v.foldend
    local line = vim.api.nvim_buf_get_lines(0, from - 1, from, false)[1]

    if not line:match("^[%s%>]*%#+") then
        return vim.fn.foldtext()
    end

    local main_config = spec.get({ "markdown", "headings" }, { fallback = nil })
    if not main_config then
        return vim.fn.foldtext()
    end

    local indent, marker, content = line:match("^([%s%>]*)(%#+)(.*)$")
    local level = marker:len()

    local config = spec.get({ "heading_" .. level }, {
        source = main_config,
        fallback = nil,
        eval_args = {
            buffer,
            {
                class = "markdown_atx_heading",
                marker = marker,
                text = { marker .. content },
                range = { row_start = from - 1, row_end = from, col_start = #indent, col_end = #line },
            },
        },
    })

    if not config then
        return vim.fn.foldtext()
    end

    local shift_width = spec.get({ "shift_width" }, { source = main_config, fallback = 0 })
    local shift = string.rep(" ", level * shift_width)
    local fold_info = { string.format(" 󰘖 %d", to - from), utils.set_hl(string.format("Palette%dFg", 7 - level)) }

    if config.style == "simple" then
        return {
            { marker .. content, utils.set_hl(config.hl) },
            fold_info,
        }
    elseif config.style == "label" then
        return {
            { shift, utils.set_hl(config.hl) },
            { config.corner_left or "", utils.set_hl(config.corner_left_hl or config.hl) },
            { config.padding_left or "", utils.set_hl(config.padding_left_hl or config.hl) },
            { config.icon or "", utils.set_hl(config.padding_left_hl or config.hl) },
            { content:gsub("^%s", ""), utils.set_hl(config.hl) },
            { config.padding_right or "", utils.set_hl(config.padding_right_hl or config.hl) },
            { config.corner_right or "", utils.set_hl(config.corner_right_hl or config.hl) },
            fold_info,
        }
    elseif config.style == "icon" then
        return {
            { shift, utils.set_hl(config.hl) },
            { config.icon or "", utils.set_hl(config.padding_left_hl or config.hl) },
            { content:gsub("^%s", ""), utils.set_hl(config.hl) },
            fold_info,
        }
    end
end

vim.o.fillchars = "fold: "
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldtext = "v:lua.heading_foldtext()"
