return {
    {
        "ray-x/go.nvim",
        ft = { "go", "gomod" },
        keys = {
            { "<leader>js", "<cmd>GoFillStruct<cr>", desc = "Fill Struct", ft = "go" },
            { "<leader>jp", "<cmd>GoFixPlurals<cr>", desc = "Fix Plurals", ft = "go" },
            { "<leader>jS", "<cmd>GoFillSwitch<cr>", desc = "Fill Switch", ft = "go" },
            { "<leader>jD", "<cmd>GoModTidy<cr>", desc = "`go mod tidy`", ft = "go" },
            { "<leader>jI", "<cmd>GoModVendor<cr>", desc = "`go mod vendor`", ft = "go" },
            {
                "<leader>jf",
                function()
                    local fzf = require("fzf-lua")
                    return fzf.fzf_exec("go list std; go list all", {
                        prompt = "Go Packages> ",
                        fzf_opts = { ["--preview"] = "go doc -all -c {}" },
                        winopts = { preview = { default = "bat", border = "none" } },
                        actions = {
                            ["default"] = function(pkg_selected, _)
                                local package_name = pkg_selected[1]
                                local rg_cmd = table.concat({
                                    "go",
                                    "doc",
                                    "-c",
                                    "-all",
                                    "-u",
                                    tostring(package_name),
                                    "|",
                                    "rg",
                                    "--column",
                                    "--line-number",
                                    "--no-heading",
                                    "--color=always",
                                    "--smart-case",
                                    "--max-columns=4096",
                                    "--",
                                    "<query>",
                                    "2>/dev/null",
                                }, " ")

                                local open_docs = function(rg_sel, split)
                                    local line_col = tonumber(rg_sel[1]:match("(%d+):")) or 1
                                    local line_row = tonumber(rg_sel[1]:match(":(%d+):")) or 1

                                    vim.cmd(split)

                                    return vim.system({ "go", "doc", "-all", "-c", package_name }, { text = true }, function(result)
                                        vim.schedule(function()
                                            if result.code ~= 0 then
                                                return vim.notify("Error: " .. result.stderr, 4)
                                            end

                                            local current_buf = vim.api.nvim_create_buf(false, true) or 0
                                            local current_win = vim.api.nvim_get_current_win() or 0

                                            if vim.api.nvim_buf_is_valid(0) then
                                                local output_lines = vim.split(result.stdout, "\n")

                                                vim.api.nvim_buf_set_name(current_buf, "godocs")

                                                vim.bo[current_buf].buftype = "nofile"
                                                vim.bo[current_buf].filetype = "markdown"
                                                vim.bo[current_buf].bufhidden = "wipe"
                                                vim.bo[current_buf].buflisted = false
                                                vim.bo[current_buf].swapfile = false
                                                vim.wo[current_win].number = false
                                                vim.wo[current_win].relativenumber = false

                                                vim.api.nvim_win_set_buf(current_win, current_buf)
                                                vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, output_lines)

                                                return vim.api.nvim_win_set_cursor(current_win, { line_col, line_row })
                                            end
                                        end)
                                    end):wait()
                                end

                                fzf.fzf_live(rg_cmd, {
                                    actions = {
                                        ["default"] = function(rg_sel)
                                            return open_docs(rg_sel, "vsplit")
                                        end,
                                        ["ctrl-v"] = function(rg_sel)
                                            return open_docs(rg_sel, "vsplit")
                                        end,
                                        ["ctrl-s"] = function(rg_sel)
                                            return open_docs(rg_sel, "split")
                                        end,
                                        ["ctrl-t"] = function(rg_sel)
                                            return open_docs(rg_sel, "tab split")
                                        end,
                                    },
                                })
                            end,
                        },
                    })
                end,
                ft = "go",
                desc = "Go Docs",
            },
            {
                "<leader>ji",
                function()
                    vim.ui.input({ prompt = "Impl {r *receiver} -> {interface} : " }, function(input)
                        if input ~= "" then
                            return vim.cmd(string.format("GoImpl %s", input))
                        end
                    end)
                end,
                desc = "Implement Method",
                ft = "go",
            },
            {
                "<leader>jt",
                function()
                    vim.ui.select({ "Add", "Clear", "Remove" }, {
                        prompt = "Modify Tags Option:",
                    }, function(choice)
                        if choice == "Add" then
                            vim.ui.input({ prompt = "Input Tags to Add: " }, function(input)
                                if input ~= nil then
                                    return vim.cmd(string.format("GoModifyTag -add-tags %s", input))
                                end
                            end)
                        elseif choice == "Remove" then
                            vim.ui.input({ prompt = "Input Tags to Remove : " }, function(input)
                                if input ~= nil then
                                    return vim.cmd(string.format("GoModifyTag -remove-tags %s", input))
                                end
                            end)
                        elseif choice == "Clear" then
                            vim.ui.input({ prompt = "Input Tags to Clear : " }, function(input)
                                if input ~= nil then
                                    return vim.cmd(string.format("GoModifyTag -clear-tags %s", input))
                                end
                            end)
                        end
                    end)
                end,
                desc = "Modify Tag",
                ft = "go",
            },
        },
        opts = {
            lsp_keymaps = false,
            lsp_cfg = true,
            icons = false,
            trouble = false,
            tag_transform = "snakecase",
            tag_options = "json=",
            dap_debug_keymap = false,
            dap_debug = false,
            null_ls = false,
            lsp_inlay_hints = { enable = false },
            diagnostic = false,
            go_input = vim.ui.input,
            go_select = vim.ui.select,
        },
    },
}
