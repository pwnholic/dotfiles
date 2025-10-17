local group = vim.api.nvim_create_augroup("InlayHintsNormalModeOnly", { clear = true })

vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = "*:*",
    desc = "Enable inlay hints only in normal mode",
    callback = function(args)
        local bufnr = args.buf
        local to_mode = args.match:sub(3, 3)
        local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/inlayHint" })

        if not vim.api.nvim_buf_is_valid(bufnr) or #clients < 1 then
            return
        end

        if next(clients) then
            vim.lsp.inlay_hint.enable(to_mode == "n", { bufnr = bufnr })
        end
    end,
})
