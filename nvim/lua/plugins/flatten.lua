return {
    "willothy/flatten.nvim",
    priority = 1001,
    opts = function()
        local flatten = require("flatten")
        return {
            hooks = {
                should_block = flatten.hooks.should_block,
                should_nest = flatten.hooks.should_nest,
                pre_open = flatten.hooks.pre_open,
                post_open = flatten.hooks.post_open,
                block_end = flatten.hooks.block_end,
                no_files = flatten.hooks.no_files,
                guest_data = flatten.hooks.guest_data,
                pipe_path = flatten.hooks.pipe_path,
            },
            block_for = { gitcommit = true, gitrebase = true },
            disable_cmd_passthrough = false,
            nest_if_no_args = false,
            nest_if_cmds = false,
            window = {
                open = "alternate",
                diff = "tab_vsplit",
                focus = "first",
            },
            integrations = {
                kitty = true,
                wezterm = false,
            },
        }
    end,
}
