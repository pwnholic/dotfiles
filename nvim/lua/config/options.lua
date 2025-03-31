vim.opt.showtabline = 0
vim.opt.cmdheight = 0
vim.opt.colorcolumn = "90,120"
vim.opt.cursorcolumn = true
vim.opt.scrolloff = 21
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.swapfile = false
vim.opt.pumblend = 0
vim.opt.spell = true
vim.opt.smoothscroll = true
vim.opt.pumheight = 15

vim.opt.spellcapcheck = ""
vim.opt.spelllang = "en"
vim.opt.spelloptions = "camel"
vim.opt.spellsuggest = "best,9"

vim.opt.shell = os.getenv("SHELL") or "/usr/bin/fish"

vim.opt.guicursor = {
    "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50",
    "a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor",
    "sm:block-blinkwait175-blinkoff150-blinkon175",
}

vim.opt.listchars = {
    tab = "▏ ",
    trail = "·",
    nbsp = "␣",
}

vim.opt.fillchars = {
    fold = "·",
    foldsep = " ",
    eob = " ",
    foldopen = "",
    foldclose = "",
    diff = "╱",
}

vim.opt.diffopt:append({ "algorithm:histogram", "indent-heuristic" })

vim.opt.backup = true
vim.opt.backupdir:remove(".")

vim.g.lazyvim_picker = "fzf"
vim.g.deprecation_warnings = true

vim.g.border = "single"

local borderchars = {
    single = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
    rounded = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
}

if vim.g.border == "single" then
    vim.g.borderchars = borderchars.single
elseif vim.g.border == "rounded" then
    vim.g.borderchars = borderchars.rounded
end

vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"
vim.g.lazyvim_rust_diagnostics = "bacon-ls"

vim.g.lazyvim_prettier_needs_config = false

vim.g.fzf_layout = {
    horizontal = {
        fzf_options = {
            no_preview = {
                ["--info"] = "inline-right",
                ["--layout"] = "reverse",
                ["--ansi"] = true,
                ["--preview-window"] = "hidden",
                ["--no-preview"] = true,
                ["--border"] = "none",
                ["--marker"] = "█",
                ["--pointer"] = "█",
                ["--padding"] = "0,1",
                ["--margin"] = "0",
                ["--highlight-line"] = true,
            },
            with_preview = {
                ["--info"] = "inline-right",
                ["--ansi"] = true,
                ["--no-scrollbar"] = true,
                ["--marker"] = "█",
                ["--pointer"] = "█",
                ["--padding"] = "0,1",
                ["--margin"] = "0",
                ["--highlight-line"] = true,
            },
        },
        window_options = {
            no_preview = {
                split = string.format("botright %dnew", math.floor(vim.o.lines / 2)),
                preview = { hidden = true },
            },
        },
    },
    vertical = {
        fzf_options = {
            with_preview = {
                ["--layout"] = "reverse",
                ["--ansi"] = true,
                ["--no-separator"] = false,
                ["--marker"] = "█",
                ["--pointer"] = "█",
                ["--padding"] = "0,1",
                ["--margin"] = "0",
                ["--highlight-line"] = true,
            },
        },
        window_options = {
            with_preview = {
                height = 0.75,
                width = 0.90,
                row = 0.50,
                col = 0.50,
                preview = { layout = "vertical", vertical = "down:50%" },
            },
        },
    },
}
