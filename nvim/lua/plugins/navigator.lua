local methods = vim.lsp.protocol.Methods

local function keys_on_attach(client, buffer)
    local Keys = require("lazy.core.handler.keys")
    if not Keys.resolve then
        return {}
    end
    local keymaps = Keys.resolve({
        { "<leader>gr", "<cmd>FzfLua lsp_references jump_to_single_result=true ignore_current_line=true<cr>", desc = "References", has = methods.textDocument_references },
        { "gd", "<cmd>FzfLua lsp_definitions jump_to_single_result=true ignore_current_line=true<cr>", desc = "Definition", has = methods.textDocument_definition },
        { "<leader>gd", "<cmd>FzfLua lsp_declarations jump_to_single_result=true ignore_current_line=true<cr>", desc = "Declaration", has = methods.textDocument_declaration },
        { "gD ", "<cmd>FzfLua lsp_typedefs jump_to_single_result=true ignore_current_line=true<cr>", desc = "Type Definition", has = methods.textDocument_typeDefinition },
        {
            "<leader>gi",
            "<cmd>FzfLua lsp_implementations jump_to_single_result=true ignore_current_line=true<cr>",
            desc = "Implementation",
            has = methods.textDocument_implementation,
        },
        {
            "<leader>gi",
            "<cmd>FzfLua lsp_incoming_calls jump_to_single_result=true ignore_current_line=true<cr>",
            desc = "Incoming Calls",
            has = methods.callHierarchy_incomingCalls,
        },
        {
            "<leader>go",
            "<cmd>FzfLua lsp_outgoing_calls jump_to_single_result=true ignore_current_line=true<cr>",
            desc = "Outgoing Calls",
            has = methods.callHierarchy_outgoingCalls,
        },
        { "<leader>gs", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Document Symbols", has = methods.textDocument_documentSymbol },
        { "<leader>gw", "<cmd>FzfLua lsp_live_workspace_symbols<cr>", desc = "Workspace Symbols", has = methods.workspace_symbol },
        { "<leader>gc", "<cmd>FzfLua lsp_code_actions<cr>", desc = "Code Actions", has = methods.textDocument_codeAction },
        { "<leader>gf", "<cmd>FzfLua lsp_finder<cr>", desc = "Lsp Finder", nowait = true },
        { "<leader>gx", "<cmd>FzfLua lsp_document_diagnostics<cr>", desc = "Document Diagnostic", has = methods.textDocument_diagnostic },
        { "<leader>gX", "<cmd>FzfLua lsp_workspace_diagnostics<cr>", desc = "Workspace Diagnostic", has = methods.workspace_diagnostic },
        { "<c-k>", vim.lsp.buf.signature_help, mode = "i", desc = "Signature Help", has = methods.textDocument_signatureHelp },
        { "K", vim.lsp.buf.hover, desc = "Hover", has = methods.textDocument_hover },
        { "<leader>ga", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "v" }, has = methods.textDocument_codeLens },
        { "<leader>gA", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens", has = methods.textDocument_codeLens },
        { "<leader>gn", vim.lsp.buf.rename, desc = "Rename", has = methods.textDocument_rename },
        {
            "]]",
            function()
                require("navigator.treesitter").goto_next_usage()
            end,
            has = methods.textDocument_documentHighlight,
            desc = "Next Reference",
        },
        {
            "[[",
            function()
                require("navigator.treesitter").goto_previous_usage()
            end,
            has = methods.textDocument_documentHighlight,
            desc = "Prev Reference",
        },
    })

    for _, keys in pairs(keymaps) do
        local has = not keys.has or client.supports_method(keys.has)
        local cond = not (keys.cond == false or ((type(keys.cond) == "function") and not keys.cond()))
        if has and cond then
            local opts = Keys.opts(keys)
            opts.cond = nil
            opts.has = nil
            opts.silent = opts.silent ~= false
            opts.buffer = buffer
            vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
        end
    end
end

return {
    "ray-x/navigator.lua",
    event = "VeryLazy",
    branch = "master",
    version = false,
    dependencies = { "neovim/nvim-lspconfig", { "ray-x/guihua.lua", build = "cd lua/fzy && make", branch = "master", version = false } },
    opts = {
        on_attach = function(client, bufnr)
            keys_on_attach(client, bufnr)
            if client.supports_method(methods.textDocument_documentSymbol) then
                require("nvim-navic").attach(client, bufnr)
            end
            if client.supports_method(methods.textDocument_inlayHint) then
                if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == "" and not vim.tbl_contains({}, vim.bo[bufnr].filetype) then
                    vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
                end
            end
        end,
        ts_fold = { enable = false },
        default_mapping = false,
        treesitter_analysis = true,
        treesitter_navigation = true,
        treesitter_analysis_max_num = 100,
        treesitter_analysis_condense = true,
        transparency = nil,
        lsp_signature_help = true,
        signature_help_cfg = nil,
        icons = { icons = false },
        mason = false,
        lsp = {
            enable = true,
            code_action = { enable = true, sign = true, sign_priority = 40, virtual_text = true, delay = 1000 * 15 },
            code_lens_action = { enable = true, sign = true, sign_priority = 40, virtual_text = true },
            document_highlight = false,
            format_on_save = false,
            disable_format_cap = {},
            diagnostic = {
                underline = true,
                update_in_insert = false,
                severity_sort = true,
                signs = {
                    text = {
                        [vim.diagnostic.severity.ERROR] = require("utils.icons").diagnostics.ERROR,
                        [vim.diagnostic.severity.WARN] = require("utils.icons").diagnostics.WARN,
                        [vim.diagnostic.severity.INFO] = require("utils.icons").diagnostics.HINT,
                        [vim.diagnostic.severity.HINT] = require("utils.icons").diagnostics.INFO,
                    },
                    numhl = {
                        [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
                        [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
                        [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
                        [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
                    },
                },
                virtual_text = {
                    spacing = 4,
                    source = "if_many",
                    prefix = "",
                    format = function(d)
                        local dicons = {}
                        for key, value in pairs(require("utils.icons").diagnostics) do
                            dicons[key:upper()] = value
                        end
                        return string.format(" %s %s [%s] ", dicons[vim.diagnostic.severity[d.severity]], d.message, not vim.tbl_contains({ "lazy" }, vim.o.ft) and d.source or "")
                    end,
                },
                float = {
                    header = setmetatable({}, {
                        __index = function(_, k)
                            local icon, icons_hl = require("mini.icons").get("file", vim.api.nvim_buf_get_name(0))
                            local arr = {
                                function()
                                    return string.format("Diagnostics: %s  %s", icon, vim.bo.filetype)
                                end,
                                function()
                                    return icons_hl
                                end,
                            }
                            return arr[k]()
                        end,
                    }),
                    format = function(d)
                        return string.format("[%s] : %s", d.source, d.message)
                    end,
                    source = "if_many",
                    severity_sort = true,
                    wrap = true,
                    border = "single",
                    max_width = math.floor(vim.o.columns / 2),
                    max_height = math.floor(vim.o.lines / 3),
                },
            },
            hover = { enable = false },
            diagnostic_scrollbar_sign = { "▃", "▆", "█" },
            diagnostic_virtual_text = true,
            diagnostic_update_in_insert = false,
            display_diagnostic_qf = false,
            servers = { lua_ls = {} },
        },
    },
    config = function(_, opts)
        require("navigator").setup(opts)
        local register_capability = vim.lsp.handlers["client/registerCapability"]
        vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
            local ret = register_capability(err, res, ctx)
            local client = vim.lsp.get_client_by_id(ctx.client_id)
            if client then
                for buffer in pairs(client.attached_buffers) do
                    keys_on_attach(client, buffer)
                end
            end
            return ret
        end
    end,
}
