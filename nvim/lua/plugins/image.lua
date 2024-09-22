return {
    "3rd/image.nvim",
    version = false,
    ft = { "markdown", "neorg" },
    -- build = "luarocks --local --lua-version=5.1 install magick --force",
    init = vim.schedule_wrap(function()
        package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua"
        package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua"
    end),
    opts = function()
        return {
            backend = "kitty",
            integrations = {
                markdown = {
                    enabled = true,
                    clear_in_insert_mode = false,
                    download_remote_images = false,
                    only_render_image_at_cursor = false,
                    filetypes = { "markdown", "vimwiki" },
                },
            },
        }
    end,
}
